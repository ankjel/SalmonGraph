#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=samtools  # sensible name for the job
#SBATCH --mem=50G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-samtools-%j.out



# This script takes one ore several cram files and collects reads from a given region. 

#module load SAMtools/1.11-GCC-9.3.0
# samtools in modules is way too old

samtoolssif=/cvmfs/singularity.galaxyproject.org/s/a/samtools:1.14--hb421002_0
crams=$1
echo "crams:" $crams

cd $SCRATCH/data/prdm9s
mkdir -p prdm9_both_haps

for bam in $crams
do
        echo $bam
        input=$bam
        region1='ssa05:12773150-12773892' # This depends on the reference- 
        # Øyvind 12773150-12773892 Kristina 12773188-127773343 for simon
        ind=$(basename $input)
        
        #############################################
        # Find all the reads mapping to our region
        #############################################
        echo "first step"
        singularity exec $samtoolssif \
        samtools view -@ $SLURM_CPUS_ON_NODE -H $input > header.sam # Extract the header to merge with reads later for valid bam
        # First: subset region, second: cat header and region for valid sam, 
        #third: S ignore compability something abot samtools version, b bam output 
        
        singularity exec $samtoolssif \
        samtools view -@ $SLURM_CPUS_ON_NODE $input -F 4 "$region1" | cat header.sam - | singularity exec $samtoolssif \
        samtools view -@ $SLURM_CPUS_ON_NODE -Sb - > ${ind}_${region1}.bam
         # -F 4 exclude unmapped reads
        
        # index new bam file
        singularity exec $samtoolssif \
        samtools index -@ $SLURM_CPUS_ON_NODE ${ind}_${region1}.bam
        
        
        #########################################################
        # Get all the pairs where one maps to region
        ########################################################
        echo "second step"
        #Find names of all reads in region
        singularity exec $samtoolssif \
        samtools view ${ind}_${region1}.bam | awk '{print $1}' > names.txt
        
        #extract all reads mapped and in pairs with one of these names, add heades
        singularity exec $samtoolssif \
        samtools view -@ $SLURM_CPUS_ON_NODE -N names.txt $bam | cat header.sam - | singularity exec \
        $samtoolssif samtools view -@ $SLURM_CPUS_ON_NODE -Sb - > ${ind}_${region1}_all.bam
        
        # Index bam
        singularity exec $samtoolssif \
        samtools index -@ $SLURM_CPUS_ON_NODE ${ind}_${region1}_all.bam   
        
        # Make bam into fastqs
        singularity exec $samtoolssif \
        samtools fastq -@ $SLURM_CPUS_ON_NODE -1 ${ind}_${region1}_all_R1.fq -2 ${ind}_${region1}_all_R2.fq -n ${ind}_${region1}_all.bam
        
        rm ${ind}_${region1}.bam* names.txt header.sam ${ind}_${region1}_all.bam*

done




