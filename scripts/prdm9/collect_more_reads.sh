#!/bin/bash

echo "STARTED COLLECTING READS"
date

###############
# tmp dir

FILE="$1"
outdir="$2"


samtoolssif=/cvmfs/singularity.galaxyproject.org/s/a/samtools:1.14--hb421002_0

region='ssa05:12773150-12773892' # This depends on the reference- 
# Øyvind 12773150-12773892 Kristina 12773188-127773343 for simon
name=$(basename "$FILE" .cram)


#############################################
# Find all the reads mapping to our region
#############################################
echo "first step"
#singularity exec $samtoolssif \
#samtools view -@ $SLURM_CPUS_ON_NODE -H $FILE > header.sam # Extract the header to merge with reads later for valid bam
# First: subset region, second: cat header and region for valid sam, 
#third: S ignore compability something abot samtools version, b bam output 

singularity exec $samtoolssif \
samtools view -@ $SLURM_CPUS_ON_NODE $FILE -hb -F 4 "$region" > "$name"_"$region".bam
 # -F 4 exclude unmapped reads

# index new bam file
singularity exec $samtoolssif \
samtools index -@ $SLURM_CPUS_ON_NODE "$name"_"$region".bam

#########################################################
# Get all the pairs where one maps to regionq
########################################################
echo "second step"
#Find names of all reads in region
singularity exec $samtoolssif \
samtools view "$name"_"$region".bam | awk '{print $1}' > names.txt

#extract all reads mapped and in pairs with one of these names, add heades
singularity exec $samtoolssif \
samtools view -@ $SLURM_CPUS_ON_NODE -hb -N names.txt "$FILE" >"$name"_"$region"_all.bam

# Index bam
singularity exec $samtoolssif \
samtools index -@ $SLURM_CPUS_ON_NODE "$name"_"$region"_all.bam   

# From bam to fastqs
singularity exec $samtoolssif samtools sort -n "$name"_"$region"_all.bam | singularity exec $samtoolssif \
samtools fastq -@ $SLURM_CPUS_ON_NODE -1 "$name"_"$region"_R1.fq -2 "$name"_"$region"_R2.fq -n

echo "FINISHED"
date
