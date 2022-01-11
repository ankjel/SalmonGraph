#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=samtools  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-samtools-%j.out



# This script takes one ore several cram files and collects reads from a given region. 

module load SAMtools/1.11-GCC-9.3.0


cd $SCRATCH/data/prdm9
mkdir -p prdm9_both_haps

for bam in tess.cram
do
        input=$bam
        region1='ssa05:12773188-127773343' # This depends on the reference
        ind=$(basename $input)

        samtools view -H $input > header.sam # Extract the header to merge with reads later for valid bam
        # First: subset region, second: cat header and region for valid sam, 
        #third: S ignore compability something abot samtools version, b bam output 
        samtools view $input "$region1" | cat header.sam - | samtools view -Sb - > ${ind}_${region1}.bam
        # index new bam file
        samtools index ${ind}_${region1}.bam
        # make fasta from new bam file
        samtools fasta ${ind}_${region1}.bam > prdm9_both_haps/${ind}_${region1}_reads.fa
        
        rm ${ind}_${region1}.bam*

done

