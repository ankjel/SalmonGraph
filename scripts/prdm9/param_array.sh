#!/bin/bash
#SBATCH --array=1-3 # run 50 jobs, max 10 at a time --array=1-50%10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem=3G
#SBATCH --partition=smallmem
#SBATCH --job-name=pggb-param
#SBATCH --output=logs/log-param-%j-%a.out
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this


set -o errexit # exit on errors
set -o nounset # treat unset variables as errors


echo "START"

param=$1 # which parameter to test
param_file=$2

echo "PARAM:" "$param"
param_value=$(cat $param_file | awk 'FNR=='"$SLURM_ARRAY_TASK_ID"'')
# extract the array#-line of the param_file
echo "PARAM VALUE:"
echo "$param_value"
#sample to be genotyped
name="Maxine"
fq1="/mnt/SCRATCH/ankjelst/prdm9_genotyping.out/maxine/maxine_ssa05:12773150-12773892_R1.fq"
fq2="/mnt/SCRATCH/ankjelst/prdm9_genotyping.out/maxine/maxine_ssa05:12773150-12773892_R2.fq"
refheader="Simon#1#sig" # use this haplotype as reference when genotyping

####################
# PGGB

fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf_sig_maxine.fasta
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

if [ "$param" == 'G' ]
then
    param_G="$param_value"
elif [ "$param" == 's' ]
then
    param_s="$param_value"
elif [ "$param" == 'p' ]
then
    param_p="$param_value"
elif [ "$param" == 'K' ]
then
    param_K="$param_value"
elif [ "$param" == 'k' ]
then
    param_k="$param_value"
elif [ "$param" == 'l' ]
then
    param_l="$param_value"
else
    echo "Not a valid parameter"
fi

SCRATCHout=/mnt/SCRATCH/ankjelst/"$param"_test/slurm-"$SLURM_JOBID"-"$param"-"$param_value"

mkdir -p "$SCRATCHout"

out=pggb-G$param_G.out
TMPout=$TMPDIR/$USER/$SLURM_JOBID-$SLURM_ARRAY_TASK_ID
##########
# Copy input files to tmpdir

mkdir -p "$TMPout" #Not all nodes my TMP dir exist

cd "$TMPout"
cp $fasta .

####
# Running pggb

echo "RUN PGGB"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $out -G $param_G -V $param_V -L -v -l $param_l


echo "pggb FINISHED"


echo "LS"

ls -lah

echo "ls out"

ls "$out"

echo "pwd"

pwd


#################
# Genotyping

gfa=$(ls "$out"/*.smooth.gfa)

singularity exec /mnt/users/ankjelst/tools/vg_v1.37.0.sif vg autoindex \
--request XG --prefix "$name" --workflow giraffe --threads $SLURM_CPUS_ON_NODE --gfa "$gfa" 

# vcf + fasta would be better, but I will try both I guess?
# for vcf + fasta I will have to: choose a reference, make a fasta with only reference, use vcf from deconstruct (?)


# Run giraffe!
#######################

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


echo "FINISHED genotyping"

date


cp *.vcf "$out"/*.vcf "$out"/*.smooth.gfa "$SCRATCHout"

cd ..

rm -r $TMPout

