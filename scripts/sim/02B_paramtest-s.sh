#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb-paramtest  # sensible name for the job
#SBATCH --mem=150G 
#SBATCH --partition=hugemem
#SBATCH --output=log-pggbparams_S-%j.log
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
param_i="$(basename $fasta)" 

#seqwish
param_k=311 #filter exact matches below this length [default: 29]

#smoothxg
param_H=$haplotypes # number of haplotypes, if different than that set with -n
param_G="4001,4507" # target sequence length for POA, first pass = N, second pass = M [default: 4001,4507]

param_V='ref:#' # obs obs this should be set to the sample name you want as a refernc for your vcf

pggbout=pggb.out

####
# Running pggb

echo "RUN PGGB"

echo -e "S_param\truntime_seconds" > S_runtime.txt

for param_s in 5000 10000 20000 50000 100000 200000
do
    start=`date +%s` # time pggb run
    singularity exec "$homedir"/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
    -n $param_n -t $SLURM_CPUS_ON_NODE  -o $pggbout -G $param_G -V $param_V #-l $param_l
    end=`date +%s`
    runtime=$((end-start)) # I do it this way so it is easy to save timing to file
    echo -e ""$param_s"\t"$runtime"" >> S_runtime.txt
    mv "$pggbout"/*.vcf "$SCRATCHout"/S-"$param_s".vcf
    rm -r "$pggbout"
done

mv S_runtime.txt $SCRATCHout
cd ..
rm -r $TMPout







