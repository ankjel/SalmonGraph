#!/bin/bash

#SBATCH --ntasks=4
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=giraffe  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-giraffe-%j.out


gfa=$(ls q)
refheader="Simon#1#sigextension"
fragment_mean=255

cd $SCRATCH/prdm9_genotyping.out/test

fq1=$(ls $SCRATCH/prdm9_genotyping.out/maxine/*_R1.fq)
fq2=$(ls $SCRATCH/prdm9_genotyping.out/maxine/*_R2.fq)


name=maxine

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg autoindex \
--prefix "$name" --workflow giraffe --threads $SLURM_CPUS_ON_NODE --gfa "$gfa" --gbwt-buffer-size 200 #--request XG 

# vcf + fasta would be better, but I will try both I guess?
# for vcf + fasta I will have to: choose a reference, make a fasta with only reference, use vcf from deconstruct (?)


# Run giraffe!
#######################

echo "Running giraffe"

#https://github.com/vgteam/vg/pull/2441

# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
--named-coordinates --fragment-mean 300 --fragment-stdev 90 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2"  --threads $SLURM_CPUS_ON_NODE --output-basename maxine --hit-cap 5:10:1 --distance-limit 50:400:50 --cluster-score 5:65:20


#singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
#--named-coordinates -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads #$SLURM_CPUS_ON_NODE > mapped_"$fragment_mean".gam

# https://github.com/vgteam/vg/wiki/Mapping-short-reads-with-Giraffe
# --fragment-mean 600 --fragment-stdev 68 ?



# Print mapping stats
#####################
for file in $(ls *.gam)
do 
    echo $file
    
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a $file
    
done

gam=maxine-D300-c7-C500-F0.9-M1-e800-a8-s50-u0.3-w20-v1.gam

# Variant calling
##################

#  First vg pack because vg call requires a .pack file 

echo "Running vg pack:"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
-x "$gfa" -g $gam -o "$name".pack -t "$SLURM_CPUS_ON_NODE"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg snarls "$gfa" > graph.snarls

# then vg call

echo "Running vg call"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
--pack "$name".pack -t "$SLURM_CPUS_ON_NODE" --ref-path "$refheader" --sample "$name" -r graph.snarls "$gfa" > "$name"_"$fragment_mean".vcf


echo "FINISHED genotyping"

date
