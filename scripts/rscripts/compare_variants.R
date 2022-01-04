
library(tidyverse)



source("metrics.R")

# I will use functions defined in the script sourced above

##################
# load data

path.vcf <- "/mnt/SCRATCH/ankjelst/data/pangenie/pggb-v020-G5G-k311.out/inputPangenie.fasta.2dd9516.4030258.8053ffa.smooth.simon.vcf"

vcf <- read_delim(path.vcf, delim = "\t", comment="#", col_names = c('CHROM', 'POS', 'ID', 'REF', 'ALT','QUAL',  'FILTER', 'INFO', 'FORMAT'))

path.true <- "/mnt/SCRATCH/ankjelst/data/ssa22variants.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))

vcf <- vcf %>% mutate(START = POS, END = POS + str_length(REF))



###############
# Run functions

tol <- 20


precision(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
recall(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)


false.negative(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
false.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
true.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

false.negative.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
false.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
true.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

