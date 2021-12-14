#!/bin/bash

#BATCH --nodes=1                  
#SBATCH --ntasks=8                  # The number of threads reserved
#SBATCH --mem=99G                     # The amount of memory reserved
#SBATCH --partition=smallmem         
#SBATCH --time=24:60:60              # Runs for maximum this time
#SBATCH --job-name=pangenie       # Sensible name for the job
#SBATCH --output=log-pangenie-%j.log  # Logfile output here

homedir=/mnt/users/ankjelst
outdir=/mnt/SCRATCH/ankjelst/data/pangenie


deconstructed_vcf=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.ssa22.vcf
gfa=/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.gfa
fasta=/mnt/SCRATCH/ankjelst/data/simon22.fasta

genotyped_vcf=/mnt/SCRATCH/ankjelst/data/
reads=

if [ ! -d $outdir ]
then
mkdir $outdir
fi

cd $outdir


###############################################################
# Remove all nested variants from deconstruct-vcf i.e. LV > 0


####################################################
# cat fastq files. Pangenie is k-mer based so will not use the readpair information.
# and only allowes for one read input in either fastq or fasta format.



#######################
# Run pangenie 

$homedir/tools/pangenie/build/src/PanGenie -i $reads -r $fasta -v $vcf -t $SLURM_CPUS_ON_NODE -j $SLURM_CPUS_ON_NODE



##########################
# resolve nested genotypes


singularity exec $homedir/tools/rust.sif $homedir/tools/resolve-nested-genotypes $deconstructed_vcf $genotyped_vcf > resolved_genotypes.vcf
