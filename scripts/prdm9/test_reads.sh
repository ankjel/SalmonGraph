#!/bin/bash

#SBATCH --ntasks=4
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=giraffe  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-giraffe-%j.out

refheader="Simon#1#sige"


cd $SCRATCH/prdm9_genotyping.out/test

fq1=$(ls /mnt/SCRATCH/ankjelst/prdm9_genotyping.out/PRDM9a_znf-sig_Simon_10kb_extension_v1.fasta/arnold/*_R1.fq)
fq2=$(ls /mnt/SCRATCH/ankjelst/prdm9_genotyping.out/PRDM9a_znf-sig_Simon_10kb_extension_v1.fasta/arnold/*_R2.fq)

gfa=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf-sig_Simon_10kb_extension_v1.fasta-G13117,13219-k84.out/PRDM9a_znf-sig_Simon_10kb_extension_v1.fasta-chop.gfa

name=arnold

#Indexing
#########
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg gbwt -g "$name".giraffe.gbz --gbz-format -G "$gfa" --path-regex "(.*)#(.*)#(.*)" --path-fields _SHC --max-node 0



singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg snarls -T "$name".giraffe.gbz > "$name".snarls
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg index -s "$name".snarls -j "$name".dist -p -b $TMPDIR/$USER "$name".giraffe.gbz
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg minimizer -o "$name".min -d "$name".dist "$name".giraffe.gbz


# Run giraffe!
#######################

echo "Running giraffe"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
--fragment-mean 400 --fragment-stdev 50 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE -c 2:14:2 -C 250:500:250 -D 50:200:50 --output-basename $name




# Print mapping stats
#####################
for file in $(ls *.gam)
do 
    echo $file
    
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a $file
    

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
    -x "$gfa" -g "$file" -o "$file".pack -t "$SLURM_CPUS_ON_NODE"


    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
    --pack "$file".pack -t "$SLURM_CPUS_ON_NODE" --ref-path "$refheader" --sample "$name" -r -a -A "$name".snarls "$gfa" > "$name"_"$file".vcf

done


echo "FINISHED genotyping"

date


