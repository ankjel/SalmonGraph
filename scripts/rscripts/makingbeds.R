#!/bin/Rscript

args = commandArgs(trailingOnly=TRUE)


as.numeric(args[1]) -> nhaplotypes
as.numeric(args[2]) -> nins
as.numeric(args[3]) -> ninv
as.numeric(args[4]) -> ndel
args[5] -> region

library(tidyverse)

chromosome <- str_split(region, pattern=":", simplify = T)[,1]

position <- str_split(region, pattern=":", simplify = T)[,2]
start <- str_split(position, pattern="-", simplify = T)[,1]
end <- str_split(position, pattern="-", simplify = T)[,2]

cat("nins:", nins, "\nninv", ninv, "\nndel", ndel)




path.vcf <- "/mnt/users/ankjelst/eu_merged_iris_no_simon.vcf.gz"

info <- c("SVTYPE", NA, "END", "SVLEN") 

vcf <- readr::read_tsv(path.vcf, col_names = c("chrom", "pos", "ID", 
                                               "ref", "alt", "qual", 
                                               "filter", "info", "format", 
                                               "alto"), comment = "#") %>% 
  filter(chrom == chromosome) %>% 
  separate(info, into = info, sep=";", extra="drop", remove=FALSE) %>%  
  mutate(SVTYPE = str_remove(SVTYPE, pattern = "SVTYPE="),
         SVLEN = as.numeric(str_remove(SVLEN, pattern = "SVLEN=")),
         END = as.numeric(str_remove(END, pattern = "END="))) %>% 
  filter(pos > start, END < end)

vcf %>% filter(str_detect(info, "SVTYPE=INS")) %>% 
  # Remove the insertions where we don't know the sequence.
  # we need the sequence for simulation.
  filter(alt != "<INS>") -> ins

vcf %>% filter(str_detect(info, "SVTYPE=INV")) -> inv
vcf %>% filter(str_detect(info, "SVTYPE=DEL")) -> del


if (nins > nrow(ins)){
  nins=nrow(ins)
}
if (ninv > nrow(inv)){
  ninv=nrow(inv)
}
if (ndel > nrow(del)){
  ndel=nrow(del)
}

cat(nrow(ins), "\n")
cat("nins:", nins, "\nninv", ninv, "\nndel", ndel)

for (i in 1:nhaplotypes){
  set.seed(i)
  ins2 <- ins[sample(nrow(ins), nins),]
  del2 <- del[sample(nrow(del), ndel),]
  inv2 <- inv[sample(nrow(inv), ninv),]
  
  joined.tbl <- rbind(ins2, del2, inv2) %>% 
    mutate(INF = ifelse(SVTYPE == "INS", alt, "None")) %>% 
    mutate(SVTYPE = str_replace(SVTYPE, "INS", "insertion")) %>% 
    mutate(SVTYPE = str_replace(SVTYPE, "INV", "inversion")) %>% 
    mutate(SVTYPE = str_replace(SVTYPE, "DEL", "deletion")) %>% 
    select(chrom, pos, END, SVTYPE, INF) %>% 
    mutate(random.seq = 0)
  
  
  write_tsv(joined.tbl, str_c("ssa22_", i, ".bed"), col_names = FALSE)
  
}
