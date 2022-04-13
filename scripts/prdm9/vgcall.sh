#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=50G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=vgcall      # Sensible name for the job
#SBATCH --output=log-vgcall-%j.log  # Logfile output here

cd "$SCRATCH"/data/prdm9/14322545

pggb_dir="$SCRATCH"/data/prdm9/pggb-TEST-G13117,13219-k84.out

name=MAXINE

gfa=$(ls "$pggb_dir"/*chop.gfa)
refheader="SimonResolved#2#sige"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a "$name".gam


singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
-x "$name".giraffe.gbz -g "$name".gam -o "$name".pack -t $SLURM_CPUS_ON_NODE


# then vg call

echo "Running vg call -a -A"


singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
-a -A --pack "$name".pack  -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa" > "$name"_simon.vcf




date 
