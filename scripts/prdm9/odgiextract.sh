#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=15G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=odgiextract     # Sensible name for the job
#SBATCH --output=log-odgiextract-%j.log  # Logfile output here


cd "$SCRATCH"/data/prdm9/newgraph


graph="$SCRATCH"/data/prdm9/pggb-TEST-G13117,13219-k84.out/newfull.fasta.8882a41.eefcd36.1b4c821.smooth.og


singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi paths -L -i "$graph" | grep -v "Simon#1#05" > paths_to_retain.txt # every path but simon 05

#singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi paths -L -i "$graph" | grep "SimonResolved#2#sige" > paths_to_retain.txt

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi extract -i "$graph" \
-r "Simon#1#05:12773150-12773892" \
--threads "$SLURM_CPUS_ON_NODE" \
--inverse -P \
-o clean.og \
-R paths_to_retain.txt

refpath=$(singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi paths -L -i clean.og | grep "^SimonResolved#2#sige")

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi view -i clean.og -g > clean.gfa
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg deconstruct -p "SimonResolved#2#sige" -H "#" -e clean.gfa > clean.vcf 