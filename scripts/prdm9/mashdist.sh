#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=mash  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-mash-%j.out


#############
# To find ideal -s option for pggb we use mash dist to establish the typical level of divergence

#############

fasta=$SCRATCH/data/prdm9/PRDM9a_zf_sig_original.fasta


singularity exec /cvmfs/singularity.galaxyproject.org/m/a/mash:2.3--he348c14_1 mash triangle -p $SLURM_CPUS_ON_NODE $fasta > mash-$(basename "$fasta" .fasta).txt

#######
# find distance max dist

echo "Max dist:"

sed 1,1d mash-PRDM9a_zf_sig_original.txt | tr '\t' '\n' | grep '^[A-Z]' -v | LC_ALL=C sort -g -k 1nr | uniq | head -n 1


    
# For prdm9 0.0112932
# 100-0.0112932*100 = ca 98.9 
