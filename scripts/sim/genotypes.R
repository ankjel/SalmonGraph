source("metrics.R")


path.true <- "/mnt/SCRATCH/ankjelst/data/ssa22variants.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))


path.genotype <- "/mnt/SCRATCH/ankjelst/data/giraffe/genotypes.vcf"

vcf <- read_delim(path.genotype, delim = "\t", comment="#", col_names = c('CHROM', 'POS', 'ID', 'REF', 'ALT','QUAL',  'FILTER', 'INFO', 'FORMAT')) %>% 
  mutate(START = POS, END = POS + str_length(REF))


tol <- 20


precision(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
recall(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)


false.negative(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
false.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
true.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

fn.df <- false.negative.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
fp.df <- false.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
tp.df <- true.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

nrow(fp.df) + nrow(tp.df)




