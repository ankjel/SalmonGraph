#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb-minimap  # sensible name for the job
#SBATCH --mem=40G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-minimap-pggb-%j.out

#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

echo "start"
date

fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf-candidates_v1_PanSN-spec.fasta

#seqwish
param_k=80
param_B=10000000

#smoothxg
param_i=0.7
param_H=16

cd $TMPDIR/$USER

mkdir jobdir

cd jobdir

echo "copy files to tmpdir"

ref=/mnt/SCRATCH/ankjelst/data/prdm9/prdm9_exon_ref.fasta

echo "running minimap2"

singularity exec /cvmfs/singularity.galaxyproject.org/m/i/minimap2:2.22--h5bf99c6_0 \
minimap2 -xasm10 -c -t $SLURM_CPUS_ON_NODE $ref $fasta > minimap.paf

echo "running seqwish"

cat $ref $fasta > merged.fasta

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif \
seqwish -s merged.fasta -b minimap -p minimap.paf -g minimap_seqwish.gfa -k $param_k --threads=$SLURM_CPUS_ON_NODE


echo "running smoothxg"
singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif \
smoothxg -g minimap_seqwish.gfa -o minimap_seqwish_smooth.gfa -t $SLURM_CPUS_ON_NODE



echo "copy files back to scratch"

cp minimap.paf minimap_seqwish_smooth.gfa $SCRATCH

cd .. 

echo "remove files from tmpdir"

rm -rf jobdir # remove all temporary files 

echo "finished"

date 

