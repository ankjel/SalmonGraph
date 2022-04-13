source("/mnt/users/ankjelst/MasterScripts/scripts/rscripts/metrics.R")



path.true <- "/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))

vcf.path <- "/mnt/SCRATCH/ankjelst/sim_pipe/h1"

vcf.setfrml <- "/mnt/SCRATCH/ankjelst/sim_pipe/frm400"


i <- 1

for (f in list.files(vcf.path)){
  new.vcf <- read_delim(str_c(vcf.path, "/", f), delim = "\t", comment="##") %>% 
    mutate(TYPE=ifelse(REF > ALT, "deletion", "insertion")) 
  if (i == 1){
    vcf <- new.vcf
  }else if (sum(vcf$ID == new.vcf$ID)==nrow(vcf)){
    vcf <- cbind(vcf, new.vcf[,10])
  }
  i <- i+1
}

###########
#Set fragment length

i <- 1

for (f in list.files(vcf.setfrml)){
  new.vcf <- read_delim(str_c(vcf.setfrml, "/", f), delim = "\t", comment="##") %>% 
    mutate(TYPE=ifelse(REF > ALT, "deletion", "insertion")) 
  print(colnames(new.vcf))
  if (i == 1){
    vcf.frgml <- new.vcf
  }else if (sum(vcf$ID == new.vcf$ID)==nrow(vcf)){
    vcf.frgml <- cbind(vcf, new.vcf[,10])
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


pggb.variants.path <- "/mnt/SCRATCH/ankjelst/sim_pipe/pggb/chop-deconstruct-pggb.fasta.vcf.gz"

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



vcf.frgml[!(vcf.frgml$POS %in% fp.df$POS),1:15] %>% 
  select(starts_with("h1")) %>% 
  mutate(across(.fns=~str_split(.x, pattern = ":", simplify = T)[,1])) %>% 
  pivot_longer(1:4, names_to = "depth", values_to = "genotype") %>% 
  mutate(depth = str_extract(depth, pattern = "[0-9]{1,2}$"),
         true = genotype %in% c("1/0", "0/1")) %>% 
  group_by(depth) %>% 
  summarise(precision = sum(true)/n()) %>% 
  mutate(tool = "vg")-> vg.frml



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


vcf.frgml[!(vcf.frgml$POS %in% fp.df$POS),1:15] %>% 
  select(starts_with("h1"), TYPE) %>% 
  mutate(across(-TYPE, .fns=~str_split(.x, pattern = ":", simplify = T)[,1])) %>% 
  pivot_longer(-TYPE, names_to = "depth", values_to = "genotype") %>% 
  mutate(depth = str_extract(depth, pattern = "[0-9]{1,2}$"),
         true = genotype %in% c("1/0", "0/1")) %>% 
  group_by(depth, TYPE) %>% 
  summarise(precision = sum(true)/n()) %>% 
  mutate(tool = "vg")-> vg.fgml

