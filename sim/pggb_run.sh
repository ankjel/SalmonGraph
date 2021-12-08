#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=40G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-pggb-%j.out

#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

#INPUT : full path to one fasta file

echo "START"
date


OUTDIR=/mnt/SCRATCH/ankjelst/data/pggb.out

INPUT=/mnt/SCRATCH/ankjelst/data/visor.hack/mergedVISOR.fasta

TMPOUT='pggb.out'

BASENAME="$(basename $INPUT)"

mkdir -p $TMPDIR/$USER #Not all nodes my TMP dir exist

cd $TMPDIR/$USER

cp $INPUT .  

if [ ! -d $out_dir ]
then
mkdir $out_dir
fi


echo "RUN PGGB"



singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif pggb -i $BASENAME -s 100000 -p 97 -n 10 -t $SLURM_CPUS_ON_NODE -I 0.7 -S -m -k 311 -o $TMPOUT -V ssa22:sample.list -N 
echo "MOVE FILES TO SCRATCH"

mkdir -p $OUTDIR

mv -v $TMPOUT/* $OUTDIR

cd ..

echo "DELETE TMP-FILES"

ls $TMPDIR/$USER

rm -r $TMPDIR/$USER/*

echo "AFTER deleting"

ls $TMPDIR/$USER

echo "FINISHED"

date
