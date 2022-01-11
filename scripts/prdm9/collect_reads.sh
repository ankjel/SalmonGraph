#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=30G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-pggb-%j.out



# This script takes a cram file as input and collects reads from a given region. 

cram=$1

module load SAMtools/1.11-GCC-9.3.0
mkdir prdm9_both_haps

for bam in Alto.bam Arnold.bam Barry.bam Bond.bam Brian.bam Klopp.bam Louis.bam Maxine.bam Simon.bam Tanner.bam Tess.bam
do
        input=$bam
        region1='ssa05:12773188-127773343' # This depends on the reference
        ind=${bam/.bam/}

        samtools view -H $input > header.sam
        samtools view $input "$region1" | cat header.sam - | samtools view -Sb - > ${ind}_${region1}.bam
        samtools index ${ind}_${region1}.bam
        samtools fasta ${ind}_${region1}.bam > prdm9_both_haps/${ind}_${region1}_reads.fa

        rm ${ind}_${region1}.bam*

done4



