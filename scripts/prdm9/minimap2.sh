#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=pggb-minimap  # sensible name for the job
#SBATCH --mem=40G                 # Default memory per CPU is 3GB.
#SBATCH --output=log-minimap-pggb-%j.out

#SBATCH --constraint="avx2" # IMPOTATANT!!! PGGB jobs will fail without this

# In this script I align assemblies in fasta format before 

echo "start"
date

cd $TMPDIR/$USER

mkdir jobdir

cd jobdir

echo "copy files to tmpdir"

cp /mnt/SCRATCH/ankjelst/svsim/{simonsimSV.fasta.gz,simon_ssa22_14to24M.fasta.gz,simon_cat_simsv.fasta} .

echo "running minimap2"

singularity exec /cvmfs/singularity.galaxyproject.org/m/i/minimap2:2.22--h5bf99c6_0 \
minimap2 -xasm5 -c -t $SLURM_CPUS_ON_NODE simon_ssa22_14to24M.fasta.gz simonsimSV.fasta.gz > minimap.paf


singularity exec /mnt/users/ankjelst/tools/pggb.sif \
seqwish -s simon_cat_simsv.fasta -b minimap_seqs -p minimap.paf -g minimap_seqwish.gfa -k 311 -B 10000000 -t $SLURM_CPUS_ON_NODE

singularity exec /mnt/users/ankjelst/tools/pggb.sif \
smoothxg -g minimap_seqwish.gfa -o minimap_seqwish_smooth.gfa -I 0.7 -t $SLURM_CPUS_ON_NODE


echo "vg deconstruct for vcf"


singularity exec /cvmfs/singularity.galaxyproject.org/v/g/vg:1.35.0--h9ee0642_0 \
vg snarls minimap_seqwish_smooth.gfa -t $SLURM_CPUS_ON_NODE  > graph.snarls

singularity exec /cvmfs/singularity.galaxyproject.org/v/g/vg:1.35.0--h9ee0642_0 \
vg deconstruct -p "ssa22:14000000-24000000"  minimap_seqwish_smooth.gfa -t $SLURM_CPUS_ON_NODE -r graph.snarls -e > minimap-pggb.vcf


echo "copy files back to scratch"

cp minimap-pggb.vcf $SCRATCH

cd .. 

echo "remove files from tmpdir"

rm -rf jobdir # remove all temporary files 

echo "finished"

date 

