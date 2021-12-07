#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=10G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hugemem
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=visor       # Sensible name for the job
#SBATCH --output=log-VISOR-%j.log  # Logfile output here


echo "START"
date


datadir=/mnt/SCRATCH/ankjelst/data
bed=$datadir/ssa22variants.bed
ref=$datadir/simon22.fasta
outhack=$datadir/visor.hack
homedir=/mnt/users/ankjelst
mergedfasta=$datadir/merged_ssa22.fasta


####
# Run hack to insert SV into fasta

singularity exec $homedir/tools/visor.sif VISOR hack -b $bed -g $ref -o $outhack



#####
# Run SHOrTS to simulate illumina reads
shortsbed=shorts.bed
outshorts=visor.shorts


# we will not use the command below as we do not need haplotype resolved reads.
# We will rather simulate reads directly with wgsim as used in SHORtS or ART, another well known read-simulator.

#singularity exec $homedir/tools/visor.sif VISOR SHORtS \
#-s $outhack -b $shortsbed -g $ref -o $outshorts --threads 8  --coverage 2 --fastq



echo "Merge files into one fasta"

# VISOR => the fasta I added SVs to, here I am adding to header name

sed 's/>.*/&VISOR/' $outhack/h1.fa > $datadir/h1named.fa

# merging the two fasta files

cat $ref $datadir/h1named.fa > $mergedfasta


echo "FINISHED"
date

