#!/bin/bash

#SBATCH --ntasks=16
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=99G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-pggb-v020-%j.log

#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

#INPUT : full path to one fasta file

echo "START"
date


######
## Parameters

fasta=/mnt/SCRATCH/ankjelst/data/visor.hack/mergedVISOR.fasta

#wfmash
param_s=100000
param_p=95
param_n=5
param_K=19
param_i="$(basename $fasta)"


#seqwish
param_k=311 # default 29, 85 for prmd9?

#smoothxg
param_H=2
param_G=5G


out=pggb-v020-G$param_G-k$param_k.out

SCRATCHout=/mnt/SCRATCH/ankjelst/data/$out


# -V will be the header of the reference for VCF file

param_V=ssa22:#



##########
# Copy input files to tmpdir

mkdir -p $TMPDIR/$USER #Not all nodes my TMP dir exist

cd $TMPDIR/$USER

cp $fasta .

####
# Running pggb

echo "RUN PGGB"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $out -G $param_G -V $param_V  #OBSOBS the reference for the vcf here
#specify a set of VCFs to produce with SPEC = [REF:SAMPLE_LIST_FILE] the paths matching ^REF are used as a reference


echo "MOVE FILES TO SCRATCH"

mkdir -p $SCRATCHout

mv -v $out/* $SCRATCHout

cd ..

echo "DELETE TMP-FILES"

ls $TMPDIR/$USER

rm -r $TMPDIR/$USER/*

echo "AFTER deleting"

ls $TMPDIR/$USER

echo "FINISHED"

date
