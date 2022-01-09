#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=mash  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-mash-%j.out


#############
# To find ideal -s option for pggb we use mash dist to establish the typical level of divergence
# (from pggb readme)
# This script will find mash distance between some of the sequences in the fasta with all prdm9 haplotypes.
#############

fasta=$1
headers="Simon#1#majorityconsensus Maxine#2#zfsig Arnold#1#zfsig" # headers of sequences to compare

out=$TMPDIR/$USER
mkdir -p $out #Not all nodes my TMP dir exist
cd $out


########
# make fasta files for each header

for i in $headers
do 
    singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 samtools faidx $fasta $i > $i.fasta
done


#######
# find distance

fastas=$out/$(ls *.fasta)

singularity exec /cvmfs/singularity.galaxyproject.org/m/a/mash:2.3--he348c14_1 mash dist $fastas

#########
# Clean out tmpdir

rm -r $out/*

echo finished

    

