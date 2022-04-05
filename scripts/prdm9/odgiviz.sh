#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=50G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=odgiviz      # Sensible name for the job
#SBATCH --output=log-odgiviz-%j.log  # Logfile output here


cd "$SCRATCH"/data/prdm9

graph="$SCRATCH"/data/prdm9/pggb-TEST-G13117,13219-k84.out/newfull.fasta.8882a41.eefcd36.1b4c821.smooth.og

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi viz -i "$graph" -o zf.png -x 500 -s"#" -r "Simon#1#05:12773150-12773892"
