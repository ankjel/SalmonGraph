
library(tidyverse)



source("metrics.R")

# I will use functions defined in the script sourced above

##################
# load data

path.vcf <- "/mnt/SCRATCH/ankjelst/sim_pipe/pggb/chop-deconstruct-pggb.fasta.vcf.gz"

vcf <- read_delim(path.vcf, delim = "\t", comment="##") %>% rename("CHROM" = `#CHROM`)
path.true <- "/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))

vcf <- vcf %>% mutate(START = POS, END = POS + str_length(REF))



###########################
# Find precision and recall
# This tells us how many of the SVs we inserted into chromosome 22 was detected in the graph

tol <- 60


precision(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
recall(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)


false.negative(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
false.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
true.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

fn.df <- false.negative.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
fp.df <- false.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
tp.df <- true.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)




#####################
# divide into del and ins

vcf %>% mutate(type = ifelse(ALT > REF, "insertion", "deletion")) -> vcf

ins <- filter(vcf, type == "insertion")
del <- filter(vcf, type == "deletion")

true.ins <- filter(vcf.true, TYPE == "insertion")
true.del <- filter(vcf.true, TYPE == "deletion")

tol = 20
rbind(tibble(region = "ssa22", type = "del", precision = precision(true.del, del, tol), recall = recall(true.del, del, tol)),
tibble(region = "ssa22", type = "ins", precision = precision(true.ins, ins, tol), recall = recall(true.ins, ins, tol))) -> results

results <- rbind(results, tibble(region = "ssa22", type = "all", precision = precision(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol),
recall = recall(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)))

precision(true.del, del, tol)
recall(true.del, del, tol)


ssa22.14.24 <- filter(vcf, POS <= 24000000)
ssa22.52.62 <- filter(vcf, POS > 24000000)

true.14.24 <- filter(vcf.true, START <= 24000000)
true.52.62 <- filter(vcf.true, START > 24000000)

results <- rbind(results, tibble(region = "ssa22:14-24", type = "all", precision = precision(true.vcf = true.14.24, predicted.vcf = ssa22.14.24, tolerance = tol),
                                 recall = recall(true.vcf = true.14.24, predicted.vcf = ssa22.14.24, tolerance = tol)))

results <- rbind(results, tibble(region = "ssa22:52-62", type = "all", precision = precision(true.vcf = true.52.62, predicted.vcf = ssa22.52.62, tolerance = tol),
                                 recall = recall(true.vcf = true.52.62, predicted.vcf = ssa22.52.62, tolerance = tol)))


results %>% 
  mutate(F1 = 2*precision*recall/(precision + recall))

