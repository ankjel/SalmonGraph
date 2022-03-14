source("metrics.R")


path.true <- "/mnt/SCRATCH/ankjelst/data/ssa22variants.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))



vcf <- read_delim(path.genotype, delim = "\t", comment="##") %>% 
mutate(START = POS, END = POS + str_length(REF)) %>% 
  filter(!(str_length(REF) == 1 & str_length(ALT) == 1))

tol <- 60


pres <- precision(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
rec <- recall(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)


false.negative(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
false.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
true.positive(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

fn.df <- false.negative.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
fp.df <- false.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)
tp.df <- true.positive.df(true.vcf = vcf.true, predicted.vcf = vcf, tolerance = tol)

nrow(fp.df) + nrow(tp.df)


tp.genotypes <- vcf[!(vcf$POS %in% fp.df$POS),] %>% 
  mutate(genotype = str_split(simulated2hap, pattern = ":", simplify = T)[,1])

F1 <- 2*(rec*pres)/(rec+pres)


cat("tol: ", tol, "\n", "FP:", nrow(fp.df), "\n", "FN:", nrow(fn.df))

true<- vcf.true %>% select(START) %>% 
  mutate(df="true") 

fn <- fn.df %>% select(START) %>% 
  mutate(df="fn")

fp <- fp.df %>% select(POS) %>% 
  mutate(START=POS, df="fp", .keep="none")

rbind(true, fn, fp) %>% 
  ggplot(aes(x=START, color=df)) + geom_freqpoly(binwidth=1000000) + facet_grid(vars(df), scales = "free") + labs(title="SV distribution in simulated ssa22", x="Start position")



test <- tp.genotypes %>% filter(!(genotype %in% c("0/1", "1/0")))



############ 
#Pangenie



path.pangenie <- "/mnt/SCRATCH/ankjelst/sim_pipe/slurm-14275427/pangenie_genotyping.vcf"


pangenie <- read_delim(path.pangenie, delim = "\t", comment="##") %>% 
  mutate(START = POS, END = POS + str_length(REF)) %>% 
  filter(!(str_length(REF) == 1 & str_length(ALT) == 1))




tp.pg <- true.positive.df(true.vcf = vcf.true, predicted.vcf = pangenie, tolerance = tol)
fp.pg <- false.positive.df(true.vcf = vcf.true, predicted.vcf = pangenie, tolerance = tol)

pangenie[!(pangenie$POS %in% fp.pg$POS),] %>% 
  mutate(genotype = str_split(sample, pattern = ":", simplify = T)[,1])%>% 
  filter(!(genotype %in% c("0/1", "1/0"))) -> pangenie_res


