
# Simulation of structural variants and reads

**01_sequencesim.sh - simulate data**

Inserting SVs into reference sequence of chromosome 22.  
<br/>
<br/>

**02A_paramtest-G.sh and 02B_paramtest-s.sh - running pggb with different -G and -s values**

Output will be a text file with output from `time` and a VCF with genotype calls for each parameter value.


**03_graphconstruction.sh - graph construction with PGGB**

Run PGGB to construct a graph used for genotyp


**04_genotyping.sh**

This arrayjob will simulate reads with five different depths based on the reference chromosome 22 and the simulated sequence, then do graph based genotyping.
The output is two VCF files, one for each genotyper, and a text file with `time` output.
