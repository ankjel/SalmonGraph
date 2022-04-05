source("/mnt/users/ankjelst/MasterScripts/scripts/rscripts/metrics.R")


##################
# load data

data.dir <- "/mnt/SCRATCH/ankjelst/sim_pipe/pggb/paramtest/"

path.true <- "/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed"

true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))

tol <- 60

for (file in list.files(data.dir, pattern = "G.*.vcf")){
  
  vcf <- read_delim(str_c(data.dir, file), delim = "\t", comment="##") %>% 
    rename("CHROM" = `#CHROM`)%>% 
    mutate(START = POS, END = POS + str_length(REF))
  pre <- precision(true.vcf = true, predicted.vcf = vcf, tolerance = tol)
  rec <- recall(true.vcf = true, predicted.vcf = vcf, tolerance = tol)
  f1 <-2*pre*rec/(pre + rec)
  
  if (!exists("G.tbl")){
    G.tbl <- tibble(file = file, f1 = f1)
  }else{
    G.tbl <- add_row(G.tbl, file = file, f1 = f1 )
  }
}


for (file in list.files(data.dir, pattern = "S.*.vcf")){
  
  vcf <- read_delim(str_c(data.dir, file), delim = "\t", comment="##") %>% 
    rename("CHROM" = `#CHROM`)%>% 
    mutate(START = POS, END = POS + str_length(REF))
  pre <- precision(true.vcf = true, predicted.vcf = vcf, tolerance = tol)
  rec <- recall(true.vcf = true, predicted.vcf = vcf, tolerance = tol)
  f1 <-2*pre*rec/(pre + rec)
  
  if (!exists("S.tbl")){
    S.tbl <- tibble(file = file, f1 = f1)
  }else{
    S.tbl <- add_row(S.tbl, file = file, f1 = f1 )
  }
}



for (file in list.files(data.dir, pattern = "runtime")){
  mytbl <- read_tsv(str_c(data.dir, file)) %>% 
    pivot_longer(1, names_to = "param", values_to = "param.value")
  if (!exists("time.tbl")){
    time.tbl <- mytbl
    
  }else{
    time.tbl <- rbind(time.tbl, mytbl)
  }}


  
