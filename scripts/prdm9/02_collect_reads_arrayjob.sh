#!/bin/bash
#SBATCH --array=1-3%10 # run 50 jobs, max 10 at a time --array=1-50%10
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem=10G
#SBATCH --partition=smallmem
#SBATCH --job-name=samtools
#SBATCH --output=logs/log-samtools-%j-%a.out

set -o errexit # exit on errors
set -o nounset # treat unset variables as errors

# directories where we find crams and gfa to map reads to.
cramdir=/mnt/SCRATCH/ankjelst/data/crams

########## For graph with all assemblies
#refheader="Simon#1#sig"
#pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_zf_sig_original.fasta-G13117,13219-k84.out
#fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_zf_sig_original.fasta 


########## For graph with only maxine and Simon
#refheader="Simon#1#sig" # choose one haplotype to be the reference when calling genotypes. This must be a path in the gfa.
#pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_zf_sig_simmax.fasta-G13117,13219-k84.out
#fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_zf_sig_simmax.fasta # the fasta which we made the graph with


####### This is for extension
#refheader="Simon#1#sige" # choose one haplotype to be the reference when calling genotypes. This must be a path in the gfa.
#pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf-sig_Simon_10kb_extension_v1.fasta-G13117,13219-k84.out
#fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf-sig_Simon_10kb_extension_v1.fasta # the fasta which we made the graph with


########## For graph with only maxine and Simon AND extensions
#refheader="Simon#1#sige" # choose one haplotype to be the reference when calling genotypes. This must be a path in the gfa.
#pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf-sig_Simon_10kb_extension_simmax.fasta-G13117,13219-k84.out
#fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf-sig_Simon_10kb_extension_simmax.fasta # the fasta which we made the graph with

########## For graph with only klopp and Simon AND extensions
#refheader="Simon#1#sige" # choose one haplotype to be the reference when calling genotypes. This must be a path in the gfa.
#pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf-sig_Simon_10kb_extension_klopp.fasta-G13117,13219-k84.out
#fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf-sig_Simon_10kb_extension_klopp.fasta # the fasta which we made the graph wit

########## For graph with only arnold and Simon AND extensions
#refheader="Simon#1#sige" # choose one haplotype to be the reference when calling genotypes. This must be a path in the gfa.
#pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf-sig_Simon_10kb_extension_arnold.fasta-G13117,13219-k84.out
#fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf-sig_Simon_10kb_extension_arnold.fasta # the fasta which we made the graph wit

########## For graph with extension and with all haplotypes except Simon#2
refheader="Simon#1#sige" # choose one haplotype to be the reference when calling genotypes. This must be a path in the gfa.
pggb_out=/mnt/SCRATCH/ankjelst/data/prdm9/pggb-PRDM9a_znf-sig_Simon_10kb_extension_nos2.fasta-G13117,13219-k84.out
fasta=/mnt/SCRATCH/ankjelst/data/prdm9/PRDM9a_znf-sig_Simon_10kb_extension_nos2.fasta # the fasta which we made the graph wit



gfa=$(ls "$pggb_out"/*chop.gfa)

FILE=$(ls -1 "$cramdir"/*.cram | awk 'FNR=='"$SLURM_ARRAY_TASK_ID"'')  # print one cram file per line, find the filename of the jobnumber
name=$(basename "$FILE" .cram)

#output directory
outdir="$SCRATCH"/prdm9_genotyping.out/$(basename "$fasta")/"$name"
mkdir -p "$outdir"



#tmpdir
tmpdir="$TMPDIR"/"$USER"/job-"$SLURM_ARRAY_TASK_ID" # one tmpdir for each 
mkdir -p "$tmpdir"
cd "$tmpdir"

echo "Copy files"
# copy cram to tmpdir
INDEX="$FILE".crai
cp "$FILE" "$INDEX" . #copy cram and crai file to tmp dir
# this is best practice as reading and writing is much faster to workdir

cram=$(basename "$FILE")

echo "collect reads"
#/mnt/users/ankjelst/MasterScripts/scripts/prdm9/collect_reads.sh "$FILE" "$outdir"
/mnt/users/ankjelst/MasterScripts/scripts/prdm9/collect_more_reads.sh "$cram" "$outdir"

echo "genotype"

fq1=$(ls *_R1.fq)
fq2=$(ls *_R2.fq)

/mnt/users/ankjelst/MasterScripts/scripts/prdm9/genotyping-odgi.sh "$name" "$gfa" "$refheader" "$fq1" "$fq2"

#/mnt/users/ankjelst/MasterScripts/scripts/prdm9/pangenie.sh "$pggb_out" "$fasta"

mv *.fq *.vcf *.gam "$outdir"

cd ..

rm -r "$tmpdir"
