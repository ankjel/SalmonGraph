#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=4                  # The number of threads reserved
#SBATCH --mem=3G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hugemem
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=giraffe       # Sensible name for the job
#SBATCH --output=log-giraffe-%j.log  # Logfile output here

# This one is not finished

###########################
#Read mapping with giraffe!
###########################


# Prep
##################################

out_dir=/mnt/SCRATCH/ankjelst/data/giraffe/prdm9

if [ ! -d $out_dir ]
then
mkdir $out_dir
fi

# cd to where I want the vg autoindex output
cd $out_dir

echo $(pwd)

fasta=$1 
pggb_dir=$2
fqs=$3 #fastq files path+ basename /mnt/SCRATCH/ankjelst/data/prdm9/tess.cram_ssa05:12773150-12773892_all

gfa=$(ls "$pggb_dir"*.smooth.gfa)

# Do we really need a vcf?
#vcf=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.ssa22.vcf

fq1="$fqs"_R1.fq
fq2="$fqs"_R2.fq

# need better solution for defining name and fq when doing this later
name=maxine

# Choose a referance for genotype calling
refheader="Simon#1#sig"

echo "fasta:" $fasta
echo "pggb dir:" $pggb_dir
echo "fastq dir:" $fqs

echo "gfa:" $gfa
echo "fq1:" $fq1
echo "fq2:" $fq2
echo "name:" $name
echo "referance for genotyping" $refheader

# We need to index our graph
##################################

# this fasta is the one the graph is made from

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg autoindex \
--request XG --prefix $name --workflow giraffe --threads $SLURM_CPUS_ON_NODE --gfa $gfa 

# vcf + fasta would be better, but I will try both I guess?
# for vcf + fasta I will have to: choose a reference, make a fasta with only reference, use vcf from deconstruct (?)


# Run giraffe!
#######################

echo "Running giraffe"


# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg giraffe \
--fragment-mean 300 --fragment-stdev 68 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > mapped.gam

# https://github.com/vgteam/vg/wiki/Mapping-short-reads-with-Giraffe
# --fragment-mean 600 --fragment-stdev 68 ?



# Print mapping stats
#####################

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg stats -a mapped.gam


# Variant calling
##################

#  First vg pack because vg call requires a .pack file 

echo "Running vg pack:"

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg pack \
-x $gfa -g mapped.gam -o "$name".pack -t $SLURM_CPUS_ON_NODE 


# then vg call

echo "Running vg call"

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg call \
-A --pack "$name".pack -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name $gfa > "$name"_simon.vcf
