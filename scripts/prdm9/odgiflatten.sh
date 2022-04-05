#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=10G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=odgiflatten      # Sensible name for the job
#SBATCH --output=log-odgiflatten-%j.log  # Logfile output here


cd "$SCRATCH"/data/prdm9/gfatofa


graph="$SCRATCH"/data/prdm9/pggb-TEST-G13117,13219-k84.out/newfull.fasta-chop.gfa





singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi flatten -i "$graph" -b test.bed -f test.fasta -t "$SLURM_CPUS_ON_NODE"

module load BEDTools

bedtools getfasta -fi test.fasta -bed <(awk '$4 == "SimonResolved#1#sige"' test.bed) > final.fasta

