#!/bin/bash

#BATCH --nodes=1                  
#SBATCH --ntasks=8 # The number of threads reserved
#SBATCH --mem=120G                     # The amount of memory reserved
#SBATCH --partition=hugemem         
#SBATCH --time=6:00:00              # Runs for maximum this time
#SBATCH --job-name=pggb       # Sensible name for the job
#SBATCH --output=log-main-%j.log  # Logfile output here
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

set -o errexit # exit on errors
set -o nounset # treat unset variables as errors

SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe/slurm-"$SLURM_JOBID"
homedir=/mnt/users/ankjelst

mkdir -p "$SCRATCHout"

TMPout=$TMPDIR/$USER/$SLURM_JOBID
##########
# Copy input files to tmpdir

mkdir -p "$TMPout" #Not all nodes my TMP dir exist

cd "$TMPout"

outhack=sim
ref=/mnt/SCRATCH/ankjelst/data/simon22.fasta
bed=/mnt/SCRATCH/ankjelst/data/ssa22variants.bed
# VISOR
# make a new haplotype. 


singularity exec "$homedir"/tools/visor.sif VISOR hack -b $bed -g $ref -o $outhack


## Make two haplotypes for each sample, simon and simulated
# Change the headers to this PanSN-spec format
# https://github.com/pangenome/PanSN-spec

sed 's/>.*/>simon#1#contig/' "$ref"> simon1.fa
sed 's/>.*/>simon#2#contig/' "$ref"> simon2.fa

sed 's/>.*/>simulated#1#contig/' $outhack/h1.fa > h1.fa
sed 's/>.*/>simulated#2#contig/' "$ref"> h2.fa

cat simon1.fa simon2.fa > simon2hap.fa
cat h1.fa h2.fa > simulated2hap.fa

cat simon1.fa simon2.fa h1.fa h2.fa > pggb.fasta

# ART -read simulation

singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
art_illumina --seqSys HS25 --in simulated2hap.fa --paired --len 150 --fcov 10 --mflen 400 --sdev 50 --out simulated2hap

singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
art_illumina --seqSys HS25 --in simon2hap.fa --paired --len 150 --fcov 10 --mflen 400 --sdev 50 --out simon2hap


# run pggb
fasta=pggb.fasta
haplotypes=$(cat $fasta | grep "^>" | wc -l)

#wfmash
param_s=100000 # segment size, this should only be this small because we have a small graph, for full chromosomes set to 100000
param_p=95 # percent identity in the wfmash step, including variants. This should not be so strict for this small example
param_n=$haplotypes  #Ideally, you should set this to equal the number of haplotypes in the pangenome.
param_K=16 # Kmer size for aligning
param_i="$(basename $fasta)" 
param_l=300000 # minimum block length filter for mapping. (segments are merged to blocks, default 3*segment-length)


#seqwish
param_k=311 #filter exact matches below this length [default: 29]

#smoothxg
param_H=$haplotypes # number of haplotypes, if different than that set with -n
param_G="13117,13219" # target sequence length for POA, first pass = N, second pass = M [default: 13117,13219]


#deconstruct
#param_V=ssa05:sample.list  
#OBSOBS the reference for the vcf here
#specify a set of VCFs to produce with SPEC = [REF:SAMPLE_LIST_FILE] the paths matching ^REF are used as a reference
param_V='simon:#'

pggbout=pggb.out


####
# Running pggb

echo "RUN PGGB"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $pggbout -G $param_G -V $param_V -L -v -l $param_l


#chop graph
odgi=$(ls $pggbout/*.smooth.og)
fastabase=$(basename "$fasta")

echo "Chop graph"
singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi chop -c 1024 -i $odgi -o "$fastabase"-chop.og

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi view -i "$fastabase"-chop.og --to-gfa > "$fastabase"-chop.gfa

#run giraffe + vg call

gfa="$fastabase"-chop.gfa
refheader="simon#1#contig"

for name in simulated2hap simon2hap
do
    echo "running genotyping for " "$name"
    fq1="$name"1.fq
    fq2="$name"2.fq

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg gbwt -g "$name".giraffe.gbz --gbz-format -G "$gfa" --path-regex "(.*)#(.*)#(.*)" --path-fields _SHC --max-node 0
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg snarls -T "$name".giraffe.gbz > "$name".snarls
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg index -s "$name".snarls -j "$name".dist -p -b $TMPDIR/$USER "$name".giraffe.gbz
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg minimizer -o "$name".min -d "$name".dist "$name".giraffe.gbz

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
    --fragment-mean 300 --fragment-stdev 68 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > $name.gam

    # Print mapping stats
    #####################

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a "$name".gam > "$name".stats

    # Variant calling
    ##################

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
    -x "$gfa" -g $name.gam -o "$name".pack -t $SLURM_CPUS_ON_NODE 


    # then vg call

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
    -a -A --pack "$name".pack -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa" > "$name"_simon.vcf
done
echo "FINISHED giraffe + vg call"


# running pangenie

deconstructed_vcf=$(ls "$pggbout"/*simon.vcf)

###############################################################
# Remove all nested variants from deconstruct-vcf i.e. LV > 0

echo "Filter vcf"

# zip vcf
singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip "$deconstructed_vcf"
# Index new vcf for resolving nested genotypes
singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf "$deconstructed_vcf".gz

singularity exec $homedir/tools/rust.sif $homedir/tools/vcfbub -i "$deconstructed_vcf".gz --max-level 0 > filtered.vcf  


####################################################
# cat fastq files. Pangenie is k-mer based so will not use the readpair information.
# and only allowes for one read input in either fastq or fasta format.

echo "cat fastqs"
fq1=simulated2hap1.fq
fq2=simulated2hap2.fq

cat $fq1 $fq2 > reads.fq

#######################
# Run pangenie 


echo "Run pangenie"

$homedir/tools/pangenie/build/src/PanGenie -i reads.fq -r simon1.fa -v filtered.vcf -t $SLURM_CPUS_ON_NODE -j $SLURM_CPUS_ON_NODE -o pangenie

##########################
# resolve nested genotypes

echo "Resolve nested genotypes"

# zip vcf so we can index it
#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip pangenie_genotyping.vcf 
# Index new vcf for resolving nested genotypes
#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf pangenie_genotyping.vcf.gz


#$homedir/tools/resolve-nested-genotypes "$deconstructed_vcf".gz pangenie_genotyping.vcf.gz > resolved_genotypes.vcf




cp pggb.fasta "$pggbout"/*chop.gfa reads.fq simon1.fa *.stats *.vcf "$pggbout"/*.vcf* "$SCRATCHout"

cd ..

rm -r "$TMPout"

echo "FINISHED"
