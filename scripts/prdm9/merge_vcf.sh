#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=vcfmerge  # sensible name for the job
#SBATCH --mem=1G 
#SBATCH --partition=smallmem
#SBATCH --output=log-vcfmerge-%j.log

date
set -o errexit # exit on errors
set -o nounset # treat unset variables as errors

vcf_dir=$1

cd $vcf_dir

module load module load BCFtools/1.11-GCC-10.2.0


bgzip $(ls *simon.vcf)

tabix -p vcf $(ls *simon.vcf.gz)

bcftools merge $(ls *simon.vcf.gz) > full vcf