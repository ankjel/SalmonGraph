#!/bin/bash

#BATCH --nodes=1                  # We always use 1 node
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=10G                     # The amount of memory reserved
#SBATCH --partition=smallmem         # For < 100GB use smallmem, for >100GB use hugemem
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=visor       # Sensible name for the job
#SBATCH --output=log-VISOR-%j.log  # Logfile output here


echo "START"
date


datadir=/mnt/SCRATCH/ankjelst/data
h1bed=$datadir/ssa22variants.bed
h2bed=$datadir/ssa22empty.bed
ref=$datadir/simon22.fasta
outhack=$datadir/test.visor
homedir=/mnt/users/ankjelst
mergedfasta=$outhack/mergedVISOR.fasta


####
# Run hack to insert SV into fasta

singularity exec $homedir/tools/visor.sif VISOR hack -b $h1bed $h2bed -g $ref -o $outhack



#####
# Run SHOrTS to simulate illumina reads
outshorts=$datadir/visor.shorts


#find length og longest sequence for read simulation 
cut -f1,2 $outhack/*.fai > haplochroms.dim.tsv
#chr22 from haplotype 2 is 1000000 base pairs smaller than the one from haplotype 1. For each chromosome, we get the maximum dimension. This is necessary to calculate accurately the number of reads to simulate for each chromosome
cat haplochroms.dim.tsv | sort  | awk '$2 > maxvals[$1] {lines[$1]=$0; maxvals[$1]=$2} END { for (tag in lines) print lines[tag] }' > maxdims.tsv
#create a BED to simulate reads from chr22, without coverage fluctuations (that is, capture bias value in 4th column is 100.0) and without normal contamination (that is, purity value in 5th column is 100.0) 
awk 'OFS=FS="\t"''{print $1, "1", $2, "100.0", "100.0"}' maxdims.tsv > $datadir/shorts.laser.simple.bed
#multiple entries can of course be specified in the same BED

# we will not use the command below as we do not need haplotype resolved reads.
# We will rather simulate reads directly with wgsim as used in SHORtS or ART, another well known read-simulator.



singularity exec $homedir/tools/visor.sif VISOR SHORtS \
-s $outhack -b $datadir/shorts.laser.simple.bed -g $ref -o $outshorts --threads $SLURM_CPUS_ON_NODE  --coverage 2 --fastq


echo "Merge files into one fasta"

# VISOR => the fasta I added SVs to, here I am adding to header name

#sed 's/>.*/&VISOR/' $outhack/h1.fa > $datadir/h1named.fa

# merging the two fasta files

#cat $ref $datadir/h1named.fa > $mergedfasta

# index for the new fasta:

#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools:1.9--h10a08f8_12 samtools faidx $mergedfasta

echo "FINISHED"
date

