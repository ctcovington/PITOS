# run_pitos.R
library(PITOS)

args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript run_pitos.R <filepath>", call.=FALSE)
}

# read.table reads the entire matrix of simulations
# Each column is treated as a separate simulation
data_matrix <- read.table(args[1])

# Apply the pitos function to each column of the matrix
p_values <- apply(data_matrix, 2, pitos)

# Print all resulting p-values, separated by newlines
cat(p_values, sep = "\n")