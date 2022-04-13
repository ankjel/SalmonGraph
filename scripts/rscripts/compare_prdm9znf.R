library(tidyverse)


# Finding the variants called for each set of reads

called <- tibble()
for (file in list.files("/mnt/SCRATCH/ankjelst/data/prdm9/vcfs")){
  if(file == "deconstructed.vcf") next
  
  vcf <- read_delim(str_c("/mnt/SCRATCH/ankjelst/data/prdm9/vcfs/", file), delim = "\t", comment="##") %>% 
    rename("CHROM" = `#CHROM`) %>% 
    mutate(ALT.PATHS = str_split(str_remove_all(INFO, pattern = "[A-Z]*="), ";")) %>%
    mutate(ALT.PATHS = unlist(lapply(ALT.PATHS, function(x) x[1])))
  idx1 <- as.numeric(substr(vcf[14, ncol(vcf)-1], 1, 1))
  idx2 <- as.numeric(substr(vcf[14, ncol(vcf)-1], 3, 3))
  
  all <- c()
  paths <- c()
  for (idx in c(idx1, idx2)){
    if (idx == 0){
      call <-  vcf$REF[14]
      all <- c(all, call)
      
      paths <- c(paths, vcf$ID)
    }else{
      call <- strsplit(vcf$ALT[14], split=",")[[1]][idx]
      all <- c(all, call)
      
      path <- strsplit(vcf$ALT.PATHS[14], split=",")[[1]][idx]
      paths <- c(paths, path)
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



################
# New graph without collapsed simon 75 bp znf


# Finding the variants called for each set of reads

called.new <- tibble()
for (file in list.files("/mnt/SCRATCH/ankjelst/data/prdm9/vcf_new")){
  if(file == "deconstructed.vcf") next
  
  for (line in c(1,6,7)){
  vcf <- read_delim(str_c("/mnt/SCRATCH/ankjelst/data/prdm9/vcf_new/", file), delim = "\t", comment="##") %>% 
    rename("CHROM" = `#CHROM`) %>% 
    mutate(ALT.PATHS = str_split(str_remove_all(INFO, pattern = "[A-Z]*="), ";")) %>%
    mutate(ALT.PATHS = unlist(lapply(ALT.PATHS, function(x) x[1])))
  
  
  idx1 <- as.numeric(substr(vcf[line, ncol(vcf)-1], 1, 1))
  idx2 <- as.numeric(substr(vcf[line, ncol(vcf)-1], 3, 3))
  
  all <- c()
  paths <- c()
  for (idx in c(idx1, idx2)){
    if (idx == 0){
      call <-  vcf$REF[line]
      all <- c(all, call)
      
      paths <- c(paths, vcf$ID)
    }else{
      call <- strsplit(vcf$ALT[line], split=",")[[1]][idx]
      all <- c(all, call)
      
      path <- strsplit(vcf$ALT.PATHS[line], split=",")[[1]][idx]
      paths <- c(paths, path)
    }
    
  }
  called.new <- bind_rows(called.new, 
                      tibble(name = str_extract(file, '[A-Z]*'), 
                             variants = all))}
}


called.new <- called.new %>% mutate(size = str_length(variants), 
                            nznf = size/84)




##########################
# vg deconstructed calls

true.path <- "/mnt/SCRATCH/ankjelst/data/prdm9/vcf_new/deconstructed.vcf"

truth.new <- read_tsv(true.path, comment = "##")[c(1, 6, 7), ] %>% 
  select(!starts_with("Simon#")) %>% 
  pivot_longer(-(1:9)) %>% 
  mutate(sekvens = ifelse(value == 0, REF, str_split(ALT, pattern = ",")[[1]][value]),
         length = str_length(sekvens),
         nznf = length/84) 


truth.new %>% group_by(name) %>% 
  summarise(n = sum(nznf))




## see in a set fragment size helps

frgm <- tibble()
for (file in list.files("/mnt/SCRATCH/ankjelst/data/prdm9/frgm/")){
  if(file == "deconstructed.vcf") next
  
  for (line in c(1,6,7)){
    vcf <- read_delim(str_c("/mnt/SCRATCH/ankjelst/data/prdm9/frgm/", file), delim = "\t", comment="##") %>% 
      rename("CHROM" = `#CHROM`) %>% 
      mutate(ALT.PATHS = str_split(str_remove_all(INFO, pattern = "[A-Z]*="), ";")) %>%
      mutate(ALT.PATHS = unlist(lapply(ALT.PATHS, function(x) x[1])))
    
    
    idx1 <- as.numeric(substr(vcf[line, ncol(vcf)-1], 1, 1))
    idx2 <- as.numeric(substr(vcf[line, ncol(vcf)-1], 3, 3))
    
    all <- c()
    paths <- c()
    for (idx in c(idx1, idx2)){
      if (idx == 0){
        call <-  vcf$REF[line]
        all <- c(all, call)
        
        paths <- c(paths, vcf$ID)
      }else{
        call <- strsplit(vcf$ALT[line], split=",")[[1]][idx]
        all <- c(all, call)
        
        path <- strsplit(vcf$ALT.PATHS[line], split=",")[[1]][idx]
        paths <- c(paths, path)
      }
      
    }
    frgm <- bind_rows(frgm, 
                        tibble(name = str_extract(file, '[A-Z]*'), 
                               variants = all))}
}


frgm <- frgm %>% mutate(size = str_length(variants), 
                            nznf = size/84)



