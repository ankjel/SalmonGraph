
library(tidyverse)

# this script will make the bed-file with SVs to be inserted into
# chr 22 to make up our simulated data set

path.vcf <- "/mnt/SCRATCH/ankjelst/data/eu_merged_iris_no_simon.vcf"

out.file <- "/mnt/SCRATCH/ankjelst/data/ssa22variants.bed"

# read our SV library vcf
vcf <- readr::read_tsv(path.vcf, col_names = c("chrom", "pos", "ID", 
                                           "ref", "alt", "qual", 
                                           "filter", "info", "format", 
                                           "alto"), comment = "#") %>% 
  filter(chrom == "ssa22") # leave out all variants not on chromosome 22

info <- c("SVTYPE", NA, "END", "SVLEN") # info column tags

vcf.filtered <- vcf %>% 
# the next line will separate the vcf-info field into separate columns for each tag
  separate(info, into = info, sep=";", extra="drop", remove=FALSE) %>%  
  mutate(SVTYPE = str_remove(SVTYPE, pattern = "SVTYPE="),
         SVLEN = as.numeric(str_remove(SVLEN, pattern = "SVLEN=")),
         END = as.numeric(str_remove(END, pattern = "END="))) #%>% filter(pos > 14000000, END < 24000000)


vcf.filtered %>% filter(str_detect(info, "SVTYPE=INS")) %>% 
  # Remove the insertions where we don't know the sequence.
  # we need the sequence for simulation.
  filter(alt != "<INS>") -> ins

vcf.filtered %>% filter(str_detect(info, "SVTYPE=INV")) -> inv
vcf.filtered %>% filter(str_detect(info, "SVTYPE=DEL")) -> del


# use sample() to select random rows from ins and del
# no need to do this for inversions as we have less than 10
set.seed(100)

ins <- ins[sample(nrow(ins), 50),]
del <- del[sample(nrow(del), 50),]
inv <- inv[sample(nrow(inv), 20),]

# merge to this format https://davidebolo1993.github.io/visordoc/usage/usage.html#visor-hack

joined.tbl <- rbind(ins, del, inv) %>% 
  mutate(INF = ifelse(SVTYPE == "INS", alt, "None")) %>% 
  mutate(SVTYPE = str_replace(SVTYPE, "INS", "insertion")) %>% 
  mutate(SVTYPE = str_replace(SVTYPE, "INV", "inversion")) %>% 
  mutate(SVTYPE = str_replace(SVTYPE, "DEL", "deletion")) %>% 
  select(chrom, pos, END, SVTYPE, INF) %>% 
  mutate(random.seq = 0)


write_tsv(joined.tbl, out.file, col_names = FALSE)


