#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb-paramtest  # sensible name for the job
#SBATCH --mem=3G 
#SBATCH --partition=smallmem # hugemem
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

bgzip -@ "$SLURM_CPUS_ON_NODE" "$(basename $fasta)" 
samtools faidx "$(basename $fasta)".gz

#wfmash
param_s=100000 
param_p=98 # percent identity in the wfmash step, including variants. 
param_n=$haplotypes  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_i="$(basename $fasta)".gz 

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

echo -e "G_param\ttotal_time\tclock_time\tmemory\n" > G_runtime.txt

for param_G in 3079,3559 #4001,4507 7919,8069 13117,13219 18100,18200 
do
    singularity exec "$homedir"/tools/pggb_v0.3.0.sif /usr/bin/time -v pggb -i $param_i -s $param_s -p $param_p  \
    -n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $pggbout -G $param_G -V $param_V > pggb"$param_G"-out.txt 2> time_log.txt
    
    USER_TIME="$(cat "time_log.txt" | grep "User time" | sed 's/User\ time\ (seconds):\ \([0-9]*\.[0-9]*\)/\1/g')"
    SYS_TIME="$(cat "time_log.txt" | grep "System time" | sed 's/System\ time\ (seconds):\ \([0-9]*\.[0-9]*\)/\1/g')"
    TOTAL_TIME="$(echo "${USER_TIME} + ${SYS_TIME}" | bc -l)"
    CLOCK_TIME="$(cat "time_log.txt" | grep "Elapsed (wall clock) time" | sed 's/.*\ \([0-9,:]*\)/\1/g')"
    MEMORY="$(cat "time_log.txt" | grep "Maximum resident set" | sed 's/Maximum\ resident\ set\ size\ (kbytes):\ \([0-9]*\)/\1/g')"
        
    
    echo -e ""$param_G"\t"$TOTAL_TIME"\t"$CLOCK_TIME"\t"$MEMORY"\n" >> G_runtime.txt
    mv pggb"$param_G"-out.txt "$SCRATCHout"
    mv "$pggbout"/*.vcf "$SCRATCHout"/G-"$param_G".vcf
    rm -r "$pggbout"
done


mv G_runtime.txt $SCRATCHout
cd ..
rm -r $TMPout







