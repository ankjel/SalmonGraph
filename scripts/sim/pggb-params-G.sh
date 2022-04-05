#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb-paramtest  # sensible name for the job
#SBATCH --mem=150G 
#SBATCH --partition=hugemem
#SBATCH --output=log-pggbparams_G-%j.log
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

homedir=/mnt/users/ankjelst
SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe/pggb/paramtest
mkdir -p "$SCRATCHout"
TMPout=$TMPDIR/$USER/$SLURM_JOBID
mkdir -p $TMPout
cd "$TMPout"

fasta=/mnt/SCRATCH/ankjelst/sim_pipe/pggb/pggb.fasta

cp "$fasta" .

haplotypes=$(cat "$fasta" | grep "^>" | wc -l)

#wfmash
param_s=100000 
param_p=98 # percent identity in the wfmash step, including variants. 
param_n=$haplotypes  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_K=16 # Kmer size for aligning
param_i="$(basename $fasta)" 
#param_l=300000 # minimum block length filter for mapping. (segments are merged to blocks, default 3*segment-length)

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

echo -e "G_param\truntime_seconds" > G_runtime.txt

for param_G in  3079,3559 7919,8069 13117,13219 18100,18200 25000,25100
do
    start=`date +%s` # time pggb run
    singularity exec "$homedir"/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
    -n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $pggbout -G $param_G -V $param_V #-l $param_l
    end=`date +%s`
    runtime=$((end-start)) # I do it this way so it is easy to save timing to file
    echo -e ""$param_G"\t"$runtime"" >> G_runtime.txt
    mv "$pggbout"/*.vcf "$SCRATCHout"/G-"$param_G".vcf
    rm -r "$pggbout"
done


mv G_runtime.txt $SCRATCHout
cd ..
rm -r $TMPout







