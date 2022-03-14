#!/bin/bash

#SBATCH --ntasks=4
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=samtools  # sensible name for the job
#SBATCH --mem=5G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-samtools-%j.out

singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools:1.12--h9aed4be_1 \
samtools stats -@ $SLURM_CPUS_ON_NODE $SCRATCH/data/crams/maxine.cram > $SCRATCH/data/prdm9/maxine.stats

