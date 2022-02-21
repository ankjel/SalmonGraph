#!/bin/bash

#BATCH --nodes=1                  
#SBATCH --ntasks=16                  # The number of threads reserved
#SBATCH --mem=99G                     # The amount of memory reserved
#SBATCH --partition=smallmem         
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=pggb       # Sensible name for the job
#SBATCH --output=log-main-%j.log  # Logfile output here
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this


fasta=$1

bed=$2

SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe/slurm-"$SLURM_JOBID"

mkdir -p "$SCRATCHout"

TMPout=$TMPDIR/$USER/$SLURM_JOBID
##########
# Copy input files to tmpdir

mkdir -p "$TMPout" #Not all nodes my TMP dir exist

cd "$TMPout"


# VISOR
# make a new haplotype. Hetrozygous.

singularity exec $homedir/tools/visor.sif VISOR hack -b $h1bed $h2bed -g $ref -o $outhack


## Make two haplotypes for each sample, simon and simulated
# Change the headers to this PanSN-spec format
# https://github.com/pangenome/PanSN-spec

cat "$fasta" | sed 's/^>.*/>simon#1#contig/' > simon1.fa
cat "$fasta" | sed 's/^>.*/>simon#2#contig/' > simon2.fa

cat $hack/h1.fa | sed 's/^>.*/>simulated#1#contig/' > h1.fa
cat $hack/h2.fa | sed 's/^>.*/>simulated#2#contig/' > h2.fa

cat simon1.fa simon2.fa h1.fa h2.fa > pggb.fasta


# run pggb

fasta=$1
haplotypes=$(cat $fasta | grep "^>" | wc -l)

#wfmash
param_s=100 # segment size, this should only be this small because we have a small graph, for full chromosomes set to 100000
param_p=95 # percent identity in the wfmash step, including variants. This should not be so strict for this small example
param_n=$haplotypes  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_K=16 # Kmer size for aligning
param_i="$(basename $fasta)" 
param_l=300 # minimum block length filter for mapping. (segments are merged to blocks, default 3*segment-length)


#seqwish
param_k=84 #filter exact matches below this length [default: 29]

#smoothxg
param_H=$haplotypes # number of haplotypes, if different than that set with -n
param_G=20000 # target sequence length for POA, first pass = N, second pass = M [default: 13117,13219]


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
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $out -G $param_G -V $param_V -L -v -l $param_l

#run giraffe + vg call

name=$1
gfa=$2
outdir=$3
refheader=$4

fq1=$(ls *_R1.fq)
fq2=$(ls *_R2.fq)



singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg autoindex \
--request XG --prefix "$name" --workflow giraffe --threads $SLURM_CPUS_ON_NODE --gfa "$gfa" 



echo "Running giraffe"


# Giraffe input is the very VG-specific files created with vg autoindex above.

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg giraffe \
--fragment-mean 300 --fragment-stdev 68 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > mapped.gam

# https://github.com/vgteam/vg/wiki/Mapping-short-reads-with-Giraffe
# --fragment-mean 600 --fragment-stdev 68 ?



# Print mapping stats
#####################

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg stats -a mapped.gam


# Variant calling
##################

#  First vg pack because vg call requires a .pack file 

echo "Running vg pack:"

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg pack \
-x "$gfa" -g mapped.gam -o "$name".pack -t "$SLURM_CPUS_ON_NODE" 


# then vg call

echo "Running vg call"

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg call \
-a --pack "$name".pack -t "$SLURM_CPUS_ON_NODE" --ref-path "$refheader" --sample "$name" "$gfa" > "$name"_"$refheader".vcf


echo "FINISHED giraffe + vg call"


# running pangenie


deconstructed_vcf=$(ls "$pggbout"/*Simon.vcf)

###############################################################
# Remove all nested variants from deconstruct-vcf i.e. LV > 0

echo "Filter vcf"

#singularity exec /cvmfs/singularity.galaxyproject.org/b/c/bcftools:1.10.2--hd2cd319_0 \
#bcftools view -i 'INFO/LV=0' --no-version $deconstructed_vcf  > $filtered_vcf

# bcftools removed the format column. Should write a regex, but feel like a script is safer. 
# Erik Garrison already wrote one


singularity exec $homedir/tools/rust.sif $homedir/tools/vcfbub -i $deconstructed_vcf --max-level 0 > $filtered_vcf  


####################################################
# cat fastq files. Pangenie is k-mer based so will not use the readpair information.
# and only allowes for one read input in either fastq or fasta format.

echo "cat fastqs"

cat $fq1 $fq2 > $reads

#######################
# Run pangenie 


echo "Run pangenie"

$homedir/tools/pangenie/build/src/PanGenie -i $reads -r $fasta -v $filtered_vcf -t $SLURM_CPUS_ON_NODE -j $SLURM_CPUS_ON_NODE -o pangenie

##########################
# resolve nested genotypes

echo "Resolve nested genotypes"

# zip vcf so we can index it
singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip pangenie_genotyping.vcf 
# Index new vcf for resolving nested genotypes
singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf pangenie_genotyping.vcf.gz


$homedir/tools/resolve-nested-genotypes $deconstructed_vcf pangenie_genotyping.vcf.gz > resolved_genotypes.vcf




cp *.vcf "$SCRATCHout"
cd ..

rm -r "$TMPout"

echo "FINISHED"