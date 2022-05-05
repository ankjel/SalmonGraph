library(tidyverse)


# Finding the variants called for each set of reads
line <- 15
called <- tibble()
for (file in list.files("/mnt/SCRATCH/ankjelst/data/prdm9/vcfs")){
  if(file == "deconstructed.vcf") next
  
  vcf <- read_delim(str_c("/mnt/SCRATCH/ankjelst/data/prdm9/vcfs/", file), delim = "\t", comment="##") %>% 
    rename("CHROM" = `#CHROM`) %>% 
    mutate(ALT.PATHS = str_split(str_remove_all(INFO, pattern = "[A-Z]*="), ";")) %>%
    mutate(ALT.PATHS = unlist(lapply(ALT.PATHS, function(x) x[1])))
  idx1 <- as.numeric(substr(vcf[line, ncol(vcf)-1], 1, 1))
  idx2 <- as.numeric(substr(vcf[line, ncol(vcf)-1], 3, 3))
  
  all <- c()
  paths <- c()
  for (idx in c(idx1, idx2)){
    if (idx == 0){
      call <-  vcf$REF[14]
      all <- c(all, call)
      
      paths <- c(paths, vcf$ID[line])
    }else{
      call <- strsplit(vcf$ALT[line], split=",")[[1]][idx]
      all <- c(all, call)
      
      path <- strsplit(vcf$ALT.PATHS[line], split=",")[[1]][idx+1]
      paths <- c(paths, path)
    }
  
  }
  called <- bind_rows(called, 
                      tibble(ID = vcf$ID[line], path = paths, name = str_c(str_extract(file, '[A-Z]*'), c(-1, -2)), 
                             variants = all))
  }
  




# Check out what we expect:


read_tsv("/mnt/SCRATCH/ankjelst/data/prdm9/pggb-final-k311-p98.out/prdm9-znf.fasta-chop.vcf", 
         comment = "##", col_types = cols(.default="c")) -> deconstruct

deconstruct[line,] %>% 
  select(-c(Alto, Brian, Bond, Tanner)) %>% 
  separate(Arnold, into = c("Arnold-1", "Arnold-2")) %>% 
  separate(Klopp, into = c("Klopp-1", "Klopp-2")) %>% 
  separate(Maxine, into = c("Maxine-1", "Maxine-2")) %>% 
  separate(SimonResolved, into = c("Simon-1", "Simon-2")) %>% 
  pivot_longer(10:18) %>% 
  mutate(value = as.numeric(value),
         seq = ifelse(value == 0, REF, unlist(str_split(ALT, ","))[value]),
         len = str_length(seq),
         start = 1) %>% 
  mutate(ALT.PATHS = str_split(str_remove_all(str_extract(INFO, pattern = "AT=.*;"), pattern = "[A-Z]*="), ",")) %>%
  mutate(called.path = ifelse(value ==0, ID, unlist((ALT.PATHS)[value]))) -> deconstructed.vcf




