#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=samtools  # sensible name for the job
#SBATCH --mem=50G                 # Default memory per CPU is 3GB.
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

        samtools view -@ $SLURM_CPUS_ON_NODE -H $input > header.sam # Extract the header to merge with reads later for valid bam
        # First: subset region, second: cat header and region for valid sam, 
        #third: S ignore compability something abot samtools version, b bam output 
        samtools view -@ $SLURM_CPUS_ON_NODE $input "$region1" | cat header.sam - | \
        samtools view -@ $SLURM_CPUS_ON_NODE -Sb - > ${ind}_${region1}.bam
        
        # index new bam file
        samtools index -@ $SLURM_CPUS_ON_NODE ${ind}_${region1}.bam
        
        # make fasta from new bam file
        samtools fastq -@ $SLURM_CPUS_ON_NODE ${ind}_${region1}.bam > prdm9_both_haps/${ind}_${region1}_reads.fq
        
        # Sort reads into two files for giraffe.
        cat prdm9_both_haps/${ind}_${region1}_reads.fq | \
        grep "^@.*/1$" -A 3 --no-group-separator > prdm9_both_haps/${ind}_${region1}_r1.fq
        
        cat prdm9_both_haps/${ind}_${region1}_reads.fq | \
        grep "^@.*/2$" -A 3 --no-group-separator > prdm9_both_haps/${ind}_${region1}_r2.fq
        
        rm ${ind}_${region1}.bam* 

done




