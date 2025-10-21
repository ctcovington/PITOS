#' @title Paired-Index Test of Uniformity (PITOS)
#' @description Performs the PITOS test to check if a numeric vector follows a
#'   uniform distribution on the interval (0,1).
#'
#' @param x A numeric vector of values to test.
#' @param pairs_sequence An optional two-column matrix or data frame where each
#'   row represents a pair of indices `(start, finish)` to be tested. If `NULL`
#'   (the default), a weighted Halton sequence is generated automatically.
#'
#' @return A single p-value from the Cauchy combination test. A small p-value
#'   suggests the data does not follow a U(0,1) distribution.
#'
#' @export
#' @examples
#' # Generate some uniform data
#' set.seed(123)
#' uniform_data <- runif(20)
#' pitos(uniform_data)
#'
#' # Generate data that is not uniform
#' non_uniform_data <- rbeta(20, 2, 1)
#' pitos(non_uniform_data)
pitos <- function(x, pairs_sequence = NULL) {
  n <- length(x)

  if (is.null(pairs_sequence)) {
    # Generate a default sequence if none is provided
    N <- round(10 * n * log(n))
    pairs_sequence <- generate_weighted_halton_sequence(N, n)
  }

  # Validate the pairs
  validate_pairs(pairs_sequence, n)

  # Pre-sort the input vector
  xo <- sort(x)

  # Apply the PITCOS calculation over all pairs
  # The `apply` function iterates over each row of the pairs_sequence matrix
  p_values <- apply(pairs_sequence, 1, function(pair) {
    indexed_PITCOS_bidirectional(xo, n, pair)
  })

  # Combine p-values using the Cauchy method
  p <- cauchy_combination(p_values)

  return(p)
}


# --- Internal Helper Functions ---

#' @description Calculates the i-th element of a 1D Halton sequence.
#' @noRd
halton_1d <- function(i, b) {
  result <- 0.0
  f <- 1.0
  while (i > 0) {
    f <- f / b
    result <- result + f * (i %% b)
    i <- i %/% b # Integer division
  }
  return(result)
}

#' @description Generates a raw 2D Halton sequence.
#' @noRd
generate_raw_halton_sequence <- function(N, n) {
  if (n <= 0) {
    stop("Sample size n must be a positive integer.")
  }
  # Standard prime bases for a 2D Halton sequence
  base_x <- 2
  base_y <- 3

  i <- 1:N
  x_raw <- sapply(i, halton_1d, b = base_x)
  y_raw <- sapply(i, halton_1d, b = base_y)

  # Return as a two-column matrix
  return(cbind(x_raw, y_raw))
}

#' @description Transforms the raw Halton sequence using Beta quantiles.
#' @noRd
generate_weighted_halton_sequence <- function(N, n) {
  raw_halton <- generate_raw_halton_sequence(N, n)

  # Vectorized transformation
  weighted_x <- qbeta(raw_halton[, 1], 0.7, 0.7)
  weighted_y <- qbeta(raw_halton[, 2], 0.7, 0.7)

  # Handle cases where quantile returns exactly 0
  weighted_x[weighted_x == 0] <- 1 / n
  weighted_y[weighted_y == 0] <- 1 / n

  # Create integer pairs matrix
  weighted_pairs <- cbind(
    ceiling(weighted_x * n),
    ceiling(weighted_y * n)
  )

  # Append marginal pairs (i, i)
  marginals <- cbind(1:n, 1:n)

  return(rbind(weighted_pairs, marginals))
}

#' @description Calculates the bidirectional PITCOS p-value for a single pair.
#' @noRd
indexed_PITCOS_bidirectional <- function(xo, n, pair) {
  start <- pair[1]
  finish <- pair[2]

  u <- 0.0

  if (start == finish) {
    u <- pbeta(xo[finish], shape1 = finish, shape2 = n - finish + 1)
  } else if (start < finish) {
    if (xo[start] == xo[finish]) {
      u <- 0.0
    } else {
      # This is the CDF of a Beta(finish-start, n-finish+1) distribution
      u <- pbeta(
        (xo[finish] - xo[start]) / (1.0 - xo[start]),
        shape1 = finish - start,
        shape2 = n - finish + 1
      )
    }
  } else { # start > finish
    if (xo[start] == xo[finish]) {
      u <- 0.0
    } else {
      # This is the CDF of a Beta(finish, start-finish) distribution
      u <- pbeta(
        xo[finish] / xo[start],
        shape1 = finish,
        shape2 = start - finish
      )
    }
  }
  # Return the two-sided p-value
  return(2.0 * min(u, 1.0 - u))
}

#' @description Combines p-values using the Cauchy combination method.
#' @noRd
cauchy_combination <- function(pvalues) {
  # Validate that all p-values are within the [0, 1] range
  if (any(pvalues < 0) || any(pvalues > 1)) {
    stop("All p-values must be in the range [0, 1].")
  }

  statistic <- mean(tan(pi * (0.5 - pvalues)))
  # The complementary CDF of the standard Cauchy distribution
  return(pcauchy(statistic, lower.tail = FALSE))
}

#' @description Validates that all indices in the pairs sequence are valid.
#' @noRd
validate_pairs <- function(pairs, n) {
  # `pairs` is expected to be a two-column matrix
  if (any(pairs < 1) || any(pairs > n)) {
    stop(sprintf("All pair indices must be between 1 and n (where n=%d).", n))
  }
}