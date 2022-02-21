#!/bin/bash

#BATCH --nodes=1                  
#SBATCH --ntasks=16                  # The number of threads reserved
#SBATCH --mem=99G                     # The amount of memory reserved
#SBATCH --partition=smallmem         
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=pangenie       # Sensible name for the job
#SBATCH --output=log-pangenie-%j.log  # Logfile output here

homedir=/mnt/users/ankjelst
outdir=/mnt/SCRATCH/ankjelst/data/pangenie

# VCF has to be phased, multisample and with non-overlapping variant.
# Last part we handle with filtering out nested variants later in the script
# The nested variants genotype are imputed as a last step in this script
# pggb will 

#deconstructed_vcf=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.ssa22.vcf

# vcf must be gziped for vcfbub
deconstructed_vcf=/mnt/SCRATCH/ankjelst/data/pangenie/pggb-v020-G5G-k311.out/inputPangenie.fasta.2dd9516.4030258.8053ffa.smooth.simon.vcf.gz

#gfa=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.gfa
gfa=/mnt/SCRATCH/ankjelst/data/pangenie/pggb-v020-G5G-k311.out/inputPangenie.fasta.2dd9516.4030258.8053ffa.smooth.gfa
fasta=/mnt/SCRATCH/ankjelst/data/pangenie/simon22Pangenie.fasta

filtered_vcf=/mnt/SCRATCH/ankjelst/data/deconstructed_filtered.vcf


fq1=/mnt/SCRATCH/ankjelst/data/art/sim_r_sim_SV1.fq
fq2=/mnt/SCRATCH/ankjelst/data/art/sim_r_sim_SV2.fq

reads=/mnt/SCRATCH/ankjelst/data/allreads.fq

if [ ! -d $outdir ]
then
mkdir $outdir
fi

cd $outdir


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
