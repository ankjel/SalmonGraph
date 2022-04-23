#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --nodes=1                # Use 1 node
#SBATCH --job-name=visor  # sensible name for the job
#SBATCH --mem=10G 
#SBATCH --partition=smallmem
#SBATCH --output=log-visor-%j.log

date
set -o errexit # exit on errors
set -o nounset # treat unset variables as errors



SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe/pggb
homedir=/mnt/users/ankjelst
outhack=sim
ref=/mnt/SCRATCH/ankjelst/data/simon22.fasta
bed=/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed


mkdir -p "$SCRATCHout"
TMPout=$TMPDIR/$USER/$SLURM_JOBID
mkdir -p $TMPout
cd "$TMPout"


############
# Insert SVs into sequence

singularity exec $homedir/tools/visor.sif VISOR hack -b "$bed" -g $ref -o $outhack



sed 's/>.*/>ref#1#ssa22/' "$ref"> ref1.fa
sed 's/>.*/>ref#2#ssa22/' "$ref"> ref2.fa
cat ref1.fa ref2.fa > ref-2hap.fa


sed 's/>.*/>simulated#1#ssa22/' $ref > h1-1.fa
sed 's/>.*/>simulated#2#ssa22/' $outhack/h1.fa > h1-2.fa
cat h1-1.fa h1-2.fa > h1-2hap.fa

cat ref1.fa h1-2.fa > pggb.fasta


singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip -@ "$SLURM_CPUS_ON_NODE" pggb.fasta

singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 samtools faidx pggb.fasta.gz

cp *.fa *.fasta.gz* "$SCRATCHout" 

cd ..
rm -r $TMPout

date