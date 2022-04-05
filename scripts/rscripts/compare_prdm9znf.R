library(tidyverse)


# Finding the variants called for each set of reads

called <- tibble()
for (file in list.files("/mnt/SCRATCH/ankjelst/data/prdm9/vcfs")){
  if(file == "deconstructed.vcf") next
  
  vcf <- read_delim(str_c("/mnt/SCRATCH/ankjelst/data/prdm9/vcfs/", file), delim = "\t", comment="##") %>% 
    rename("CHROM" = `#CHROM`)
  idx1 <- as.numeric(substr(vcf[14, ncol(vcf)], 1, 1))
  idx2 <- as.numeric(substr(vcf[14, ncol(vcf)], 3, 3))
  
  all <- c()
  for (idx in c(idx1, idx2)){
    if (idx == 0){
      call <-  vcf$REF[14]
      all <- c(all, call)
    }else{
      call <- strsplit(vcf$ALT[14], split=",")[[1]][idx]
      all <- c(all, call)
    }
  
  }
  called <- bind_rows(called, 
                      tibble(name = str_extract(file, '[A-Z]*'), 
                             variants = all))
  }
  

called <- called %>% mutate(size = str_length(variants), 
                  nznf = size/84)




# Check out what we expect:

true.path <- "/mnt/SCRATCH/ankjelst/data/prdm9/vcfs/deconstructed.vcf"

truth <- read_tsv(true.path, comment = "##")[14, ] %>% 
  select(!starts_with("Simon#")) %>% 
  pivot_longer(-(1:9)) %>% 
  mutate(sekvens = ifelse(value == 0, REF, str_split(ALT, pattern = ",")[[1]][value]),
         length = str_length(sekvens),
         nznf = length/84) 



