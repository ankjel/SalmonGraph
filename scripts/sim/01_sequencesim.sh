#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=50G 
#SBATCH --partition=smallmem
#SBATCH --output=log-pggb-%j.log
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

date
set -o errexit # exit on errors
set -o nounset # treat unset variables as errors



SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe/pggb
homedir=/mnt/users/ankjelst
outhack=sim
ref=/mnt/SCRATCH/ankjelst/data/simon22.fasta
bed=/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed


mkdir -p "$SCRATCHout"
TMPout=$TMPDIR/$USER/$SLURM_JOBID
mkdir -p $TMPout
cd "$TMPout"


############
# Insert SVs into sequence

singularity exec $homedir/tools/visor.sif VISOR hack -b "$bed" -g $ref -o $outhack



sed 's/>.*/>ref#1#ssa22/' "$ref"> ref1.fa
sed 's/>.*/>ref#2#ssa22/' "$ref"> ref2.fa
cat ref1.fa ref2.fa > ref-2hap.fa


sed 's/>.*/>simulated#1#ssa22/' $ref > h1-1.fa
sed 's/>.*/>simulated#2#ssa22/' $outhack/h1.fa > h1-2.fa
cat h1-1.fa h1-2.fa > h1-2hap.fa


fasta=pggb.fasta
cat ref1.fa h1-2.fa > $fasta

haplotypes=$(cat "$fasta" | grep "^>" | wc -l)

#wfmash
param_s=100000 # segment size, this should only be this small because we have a small graph, for full chromosomes set to 100000
param_p=98 # percent identity in the wfmash step, including variants. This should not be so strict for this small example
param_n=$haplotypes  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_i="$(basename $fasta)" 

#seqwish
param_k=311 #filter exact matches below this length [default: 29]

#smoothxg
param_H=$haplotypes # number of haplotypes, if different than that set with -n
param_G="13117,13219" # target sequence length for POA, first pass = N, second pass = M [default: 13117,13219]

param_V='ref:#' # obs obs this should be set to the sample name you want as a refernc for your vcf

pggbout=pggb.out


####
# Running pggb

echo "RUN PGGB"

singularity exec "$homedir"/tools/pggb_v0.3.0.sif pggb -i $param_i -s $param_s -p $param_p \
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $pggbout -G $param_G -V $param_V -A


#chop graph
odgi=$(ls $pggbout/*.smooth.og)
fastabase=$(basename "$fasta")

echo "Chop graph"
singularity exec "$homedir"/tools/pggb_v0.3.0.sif odgi chop -c 1024 -i $odgi -o "$fastabase"-chop.og

singularity exec "$homedir"/tools/pggb_v0.3.0.sif odgi view -i "$fastabase"-chop.og --to-gfa > "$fastabase"-chop.gfa
singularity exec "$homedir"/tools/pggb_v0.3.0.sif vg deconstruct -p "ref#1#ssa22" -H "#" -a -e "$fastabase"-chop.gfa > chop-deconstruct-"$fasta".vcf

singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip chop-deconstruct-"$fasta".vcf

singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf chop-deconstruct-"$fasta".vcf.gz

cp *-chop.gfa chop-deconstruct-* *.fa *.fasta "$pggbout"/*.gfa "$SCRATCHout" 

cd ..
rm -r $TMPout

date
#sbatch 02.sh