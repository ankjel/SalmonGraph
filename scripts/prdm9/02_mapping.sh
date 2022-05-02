#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=16                  # The number of threads reserved
#SBATCH --mem=200G                     # The amount of memory reserved
#SBATCH --partition=hugemem         # For < 100GB use smallmem, for >100GB use hu
#SBATCH --job-name=giraffe       # Sensible name for the job
#SBATCH --output=log-giraffe-%j.log  # Logfile output here
#SBATCH --mail-user=anna.sofie.kjelstrup@nmbu.no # Email me when job is done.
#SBATCH --mail-type=ALL


# This one is not finished

###########################
#Read mapping with giraffe!
###########################


# Prep3
##################################
fasta=/mnt/SCRATCH/ankjelst/data/prdm9/newfull.fasta 
gfa=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-final-k311-p98.out/prdm9-znf.fasta-chop.gfa
fq1original=$1
fq2original=$2

outdir=/mnt/SCRATCH/ankjelst/data/prdm9/"$SLURM_JOB_ID"

if [ ! -d $outdir ]
then
mkdir $outdir
fi

#tmpdir
tmpdir="$TMPDIR"/"$USER"/job-"$SLURM_JOBID" # one tmpdir for each 
mkdir -p "$tmpdir"
cd "$tmpdir"

echo "Copy fqs to tmpdir"

cp $fq1original $fq2original .

fq1gz=$(basename "$fq1original")
fq2gz=$(basename "$fq2original")

echo "Decompress fqs"
pigz -d -p "$SLURM_CPUS_ON_NODE" "$fq1gz" "$fq2gz"

fq1=$(basename "$fq1gz" .gz)
fq2=$(basename "$fq2gz" .gz)

name=$(echo "$fq1"| cut -d'_' -f 3)


# Choose a referance for genotype calling
refheader="SimonResolved#2#znfArray" # this is the shortest, thats why ipicked this, vcf is easier to read

echo "fasta:" $fasta
echo "fastq dir:" $fqs

echo "gfa:" $gfa
echo "fq1:" $fq1
echo "fq2:" $fq2
echo "name:" $name
echo "referance for genotyping" $refheader

echo "genotype"
/mnt/users/ankjelst/MasterScripts/scripts/prdm9/genotyping-odgi.sh "$name" "$gfa" "$refheader" "$fq1" "$fq2"

mv *.txt *.vcf "$outdir"

cd ..

rm -r "$tmpdir"


