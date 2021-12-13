
library(tidyverse)


path.vcf <- "/mnt/SCRATCH/ankjelst/data/pggb-v020-G5G-k85.out/mergedVISOR.fasta.2dd9516.b921d7e.8053ffa.smooth.ssa22.vcf"

vcf <- read_delim(path.vcf, delim = "\t", comment="#", col_names = c('CHROM', 'POS', 'ID', 'REF', 'ALT','QUAL',  'FILTER', 'INFO', 'FORMAT'))

path.true <- "/mnt/SCRATCH/ankjelst/data/ssa22variants.bed"

vcf.true <- read_delim(path.true, delim = "\t", comment="#", col_names = c('CHROM', 'START', 'END', 'TYPE', 'SEQUENCE', 'X'))



###
# Match positions

find_variant<- function(trueVariants, foundVariants, tolerance=0){
  # Function to match true variants we inserted and the ones found with pggb
  # To make it easy to compare
  
  # make a matrix of allowed positions
  if (tolerance > 0){
    allowed_positions <- sapply(trueVariants, function(x) seq(x-tolerance, x+tolerance, 1))
    
  } else{ allowed_positions <- trueVariants}
  
  # filter so we only have variants with allowed positions
  filteredVariants <- foundVariants[foundVariants %in% allowed_positions]
  
  # match variants with true variants
  
  if (tolerance >0){
      col.idx <- sapply(filteredVariants, function(x) which(allowed_positions == x, arr.ind = TRUE))[2,]
  }else{col.idx <- sapply(filteredVariants, function(x) which(allowed_positions == x))}
  
  # combine the positions.
  result.tbl <- tibble(true.position = trueVariants[col.idx], our.position = filteredVariants)
  
  
  return(result.tbl)
}



myTable <- find_variant(vcf.true$START, vcf$POS, 10)

left_join(myTable, vcf, by = c("our.position" = "POS")) %>% 
  left_join(vcf.true, by = c("true.position" = "START")) -> full.table

filter(full.table, TYPE == "inversion") -> inversions

filter(full.table, TYPE == "deletion") -> deletions

filter(full.table, TYPE == "insertion") -> insertions





###
# Definitly false variants

filter(vcf, !(POS %in% full.table$our.position))


####
#Genotype vcf

genotype.path <- "/mnt/SCRATCH/ankjelst/data/giraffe/genotypes.vcf"
genotype.vcf <- read_delim(genotype.path, delim="\t", comment = "##")





# NOT FINISHED
# Plan: write code for finding FP, FN, TP
false_variant <- function(trueVariants, foundVariants, tolerance=0){
  if (tolerance > 0){
    allowed_positions <- sapply(trueVariants, function(x) seq(x-tolerance, x+tolerance, 1))
    
  } else{ allowed_positions <- trueVariants}
  idx <- foundVariants %in% allowed_positions
  position <- foundVariants[!idx]
  return(position)
}

false <- filter(vcf, POS == false_variant(vcf.true$START, vcf$POS, 20))




