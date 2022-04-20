#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=50G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=odgiviz      # Sensible name for the job
#SBATCH --output=log-odgiviz-%j.log  # Logfile output here


cd /mnt/users/ankjelst/MasterScripts/scripts/sim 

graph=$1

name=$(basename "$graph" .gfa)

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi viz -i "$graph" -o "$name".png  -s"#" #-r "SimonResolved#2#sige:1-10671"
