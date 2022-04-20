#!/bin/bash
#SBATCH --array=1-5 # 1-10%5 only run 5 at a time
#SBATCH --ntasks=8
#SBATCH --nodes=1
#SBATCH --mem=99G
#SBATCH --partition=smallmem  
#SBATCH --job-name=giraffe
#SBATCH --output=logs/log-genotyping-%j-%a.out

set -o errexit # exit on errors
set -o nounset # treat unset variables as errors

TMPout=$TMPDIR/$USER/$SLURM_JOBID
mkdir -p $TMPout
cd "$TMPout"

depth=$(echo 1 5 10 20 30 | cut -d " " -f "$SLURM_ARRAY_TASK_ID")
SCRATCHout=/mnt/SCRATCH/ankjelst/sim_pipe
homedir=/mnt/users/ankjelst
#samples=$(ls "$SCRATCHout"/pggb/*2hap.fa)
samples=""$SCRATCHout"/pggb/ref-2hap.fa "$SCRATCHout"/pggb/h1-2hap.fa"
jobout="$SCRATCHout"/"$SLURM_JOBID"-"$depth"

image=/mnt/
mkdir -p $jobout

for sample in $(echo "$samples")
do
# art read simulation
    name=$(basename -s .fa $sample)-$depth
    singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
    art_illumina --seqSys HS25 -sam --in "$sample" --paired --len 150 --fcov "$depth" --mflen 400 --sdev 50 --out "$name"

done

#run giraffe + vg call

gfa="$SCRATCHout"/pggb/pggb.fasta-chop.gfa
refheader="ref#1#ssa22"

# inspiration of finding time and memory: https://github.com/vgteam/giraffe-sv-paper/blob/805dcd95d24d2b320fdf253b6ee6a35a3b60066f/scripts/mapping/giraffe_speed.sh


for sample in $(echo "$samples")
do
    name=$(basename -s .fa $sample)-$depth
    echo "running genotyping for " "$name"
    fq1="$name"1.fq
    fq2="$name"2.fq

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg gbwt -g "$name".giraffe.gbz --gbz-format -G "$gfa" --path-regex "(.*)#(.*)#(.*)" --path-fields _SHC --max-node 0
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg snarls -T "$name".giraffe.gbz > "$name".snarls
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg index -s "$name".snarls -j "$name".dist -p -b $TMPDIR/$USER "$name".giraffe.gbz
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg minimizer -o "$name".min -d "$name".dist "$name".giraffe.gbz

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
    -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > "$name".gam

   
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg giraffe \
    --fragment-mean 400 --fragment-stdev 50 -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE > "$name"-frgm400.gam

    # Print mapping stats
    #####################

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a "$name".gam > "$name".stats
    
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a "$name"-frgm400.gam > "$name"-frgm400.stats

    # Variant calling
    ##################

    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
    -x "$gfa" -g "$name".gam -o "$name".pack -t $SLURM_CPUS_ON_NODE 
    
        singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg pack \
    -x "$gfa" -g "$name"-frgm400.gam -o "$name"-frgm400.pack -t $SLURM_CPUS_ON_NODE 



    # then vg call
    
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
    -a -A --pack "$name".pack -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa" > "$name".vcf
    
    cp "$name".vcf "$SCRATCHout"/h1
    
    singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg call \
    -a -A --pack "$name"-frgm400.pack -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa" > "$name"-frgm400.vcf
    cp "$name"-frgm400.vcf "$SCRATCHout"/frgm400
done
echo "FINISHED giraffe + vg call"




# running pangenie

deconstructed_vcf="$SCRATCHout"/pggb/chop-deconstruct-pggb.fasta.vcf.gz

###############################################################
# Remove all nested variants from deconstruct-vcf i.e. LV > 0

echo "Filter vcf"

singularity exec $homedir/tools/rust.sif $homedir/tools/vcfbub -i "$deconstructed_vcf" --max-level 0 > filtered.vcf  


####################################################
# cat fastq files. Pangenie is k-mer based so will not use the readpair information.
# and only allowes for one read input in either fastq or fasta format.
pangenieref="$SCRATCHout"/pggb/ref-2hap.fa
sample="$SCRATCHout"/pggb/h1-2hap.fa
name=$(basename -s .fa "$sample")-"$depth"
echo "cat fastqs"
fq1="$name"1.fq
fq2="$name"2.fq



cat $fq1 $fq2 > reads.fq

#######################
# Run pangenie 


echo "Run pangenie"

$homedir/tools/pangenie/build/src/PanGenie -i reads.fq -r "$pangenieref" -v filtered.vcf -t $SLURM_CPUS_ON_NODE -j $SLURM_CPUS_ON_NODE -o pangenie-"$depth" -s "$name"

cp pangenie-"$depth"_genotyping.vcf "$SCRATCHout"/h1_pangenie
##########################
# resolve nested genotypes

echo "Resolve nested genotypes"

# zip vcf so we can index it
#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip pangenie_genotyping.vcf 
# Index new vcf for resolving nested genotypes
#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf pangenie_genotyping.vcf.gz


#$homedir/tools/resolve-nested-genotypes "$deconstructed_vcf".gz pangenie_genotyping.vcf.gz > resolved_genotypes.vcf




cp *.stats *.vcf *.vcf* "$jobout"

cd ..

rm -r "$TMPout"

echo "FINISHED"
