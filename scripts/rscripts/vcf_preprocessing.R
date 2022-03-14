
library(tidyverse)
library(gggenes)

# this script will make the bed-file with SVs to be inserted into ssa22

overlappingVariants <- function(mytable){
  require(GenomicRanges)
  df <- tibble()
  for (i in 1:nrow(mytable)){
    # Use each variant as a query to check for overlaps with the rest of the variants
    tbl <-findOverlaps(makeGRangesFromDataFrame(mytable[i,]), makeGRangesFromDataFrame(mytable[-i,]), type = "any", minoverlap = 1)
    if (nrow(as.data.frame(tbl)) != 0){ # if there are any overlapping variants to the query i:
      partner <- as.data.frame(tbl)$subjectHits # get the rownumbers of the overlapping variants
      for (j in partner){ # for each variant overlapping
        if (i <= j){ 
          j = j+1
          df <- rbind(df, tibble(row1=i, row2=j))
        }
        else{
          df <- rbind(df, tibble(row1 = j, row2 = i))}
      }
    }
  }
  if (nrow(df) >0){
    df <- distinct(df)
  }
  
  return (df)
}

path.vcf <- "/mnt/SCRATCH/kristenl/supergene/supp_3/eu_supp_3.vcf"

out.file <- "/mnt/users/ankjelst/MasterScripts/scripts/sim/ssa22variants_tworegions.bed"

# read our SV library vcf
vcf <- readr::read_tsv(path.vcf, col_names = c("chrom", "pos", "ID", 
                                           "ref", "alt", "qual", 
                                           "filter", "info", "format", 
                                           "alto"), comment = "#") %>% 
  filter(chrom == "ssa22") # leave out all variants not on chromosome 22

info.into <- c("SVTYPE", NA, "END", "SVLEN") # info column tags

vcf.filtered <- vcf %>% 
# the next line will extract useful information from the info-column to its own columns
  separate(info, into = info.into, sep=";", extra="drop", remove=FALSE) %>%  
  mutate(SVTYPE = str_remove(SVTYPE, pattern = "SVTYPE="),
         SVLEN = as.numeric(str_remove(SVLEN, pattern = "SVLEN=")),
         END = as.numeric(str_remove(END, pattern = "END="))) %>% 
  # will also bring supp (number of tools which supports variant) into its own column
  mutate(supp=str_extract(info, pattern="SUPP=[0-9]")) %>% 
  separate(supp, into=c(NA, "supp"), sep="=") %>% 
  # new supp column is uset to filter the variants so end up with those supported by 2 or more tools
  filter(supp >= 2)
  
######################################
# Non-repeat region - 14-24 Mbp

region1 <- vcf.filtered %>% 
  filter(pos > 14000000, pos < 24000000) 

region1pos <- select(region1, chrom, pos, END) %>% rename("start" = pos, "end" = END)

df <- overlappingVariants(region1pos)

dim(df)

# no overlapping variants in region 1

########################################
# Repeat region - region 2 52-62 Mbp

region2 <- vcf.filtered %>% 
  filter(pos > 52000000, pos < 62000000) 

region2pos <- select(region2, chrom, pos, END) %>% rename("start" = pos, "end" = END)

df <- overlappingVariants(region2pos)

df <- region2[df$row1,] %>% 
  mutate(pair = factor(1:nrow(df))) %>% 
  rbind(mutate(region2[df$row2,], pair = factor(1:nrow(df))))

df %>% 
  mutate(id = factor(row_number())) %>% 
  mutate(pair = factor(pair, labels= c("Deletion 6090 bp long, ins = 112bp", "Deletion 180 bp long, ins = 56bp", "Deletion 98 bp long, ins = 58bp"))) %>% 
  ggplot(aes(xmin = pos, xmax = END, y = id, fill = id)) +  
  geom_gene_arrow() + 
  facet_wrap(~pair, ncol = 1, scales = "free")  + 
  labs(x = "Position in ssa22") 

ggsave("file.png", device = "png")

region2 <- region2 %>% filter(!(pos %in% df$pos[c(4, 5, 6)])) 
# Of the 6 overlapping variants i keep id = 6 because it has 4 supporting tools
# I also keep 4 and 5 because 

# merge to this format https://davidebolo1993.github.io/visordoc/usage/usage.html#visor-hack




joined.tbl <- rbind(region1, region2) %>% 
  mutate(INF = ifelse(SVTYPE == "INS", alt, "None")) %>% 
  mutate(SVTYPE = str_replace(SVTYPE, "INS", "insertion")) %>% 
  mutate(SVTYPE = str_replace(SVTYPE, "INV", "inversion")) %>% 
  mutate(SVTYPE = str_replace(SVTYPE, "DEL", "deletion")) %>% 
  select(chrom, pos, END, SVTYPE, INF) %>% 
  mutate(random.seq = 0)


write_tsv(joined.tbl, out.file, col_names = FALSE)


