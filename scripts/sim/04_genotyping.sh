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
sample="$SCRATCHout"/pggb/h1-2hap.fa
jobout="$SCRATCHout"/"$SLURM_JOBID"-"$depth"

image=/mnt/
mkdir -p $jobout


name=$(basename -s .fa $sample)-$depth
singularity exec /cvmfs/singularity.galaxyproject.org/a/r/art:2016.06.05--he1d7d6f_6 \
art_illumina --seqSys HS25 -sam --in "$sample" --paired --len 150 --fcov "$depth" --mflen 400 --sdev 50 --out "$name"


#run giraffe + vg call

gfa="$SCRATCHout"/pggb/pggb.fasta.gz-chop.gfa
refheader="ref#1#ssa22"

# inspiration of finding time and memory: https://github.com/vgteam/giraffe-sv-paper/blob/805dcd95d24d2b320fdf253b6ee6a35a3b60066f/scripts/mapping/giraffe_speed.sh



name=$(basename -s .fa $sample)-$depth
echo "running genotyping for " "$name"
fq1="$name"1.fq
fq2="$name"2.fq

echo "gbwt"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg gbwt -g "$name".giraffe.gbz --gbz-format -G "$gfa" --path-regex '(.*)#(.*)#(.*)' --path-fields _SHC --max-node 0" 2> gbwt.txt

echo "snarls"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg snarls -T "$name".giraffe.gbz" > "$name".snarls 2> snarls.txt

echo "index"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg index -s "$name".snarls -j "$name".dist -p -b $TMPDIR/$USER "$name".giraffe.gbz" 2> index.txt

echo "minimizer"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg minimizer -o "$name".min -d "$name".dist "$name".giraffe.gbz" 2> minimizer.txt

echo "giraffe"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg giraffe -Z "$name".giraffe.gbz -m "$name".min -d "$name".dist -f "$fq1" -f "$fq2" -p --threads $SLURM_CPUS_ON_NODE" > "$name".gam 2> giraffe.txt



# Print mapping stats
#####################
echo "stats"
singularity exec /mnt/users/ankjelst/tools/vg_v1.38.0.sif vg stats -a "$name".gam > "$name".stats


# Variant calling
##################
echo "pack"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg pack -x "$gfa" -g "$name".gam -o "$name".pack -t $SLURM_CPUS_ON_NODE" 2> pack.txt



# then vg call
echo "call"
singularity exec "$homedir"/tools/vg_v1.38.0.sif "$homedir"/tools/time -v bash -c "vg call \
-a -A --pack "$name".pack -t $SLURM_CPUS_ON_NODE --ref-path $refheader --sample $name "$gfa"" > "$name".vcf 2> call.txt



echo "FINISHED giraffe + vg call"







# running pangenie

deconstructed_vcf="$SCRATCHout"/pggb/chop-deconstruct-pggb.fasta.gz.vcf.gz

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

$homedir/tools/time -v bash -c "$homedir/tools/pangenie/build/src/PanGenie -i reads.fq -r $pangenieref -v filtered.vcf -t $SLURM_CPUS_ON_NODE -j $SLURM_CPUS_ON_NODE -o pangenie-"$depth" -s $name"  2> pangenie.txt

echo "done pangenie"

cp pangenie-"$depth"_genotyping.vcf "$SCRATCHout"/h1_pangenie
##########################
# resolve nested genotypes

echo "Resolve nested genotypes"

# zip vcf so we can index it
#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 bgzip pangenie_genotyping.vcf 
# Index new vcf for resolving nested genotypes
#singularity exec /cvmfs/singularity.galaxyproject.org/s/a/samtools\:1.14--hb421002_0 tabix -p vcf pangenie_genotyping.vcf.gz


#$homedir/tools/resolve-nested-genotypes "$deconstructed_vcf".gz pangenie_genotyping.vcf.gz > resolved_genotypes.vcf

echo -e "tool\tclock_time\tmemory(kbytes)\n" > genotype"$depth"_time.txt

for file in gbwt.txt snarls.txt index.txt minimizer.txt giraffe.txt pack.txt call.txt pangenie.txt
do
    CLOCK_TIME="$(cat $file | grep "Elapsed (wall clock) time" | sed 's/.*\ \([0-9,:]*\)/\1/g')"
    MEMORY="$(cat $file | grep "Maximum resident set" | sed 's/Maximum\ resident\ set\ size\ (kbytes):\ \([0-9]*\)/\1/g')"

    tool=$(basename "$file" ".txt")
    echo -e ""$tool"\t"$CLOCK_TIME"\t"$MEMORY"\n" >> genotype"$depth"_time.txt
done

cp "$name".vcf "$SCRATCHout"/h1


cp *.stats *.vcf *.vcf* genotype"$depth"_time.txt "$jobout"

cd ..

rm -r "$TMPout"

echo "FINISHED"