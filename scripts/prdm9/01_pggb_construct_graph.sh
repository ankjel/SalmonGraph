#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb  # sensible name for the job
#SBATCH --mem=3G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-pggb-%j.out
#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this



echo "START"
date

#INPUT : full path to one fasta file
# NB! if you include more graphics with for instance --multiqc, --layout and --stats you should ask for more memory 
# NB2! if you are running this script with a full chromosome input you should ask for a lot more memory


######
## Parameters

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
param_G="13117,13219" # target sequence length for POA, first pass = N, second pass = M [default: 13117,13219]
param_P="1,4,6,2,26,1"

#deconstruct
#param_V=ssa05:sample.list  
#OBSOBS the reference for the vcf here
#specify a set of VCFs to produce with SPEC = [REF:SAMPLE_LIST_FILE] the paths matching ^REF are used as a reference
param_V='Simon2:#'


SCRATCHout=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-$param_i-G$param_G-k$param_k.out

out=pggb-$(basename $fasta).out

##########
# Copy input files to tmpdir

mkdir -p $TMPDIR/$USER/$SLURM_JOBID #Not all nodes my TMP dir exist

cd $TMPDIR/$USER/$SLURM_JOBID

cp $fasta .

####
# Running pggb

echo "RUN PGGB"

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif pggb -i $param_i -s $param_s -p $param_p -K $param_K \
-n $param_n -t $SLURM_CPUS_ON_NODE -k $param_k -o $out -G $param_G -V $param_V -L -v -l $param_l -P $param_P -H $param_H


echo "CHOP GFA"

# vg does not like nodes >1024 bp. We chop the graph ourselves to avoid coordinate inconsistency between mapped file and graph.

odgi=$(ls $out/*.smooth.og)
fastabase=$(basename "$fasta")

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi chop -c 1024 -i $odgi -o "$fastabase"-chop.og

singularity exec /mnt/users/ankjelst/tools/pggb-v020.sif odgi view -i "$fastabase"-chop.og --to-gfa > "$fastabase"-chop.gfa


echo "MOVE FILES TO SCRATCH"

mkdir -p $SCRATCHout

mv -v $out/* "$fastabase"-chop.gfa $SCRATCHout

cd ..

echo "DELETE TMP-FILES"

ls $TMPDIR/$USER

rm -r $TMPDIR/$USER/$SLURM_JOBID

echo "AFTER deleting"

ls $TMPDIR/$USER/

echo "FINISHED"

date
