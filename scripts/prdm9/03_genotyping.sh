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

gfa=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf_sig.fasta-G20000-k84.out/PRDM9a_znf_sig.fasta.bfda8cb.eefcd36.008d801.smooth.gfa
fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf_sig.fasta
# Do we really need a vcf?
#vcf=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.ssa22.vcf

fq1=/mnt/SCRATCH/ankjelst/data/prdm9/tess.cram_ssa05:12773150-12773892_all_R1.fq
fq2=/mnt/SCRATCH/ankjelst/data/prdm9/tess.cram_ssa05:12773150-12773892_all_R2.fq

# need better solution for defining name and fq when doing this later
name=tess

# We need to index our graph
##################################

# this fasta is the one the graph is made from

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg autoindex \
--prefix visorpggb --workflow giraffe --threads $SLURM_CPUS_ON_NODE --gfa $gfa 

# vcf + fasta would be better, but I will try both I guess?
# for vcf + fasta I will have to: choose a reference, make a fasta with only reference, use vcf from deconstruct (?)


# Run giraffe!
#######################

echo "Running giraffe"


# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg giraffe \
-Z visorpggb.giraffe.gbz -m visorpggb.min -d visorpggb.dist -f $fq1 -f $fq2 > mapped.gam

# https://github.com/vgteam/vg/wiki/Mapping-short-reads-with-Giraffe



# Print mapping stats
#####################

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg stats -a mapped.gam


# Variant calling
##################

#  First vg pack because vg call requires a .pack file 

echo "Running vg pack:"

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg pack \
-x $gfa -g mapped.gam -o $namepggb.pack -t $SLURM_CPUS_ON_NODE 


# then vg call

echo "Running vg call"

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg call \
--pack visorpggb.pack -t $SLURM_CPUS_ON_NODE --ref-path "Simon#1#sig" --ref-path "Maxine#1#sig" --sample $name $gfa > simon.vcf maxine.vcf
