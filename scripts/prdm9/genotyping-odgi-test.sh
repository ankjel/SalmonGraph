#!/bin/bash

name=$1
gfa=$2
refheader=$3
fq1=$4
fq2=$5




# vcf + fasta would be better, but I will try both I guess?
# for vcf + fasta I will have to: choose a reference, make a fasta with only reference, use vcf from deconstruct (?)

# https://github.com/vgteam/vg/issues/3455

# do the chopping of graph nodes in construction script since it is the same for alle samples
#singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi chop -c 1024 -i $odgi -o new.og
#singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi view -i new.og --to-gfa > new.gfa

echo "Deconstruct"
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg deconstruct -p "$refheader" -e -a -t $SLURM_CPUS_ON_NODE $gfa > deconstructed.vcf

echo "gbwt"
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg gbwt -g "$name".giraffe.gbz --gbz-format -G "$gfa" --path-regex "(.*)#(.*)#(.*)" --path-fields _SHC --max-node 0

echo "snarls"

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg snarls -T "$name".giraffe.gbz > "$name".snarls

echo "index"
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg index -s "$name".snarls -j "$name".dist -p -b $TMPDIR/$USER "$name".giraffe.gbz

echo "minimizer"
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg minimizer -o "$name".min -d "$name".dist "$name".giraffe.gbz


# Run giraffe!
#######################

echo "Mapping: giraffe"


# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
-Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > "$name".gam

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
-x "$name".giraffe.gbz -g "$name".gam -o "$name".pack -t $SLURM_CPUS_ON_NODE 


# then vg call

echo "Running vg call -a -A"


singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
-a -A --pack "$name".pack  -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa" > "$name"_simon_alt.vcf




