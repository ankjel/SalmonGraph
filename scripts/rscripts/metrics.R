
compare.pos <- function(first.tbl, second.tbl, tolerance=0){
  if (tolerance > 0){
    allowed.positions <- sapply(second.tbl$START, function(x) seq(x-tolerance, x+tolerance, 1))
    
  } else{ allowed.positions <- second.tbl$START}
  
  
  # compare first vector against matrix
  idx.start <- first.tbl$START %in% allowed.positions
  
  idx.end <- c()
  for (n in 1:nrow(first.tbl)){
    if (idx.start[n] == TRUE){
      rowmatch <- which(allowed.positions == first.tbl$START[n], arr.ind = T)[2]
      
      match.end <- second.tbl[rowmatch,]$END

      allowed.end <- seq(match.end - tolerance, match.end + tolerance, 1)
      ok <- first.tbl$END[n] %in% allowed.end

      idx.end <- c(idx.end, ok)
      
    }else{idx.end <- c(idx.end, FALSE)}
  }
  idx <- idx.start == TRUE & idx.end == TRUE
  return(idx)
}

##################################################################



true.positive <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  
  idx <- compare.pos(true.vcf, predicted.vcf, tolerance)
  
  TP <- sum(idx) # TP = true positions found in predicted positions
  return(TP)
}


false.positive <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # How many of the predicted positions are true (+- threshold)
  idx <- compare.pos(predicted.vcf, true.vcf, tolerance)  

  # sum number of predicted positions not true, also known as false positives.
  FP <- sum(!idx) 
  return(FP)
}


false.negative <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # find true positive
  # how many of the true postions are not found in graph vcf
  #  idx.start <- compare.pos(true.vcf$START, predicted.vcf$START, tolerance)
  # idx.end <- compare.pos(true.vcf$END, predicted.vcf$END, tolerance)
  #idx <- idx.start == TRUE & idx.end == TRUE
  
  
  #FN <- sum(!idx)   
  
  idx <- compare.pos(true.vcf, predicted.vcf, tolerance)
  
  TP <- sum(idx)
  
  FN <- nrow(true.vcf)-TP
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
  
  
  idx <- compare.pos(true.vcf, predicted.vcf, tolerance)
  
  df <- true.vcf[idx,]  # TP = true positions found in predicted positions
  return(df)
}


false.positive.df <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns
  
  # How many of the predicted positions are true (+- threshold)
  idx<- compare.pos(predicted.vcf, true.vcf, tolerance)  
# We need both end and start positions to be correct
  
  # sum number of predicted positions not true, also known as false positives.
  df <- predicted.vcf[!idx,] 
  return(df)
}


false.negative.df <- function(true.vcf, predicted.vcf, tolerance=0){
  # Input tibble with start and end columns

  idx <- compare.pos(true.vcf, predicted.vcf, tolerance)
  
  df <- true.vcf[!idx,] 
  
  return(df)
}
