library(PITOS) 

args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript run_pitos.R <filepath>", call.=FALSE)
}

data <- read.table(args[1])[[1]]
n <- length(data)

# Use a fixed set of pairs for a deterministic test
p_value <- pitos(data)

# Print only the final p-value
cat(p_value)