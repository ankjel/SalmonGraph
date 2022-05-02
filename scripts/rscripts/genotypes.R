source("/mnt/users/ankjelst/MasterScripts/scripts/rscripts/metrics.R")

library(tidyverse)

path.true <- "/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))

vcf.path <- "/mnt/SCRATCH/ankjelst/sim_pipe/h1"



i <- 1

for (f in list.files(vcf.path, pattern = "*.vcf")){
  new.vcf <- read_delim(str_c(vcf.path, "/", f), delim = "\t", comment="##") %>% 
    mutate(TYPE=ifelse(REF > ALT, "deletion", "insertion")) 
  if (i == 1){
    vcf <- new.vcf
  }else if (sum(vcf$ID == new.vcf$ID)==nrow(vcf)){
    vcf <- cbind(vcf, new.vcf[,10])
  }
  i <- i+1
}






############ 
#Pangenie


vcf.path <- "/mnt/SCRATCH/ankjelst/sim_pipe/h1_pangenie"


i <- 1

for (f in list.files(vcf.path)){
  new.vcf <- read_delim(str_c(vcf.path, "/", f), delim = "\t", comment="##") %>% 
    mutate(TYPE=ifelse(REF > ALT, "deletion", "insertion")) 
  if (i == 1){
    vcf.pangenie <- new.vcf %>% rename()
  }else if (sum(vcf.pangenie$ID == new.vcf$ID)==nrow(vcf.pangenie)){
    vcf.pangenie <- cbind(vcf.pangenie, new.vcf[,10])
  }
  i <- i+1
}




##########
# Find False positives


pggb.variants.path <- "/mnt/SCRATCH/ankjelst/sim_pipe/pggb/chop-deconstruct-pggb.fasta.gz.vcf.gz"

pggb.variants <- read_delim(pggb.variants.path, delim = "\t", comment="##") %>% 
  rename("CHROM" = `#CHROM`) %>% mutate(START = POS, END = POS + str_length(REF))

tol <- 60
fp.df <- false.positive.df(true.vcf = vcf.true, predicted.vcf = pggb.variants, tolerance = tol)


# results


vcf.pangenie[!(vcf.pangenie$POS %in% fp.df$POS),] %>% 
  select(starts_with("h1")) %>% 
  mutate(across(.fns=~str_split(.x, pattern = ":", simplify = T)[,1])) %>% 
  pivot_longer(1:4, names_to = "depth", values_to = "genotype") %>% 
  mutate(depth = str_extract(depth, pattern = "[0-9]{1,2}$"),
         true = genotype %in% c("1/0", "0/1")) %>% 
  group_by(depth) %>% 
  summarise(precision = sum(true)/n()) %>% 
  mutate(tool = "pangenie") -> pg

vcf[!(vcf$POS %in% fp.df$POS),] %>% 
  select(starts_with("h1")) %>% 
  mutate(across(.fns=~str_split(.x, pattern = ":", simplify = T)[,1])) %>% 
  pivot_longer(1:4, names_to = "depth", values_to = "genotype") %>% 
  mutate(depth = str_extract(depth, pattern = "[0-9]{1,2}$"),
         true = genotype %in% c("1/0", "0/1")) %>% 
  group_by(depth) %>% 
  summarise(precision = sum(true)/n()) %>% 
  mutate(tool = "vg")-> vg





vcf.pangenie[!(vcf.pangenie$POS %in% fp.df$POS),] %>% 
  select(starts_with("h1"), TYPE) %>% 
  mutate(across(-TYPE, .fns=~str_split(.x, pattern = ":", simplify = T)[,1])) %>% 
  pivot_longer(-TYPE, names_to = "depth", values_to = "genotype") %>% 
  mutate(depth = str_extract(depth, pattern = "[0-9]{1,2}$"),
         true = genotype %in% c("1/0", "0/1")) %>% 
  group_by(depth, TYPE) %>% 
  summarise(precision = sum(true)/n()) %>% 
  mutate(tool = "pangenie") -> pg

vcf[!(vcf$POS %in% fp.df$POS),] %>% 
  select(starts_with("h1"), TYPE) %>% 
  mutate(across(-TYPE, .fns=~str_split(.x, pattern = ":", simplify = T)[,1])) %>% 
  pivot_longer(-TYPE, names_to = "depth", values_to = "genotype") %>% 
  mutate(depth = str_extract(depth, pattern = "[0-9]{1,2}$"),
         true = genotype %in% c("1/0", "0/1")) %>% 
  group_by(depth, TYPE) %>% 
  summarise(precision = sum(true)/n()) %>% 
  mutate(tool = "vg")-> vg



data.dir <- "/mnt/SCRATCH/ankjelst/sim_pipe/time/"

for (file in list.files(data.dir, pattern = "_time")){
  mytbl <- read_tsv(str_c(data.dir, file), col_types = cols(clock_time = col_character())) %>% 
    pivot_longer(1, names_to = "param", values_to = "param.value") %>%
    mutate(depth = str_extract(file, "[0-9]{1,2}"),
           format = str_count(clock_time, pattern=":"))  # Dealing with inconsistent time format in file %H:%M:%S or %M:%S

  if (!exists("time.tbl")){
    time.tbl <- mytbl
    
  }else{
    time.tbl <- rbind(time.tbl, mytbl)
  }}

# Dealing with inconsistent time format

time.tbl %>% 
  filter(format == 1) %>% 
  mutate(time = strptime(clock_time, format ="%M:%S")) -> m

time.tbl %>% 
  filter(format == 2) %>% 
  mutate(time = strptime(clock_time, format ="%H:%M:%S")) -> h

bind_rows(m,h) -> time.tbl


# using lubridate::hour and lubridate::minute

time.tbl %>% 
  mutate(minutes = lubridate::minute(time.tbl$time) + lubridate::minute(time) + lubridate::second(time)/60) -> time.tbl

