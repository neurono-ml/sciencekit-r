test_that("standard scaler transforms matrices with expected shape and statistics", {
  # Column 1 has values 1..4 (mean 2.5); column 2 has values 10..40 (mean 25).
  x <- matrix(
    c(
      1.0, 10.0,
      2.0, 20.0,
      3.0, 30.0,
      4.0, 40.0
    ),
    nrow = 4,
    ncol = 2,
    byrow = TRUE
  )

  builder <- sk_standard_scaler(with_mean = TRUE, with_std = TRUE)
  on.exit(close(builder), add = TRUE)

  scaler <- fit(builder, x)
  on.exit(close(scaler), add = TRUE)

  transformed <- transform(scaler, x)
  expect_true(is.matrix(transformed))
  expect_type(transformed, "double")
  expect_identical(dim(transformed), c(4L, 2L))

  # Population standard deviation of (1, 2, 3, 4) is sqrt(1.25).
  pop_sd_col1 <- sqrt(mean((x[, 1] - mean(x[, 1]))^2))
  pop_sd_col2 <- sqrt(mean((x[, 2] - mean(x[, 2]))^2))
  expected <- cbind(
    (x[, 1] - mean(x[, 1])) / pop_sd_col1,
    (x[, 2] - mean(x[, 2])) / pop_sd_col2
  )
  expect_equal(transformed, expected, tolerance = 1e-9)
  expect_equal(sk_transform(scaler, x), expected, tolerance = 1e-9)
})

test_that("standard scaler honors with_mean and with_std toggles", {
  x <- matrix(c(2.0, 4.0, 6.0, 10.0, 20.0, 30.0), nrow = 3, ncol = 2)

  builder <- sk_standard_scaler(with_mean = TRUE, with_std = FALSE)
  on.exit(close(builder), add = TRUE)
  scaler <- fit(builder, x)
  on.exit(close(scaler), add = TRUE)

  centered <- transform(scaler, x)
  expected <- cbind(x[, 1] - mean(x[, 1]), x[, 2] - mean(x[, 2]))
  expect_equal(centered, expected, tolerance = 1e-9)
})
