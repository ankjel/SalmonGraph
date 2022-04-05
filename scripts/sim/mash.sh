#!/bin/bash

#SBATCH --ntasks=2
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=mash  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-mash-%j.out


#############
# To find ideal -s option for pggb we use mash dist to establish the typical level of divergence
# (from pggb readme)
# This script will find mash distance between some of the sequences in the fasta.
#############

fasta=$1

#######
# find distance

time singularity exec /cvmfs/singularity.galaxyproject.org/m/a/mash:2.3--he348c14_1 mash triangle -p $SLURM_CPUS_ON_NODE $fasta > mash-$(basename "$fasta" .fasta).txt


echo finished

date