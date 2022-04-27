#!/bin/bash

name=$1
gfa=$2
refheader=$3
fq1=$4
fq2=$5


singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg deconstruct -p 'SimonResolved#2#sige' -e -a -t $SLURM_CPUS_ON_NODE $gfa > deconstructed.vcf

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg gbwt -g "$name".giraffe.gbz --gbz-format -G "$gfa" --path-regex "(.*)#(.*)#(.*)" --path-fields _SHC --max-node 0



singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg snarls -T "$name".giraffe.gbz > "$name".snarls
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg index -s "$name".snarls -j "$name".dist -p -b $TMPDIR/$USER "$name".giraffe.gbz
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg minimizer -o "$name".min -d "$name".dist "$name".giraffe.gbz


# Run giraffe!
#######################

echo "Running giraffe"


# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
--fragment-mean 400 --fragment-stdev 75 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > "$name".gam

# https://github.com/vgteam/vg/wiki/Mapping-short-reads-with-Giraffe
# --fragment-mean 600 --fragment-stdev 68 ?



# Print mapping stats
#####################

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a "$name".gam


# Variant calling
##################

#  First vg pack because vg call requires a .pack file q

echo "Running vg pack:"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
-x "$name".giraffe.gbz -g "$name".gam -o "$name".pack -t $SLURM_CPUS_ON_NODE -d > packtable.txt


# then vg call

echo "Running vg call"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
-a -A --pack "$name".pack  -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa" > "$name"_simon.vcf

