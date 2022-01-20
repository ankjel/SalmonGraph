# PRDM9

I will apply the methods I have tested on simulated SVs on the PRDM9 zn-finger repeat array. The goal is to genotype a population of 500 with short-read data. We are mainly interested in repeat number difference. 

Ideally, we would have used full chromosomes as input for graph construction. This is not possible as our assemblies are not haplotype resolved, but the zn-finger repeat array is manually phased.

```bash
sbatch 01_pggb_construct_graph.sh filename.fasta

sbatch 02_collect_reads.sh "name.cram name2.cram"

sbatch 03_genotyping.sh filename.fasta /pggb/out/dir/ /path/and/basename/fastq

```
