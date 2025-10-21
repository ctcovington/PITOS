test_that("Helper functions work correctly", {
  # Test the 1D Halton sequence generator
  expect_equal(halton_1d(1, 2), 0.5)
  expect_equal(halton_1d(2, 2), 0.25)
  expect_equal(halton_1d(3, 2), 0.75)
  expect_equal(halton_1d(1, 3), 1/3)
  expect_equal(halton_1d(2, 3), 2/3, tolerance = 1e-9)

  # Test the core bidirectional PIT calculation
  n <- 10
  # A perfectly sorted vector of order statistics from U(0,1)
  xo <- (1:n) / (n + 1.0)

  # For a perfectly uniform sample, one-sided p-values should be near 0.5,
  # so the two-sided p-value should be large (near 1.0).
  u_forward <- indexed_PITCOS_bidirectional(xo, n, c(2, 5))
  expect_gt(u_forward, 0.9)
  expect_lte(u_forward, 1.0)

  u_backward <- indexed_PITCOS_bidirectional(xo, n, c(8, 3))
  expect_gt(u_backward, 0.9)
  expect_lte(u_backward, 1.0)
})


test_that("Input validation and error handling work", {
  n <- 10
  x <- runif(n)

  # Test that invalid pairs throw an error
  expect_error(pitos(x, pairs_sequence = cbind(0, 5)))
  expect_error(pitos(x, pairs_sequence = cbind(3, 0)))
  expect_error(pitos(x, pairs_sequence = cbind(-1, 7)))
  expect_error(pitos(x, pairs_sequence = cbind(7, 11)))
})


test_that("Main `pitos` function provides valid output", {
  set.seed(1) # For reproducibility
  n <- 20
  x_rand <- runif(n)

  # Test default mode
  p_default <- pitos(x_rand)
  expect_gte(p_default, 0.0)
  expect_lte(p_default, 1.0)

  # Test mode with a custom sequence of pairs
  custom_pairs <- matrix(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), ncol = 2, byrow = TRUE)
  p_custom <- pitos(x_rand, pairs_sequence = custom_pairs)
  expect_gte(p_custom, 0.0)
  expect_lte(p_custom, 1.0)
  # Running it again should yield the exact same result
  expect_equal(p_custom, pitos(x_rand, pairs_sequence = custom_pairs))

  # Test with an edge-case vector (all identical values)
  # This is extremely non-uniform, so the p-value should be very small
  x_identical <- rep(0.5, n)
  expect_lt(pitos(x_identical), 1e-5)
})
