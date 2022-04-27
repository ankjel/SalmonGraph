#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=30G 
#SBATCH --partition=smallmem 
#SBATCH --output=log-pggb-%j.log
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this


SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe/pggb
fasta=/mnt/SCRATCH/ankjelst/sim_pipe/pggb/pggb.fasta.gz
TMPout=$TMPDIR/$USER/$SLURM_JOBID
mkdir -p $TMPout
cd "$TMPout"

cp "$fasta"* .

haplotypes=2
#$(cat "$fasta" | grep "^>" | wc -l)

#wfmash
param_s=50000 # segment size, this should only be this small because we have a small graph, for full chromosomes set to 100000
param_p=98 # percent identity in the wfmash step, including variants. This should not be so strict for this small example
param_n=$haplotypes  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_i="$(basename $fasta)" 

#seqwish
param_k=311 #filter exact matches below this length [default: 29]

#smoothxg
param_H=$haplotypes # number of haplotypes, if different than that set with -n
param_G="7919,8069" # target sequence length for POA, first pass = N, second pass = M [default: 13117,13219]

param_V='ref:#' # obs obs this should be set to the sample name you want as a refernc for your vcf

pggbout=pggb.out


####
# Running pggb

echo "RUN PGGB"


singularity exec ~/tools/pggb_v0.2.0.sif pggb -i $param_i -n $param_n -s $param_s \
-p $param_p -t $SLURM_CPUS_ON_NODE -k $param_k -o $pggbout -G $param_G -V $param_V 



#chop graph
odgi=$(ls $pggbout/*.smooth.og)
fastabase=$(basename "$fasta")

echo "Chop graph"
singularity exec ~/tools/pggb_v0.2.0.sif odgi chop -c 1024 -i $odgi -o "$fastabase"-chop.og

singularity exec ~/tools/pggb_v0.2.0.sif odgi view -i "$fastabase"-chop.og --to-gfa > "$fastabase"-chop.gfa
singularity exec ~/tools/vg_v1.38.0.sif vg deconstruct -p "ref#1#ssa22" -H "#" -a -e "$fastabase"-chop.gfa > chop-deconstruct-"$fastabase".vcf

singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip chop-deconstruct-"$fastabase".vcf

singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf chop-deconstruct-"$fastabase".vcf.gz


#################################################
# Make a graph for only two seq to see difference


cp /mnt/SCRATCH/ankjelst/sim_pipe/pggb/pggb_nodup.fasta.gz* .

singularity exec ~/tools/pggb_v0.2.0.sif pggb -i pggb_nodup.fasta.gz -n $param_n -s $param_s \
-p $param_p -t $SLURM_CPUS_ON_NODE -k $param_k -o nodup -G $param_G -V $param_V 



cp nodup/*.vcf* "$SCRATCHout"
cp *-chop.gfa chop-deconstruct-*  "$pggbout"/*.gfa "$SCRATCHout" 

cd ..
rm -r $TMPout

date
#sbatch 02.sh
