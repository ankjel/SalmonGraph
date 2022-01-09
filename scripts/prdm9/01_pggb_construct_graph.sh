#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=30G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-pggb-%j.out

#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

#INPUT : full path to one fasta file

echo "START"
date



######
## Parameters

fasta=$1

#wfmash
param_s=100000
param_p=98
param_n=16  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_K=8
param_i="$(basename $fasta)"


#seqwish
param_k=85

#smoothxg
param_H=16
param_G=200000


#deconstruct
#param_V=ssa05:sample.list  
#OBSOBS the reference for the vcf here
#specify a set of VCFs to produce with SPEC = [REF:SAMPLE_LIST_FILE] the paths matching ^REF are used as a reference
param_V='Simon:#,Maxine:#'


SCRATCHout=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-$param_i-G$param_G-k$param_k.out

out=pggb-G$param_G.out

##########
# Copy input files to tmpdir

mkdir -p $TMPDIR/$USER #Not all nodes my TMP dir exist

cd $TMPDIR/$USER

cp $fasta .

####
# Running pggb

echo "RUN PGGB"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $out -G $param_G -V $param_V -L -v

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
