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


# Prep3
##################################

outdir=/mnt/SCRATCH/ankjelst/data/prdm9

if [ ! -d $outdir ]
then
mkdir $outdir
fi

#tmpdir
tmpdir="$TMPDIR"/"$USER"/job-"$SLURM_JOBID" # one tmpdir for each 
mkdir -p "$tmpdir"
cd "$tmpdir"

echo $(pwd)

fasta=$1 
pggb_dir=$2
fqs=$3 #fastq files path+ basename /mnt/SCRATCH/ankjelst/data/prdm9/tess.cram_ssa05:12773150-12773892_all

gfa=$(ls "$pggb_dir"/*chop.gfa)

fq1="$fqs"_R1.fq
fq2="$fqs"_R2.fq

name=$(basename $fq1 _ssa05:12773150-12773892_R1.fq)

# Choose a referance for genotype calling
refheader='Simon2#2#sige'

echo "fasta:" $fasta
echo "pggb dir:" $pggb_dir
echo "fastq dir:" $fqs

echo "gfa:" $gfa
echo "fq1:" $fq1
echo "fq2:" $fq2
echo "name:" $name
echo "referance for genotyping" $refheader

echo "genotype"
/mnt/users/ankjelst/MasterScripts/scripts/prdm9/genotyping-odgi.sh "$name" "$gfa" "$refheader" "$fq1" "$fq2"

mv *.vcf "$outdir"

cd ..

rm -r "$tmpdir"