# PRDM9

Graph based genotyping of the variable zinc finger-array with short read data. 

**01_pggb.sh - Construct graph with PGGB**
The graph is constructed with the full Atlantic salmon genome and the phased  PRDM9 zinc finger sequences as input. 
Input sequences are based on long-read data.
Variants are called from the graph with `vg deconstruct`

**02_mapping.sh - Graph based genotyping with real reads.**
Short reads are from the same individuals as the sequences used as input to construct the graph. 
`vg giraffe` is used for graph mapping.
`vg call`is used for genotype calling. 
The resulting genotype calls are compared to the long read based genotypes.

```bash
sbatch 01_pggb.sh

sbatch 02_mapping.sh

```
