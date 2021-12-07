#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=60G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hugemem
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=ART       # Sensible name for the job
#SBATCH --output=log-ART-%j.log  # Logfile output here


input_fasta=visor/visor.hack/h1.fa



singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
art_illumina --seqSys HS25 -sam --in $input_fasta --paired --len 150 --fcov 20 --mflen 200 --sdev 10 --out sim_r_sim_SV




# example command for paired ends

# art_illumina -ss HS25 -sam -i reference.fa -p -l 150 -f 20 -m 200 -s 10 -o paired_dat


