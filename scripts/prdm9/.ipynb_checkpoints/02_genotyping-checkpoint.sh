#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=99G                     # The amount of memory reserved
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

out_dir=/mnt/SCRATCH/ankjelst/data/giraffe

if [ ! -d $out_dir ]
then
mkdir $out_dir
fi

# cd to where I want the vg autoindex output
cd $out_dir

echo $(pwd)

gfa=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-G5G.out/PRDM9a_znf-candidates_v1_PanSN-spec.fasta.2dd9516.8f341e3.c0b3beb.smooth.gfa
fasta=/mnt/SCRATCH/ankjelst/data/simon22.fasta
vcf=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.ssa22.vcf

fq1=/mnt/SCRATCH/ankjelst/data/art/sim_r_sim_SV1.fq
fq2=/mnt/SCRATCH/ankjelst/data/art/sim_r_sim_SV2.fq

###########################################
# Need a fasta with only reference sequence


refHeader=Simon#1#majorityconsensus


singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools:1.14--hb421002_0 \
samtools faidx fasta $refHeader > 


# We need to index our graph
##################################

# this fasta is the one the graph is made from

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif vg autoindex \
--prefix visorpggb --workflow giraffe --threads 8 --gfa $gfa --ref-fasta $fasta


# Run giraffe!
#######################

echo "Running giraffe"


# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif vg giraffe \
-Z visorpggb.giraffe.gbz -m visorpggb.min -d visorpggb.dist -f $fq1 -f $fq2 > mapped.gam

# https://github.com/vgteam/vg/wiki/Mapping-short-reads-with-Giraffe



# Print mapping stats
#####################

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif vg stats -a mapped.gam


# Variant calling
##################

#  First vg pack because vg call requires a .pack file 

echo "Running vg pack:"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif vg pack \
-x $gfa -g mapped.gam -o visorpggb.pack -Q 5 -t $SLURM_CPUS_ON_NODE


# then vg call

echo "Running vg call"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif vg call \
$gfa --pack visorpggb.pack --ref-fasta $fasta -t $SLURM_CPUS_ON_NODE > genotypes.vcf
