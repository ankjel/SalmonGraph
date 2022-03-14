library(tidyverse)



compare.pos <- function(first.vector, second.vector, tolerance=0){
  #  Will check if all instances in first input are present in second input +- tolerance
  
  # first make a matrix of all allowed positions
  if (tolerance > 0){
    allowed_positions <- sapply(second.vector, function(x) seq(x-tolerance, x+tolerance, 1))
    
  } else{ allowed_positions <- second.vector}
  
  # compare first vector against matrix
  idx <- first.vector %in% allowed_positions
  # return index of instances in first vector found in second vector
  return(idx)
}



##################################################################



true.positive <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  
  idx.start <- compare.pos(true.vcf$START, predicted.vcf$START, tolerance)
  idx.end <- compare.pos(true.vcf$END, predicted.vcf$END, tolerance)
  idx <- idx.start == TRUE & idx.end == TRUE
  
  TP <- sum(idx) # TP = true positions found in predicted positions
  return(TP)
}


false.positive <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # How many of the predicted positions are true (+- threshold)
  idx.start <- compare.pos(predicted.vcf$START, true.vcf$START, tolerance)  
  idx.end <- compare.pos(predicted.vcf$END, true.vcf$END, tolerance)
  idx <- idx.start == TRUE & idx.end == TRUE # We need both end and start positions to be correct
  
  # sum number of predicted positions not true, also known as false positives.
  FP <- sum(!idx) 
  return(FP)
}


false.negative <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # find true positive
  # how many of the true postions are not found in graph vcf
  idx.start <- compare.pos(true.vcf$START, predicted.vcf$START, tolerance)
  idx.end <- compare.pos(true.vcf$END, predicted.vcf$END, tolerance)
  idx <- idx.start == TRUE & idx.end == TRUE
  
  
  FN <- sum(!idx)   
  return(FN)
}


##################################################################


precision <- function(true.vcf, predicted.vcf, tolerance=0){
  
  TP <- true.positive(true.vcf, predicted.vcf, tolerance)
  FP <- false.positive(true.vcf, predicted.vcf, tolerance)
  

  return(TP / (TP + FP))
}



recall <- function(true.vcf, predicted.vcf, tolerance=0){
  TP <- true.positive(true.vcf, predicted.vcf, tolerance)
  FN <- false.negative(true.vcf, predicted.vcf, tolerance)
  return(TP / (TP + FN))
}




#############################################################

# Make functions to extract df with TP, FN and FP 

true.positive.df <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  
  idx.start <- compare.pos(true.vcf$START, predicted.vcf$START, tolerance)
  idx.end <- compare.pos(true.vcf$END, predicted.vcf$END, tolerance)
  idx <- idx.start == TRUE & idx.end == TRUE
  
  df <- true.vcf[idx,]  # TP = true positions found in predicted positions
  return(df)
}


false.positive.df <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # How many of the predicted positions are true (+- threshold)
  idx.start <- compare.pos(predicted.vcf$START, true.vcf$START, tolerance)  
  idx.end <- compare.pos( predicted.vcf$END, true.vcf$END, tolerance)
  idx <- idx.start == TRUE & idx.end == TRUE # We need both end and start positions to be correct
  
  # sum number of predicted positions not true, also known as false positives.
  df <- predicted.vcf[!idx,] 
  return(df)
}


false.negative.df <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # find true positive
  # how many of the true postions are predicter
  idx.start <- compare.pos(true.vcf$START, predicted.vcf$START, tolerance)
  idx.end <- compare.pos(true.vcf$END, predicted.vcf$END, tolerance)
  idx <- idx.start == TRUE & idx.end == TRUE
  
  df <- true.vcf[!idx,] 
  return(df)
}





