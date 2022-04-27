#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=50G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=odgiviz      # Sensible name for the job
#SBATCH --output=log-odgiviz-%j.log  # Logfile output here


cd "$SCRATCH"/data/prdm9

graph=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-final.out/newfull.fasta.826b7f9.4030258.a547c55.smooth.og

#singularity exec /mnt/users/ankjelst/tools/pggb_v0.2.0.sif odgi sort -i "$graph" -o sorted.og -O
#singularity exec /mnt/users/ankjelst/tools/pggb_v0.2.0.sif odgi paths -i sorted.og -L
singularity exec /mnt/users/ankjelst/tools/pggb_v0.2.0.sif odgi viz -i $graph -o zf.png -x 500 -s"#" -r "SimonResolved#2#sige:1-10671"
