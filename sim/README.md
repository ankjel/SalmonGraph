# Pipeline

In this folder I have gathered scripts used for inserting SVs into an assembly, read simulation, graph construction and genotyping. The assembly with SVs inserted into it and the simulated reads will together be our test data set. The graph contruction is performed with the original assembly and the one with SVs inserted. The simulated reads are mapped to this graph with giraffe and the resulting gam is genotyped using vg call.


* vcf_preprocessing.R

* visor_run.sh

* art_run.sh

* pggb_run.sh

* genotyping_run.sh

* compare_variants.R - variants inserted vs. found in pggb graph

* metrics.R 

* genotypes.R

