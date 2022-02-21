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

tmpdir="$TMPDIR"/"$USER"/sim # one tmpdir for each
mkdir -p "$tmpdir"
cd "$tmpdir"

datadir=/mnt/SCRATCH/ankjelst/data
h1bed=$datadir/ssa22variants.bed
h2bed=$datadir/ssa22empty.bed
ref=$datadir/simon22.fasta
outhack=$datadir/test.visor
homedir=/mnt/users/ankjelst
mergedfasta=$outhack/mergedVISOR.fasta
artout="$datadir"/art


####
# Run hack to insert SV into fasta

singularity exec $homedir/tools/visor.sif VISOR hack -b $h1bed $h2bed -g $ref -o $outhack



#####
# Run SHOrTS to simulate illumina reads
#outshorts=$datadir/visor.shorts


#find length og longest sequence for read simulation 
#cut -f1,2 $outhack/*.fai > haplochroms.dim.tsv
#chr22 from haplotype 2 is 1000000 base pairs smaller than the one from haplotype 1. For each chromosome, we get the maximum dimension. This is necessary to calculate accurately the number of reads to simulate for each chromosome
#cat haplochroms.dim.tsv | sort  | awk '$2 > maxvals[$1] {lines[$1]=$0; maxvals[$1]=$2} END { for (tag in lines) print lines[tag] }' > maxdims.tsv
#create a BED to simulate reads from chr22, without coverage fluctuations (that is, capture bias value in 4th column is 100.0) and without normal contamination (that is, purity value in 5th column is 100.0) 
#awk 'OFS=FS="\t"''{print $1, "1", $2, "100.0", "100.0"}' maxdims.tsv > $datadir/shorts.laser.simple.bed
#multiple entries can of course be specified in the same BED

# we will not use the command below as we do not need haplotype resolved reads.
# We will rather simulate reads directly with wgsim as used in SHORtS or ART, another well known read-simulator.



#singularity exec $homedir/tools/visor.sif VISOR SHORtS \
#-s $outhack -b $datadir/shorts.laser.simple.bed -g $ref -o $outshorts --threads $SLURM_CPUS_ON_NODE  --coverage 2 --fastq


echo "Merge files into one fasta"


# changing the header names
sed 's/>.*/>simulated#1#contig/' $outhack/h1.fa > h1named.fa
sed 's/>.*/>simulated#2#contig/' "$ref" > h2named.fa

cat $datadir/h1named.fa $datadir/refnamed.fa > simulated2hap.fa

# changing the header names
sed 's/>.*/>simon#1#contig/' "$ref" > ref1.fa
sed 's/>.*/>simon#2#contig/' "$ref" > ref2.fa

cat ref1.fa ref2.fa > ref2hap.fa

#this fasta will be used for pggb
cat ref2hap.fa simulated2hap.fa > pggb.fa



input_fasta=$outhack/h1.fa
outdir=/mnt/SCRATCH/ankjelst/data/art

singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
art_illumina --seqSys HS25 -sam --in simulated2hap.fa --paired --len 150 --fcov 20 --mflen 200 --sdev 10 --out simulated2hap

singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
art_illumina --seqSys HS25 -sam --in simon2hap.fa --paired --len 150 --fcov 20 --mflen 200 --sdev 10 --out simon2hap

cp pggb.fa $datadir
cd ..
rm -r "$tmpdir"


echo "FINISHED"
date

