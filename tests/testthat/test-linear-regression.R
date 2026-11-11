test_that("linear regression fits, predicts and scores on an exact linear fixture", {
  # y = 1 + 2 * x1 + 3 * x2
  x <- matrix(
    c(
      0.0, 0.0,
      1.0, 0.0,
      0.0, 1.0,
      2.0, 3.0
    ),
    nrow = 4,
    ncol = 2,
    byrow = TRUE
  )
  y <- c(1.0, 3.0, 4.0, 14.0)

  builder <- sk_linear_regression(include_intercept = TRUE, backend = "faer")
  on.exit(close(builder), add = TRUE)

  model <- fit(builder, x, y)
  on.exit(close(model), add = TRUE)

  preds <- predict(model, x)
  expect_type(preds, "double")
  expect_length(preds, 4L)
  expect_equal(preds, y, tolerance = 1e-9)

  r2 <- score(model, x, y)
  expect_type(r2, "double")
  expect_equal(r2, 1.0, tolerance = 1e-9)

  # Out-of-sample rows verify column-major <-> row-major layout fidelity.
  x_new <- matrix(c(3.0, 4.0, -1.0, 2.0), nrow = 2, ncol = 2, byrow = TRUE)
  expected_new <- c(1.0 + 2.0 * 3.0 + 3.0 * 4.0, 1.0 + 2.0 * (-1.0) + 3.0 * 2.0)
  expect_equal(predict(model, x_new), expected_new, tolerance = 1e-9)
})

test_that("linear regression accepts rectangular double data frames and alternative backends", {
  df <- data.frame(
    x1 = c(1.0, 2.0, 3.0, 4.0, 5.0),
    x2 = c(2.0, 1.0, 4.0, 3.0, 5.0)
  )
  y <- 0.5 + 1.5 * df$x1 - 2.0 * df$x2

  for (backend in c("faer", "matrix_multiply", "ndarray_linalg")) {
    builder <- sk_linear_regression(include_intercept = TRUE, backend = backend)
    model <- fit(builder, df, y)
    expect_equal(predict(model, df), y, tolerance = 1e-8)
    expect_equal(score(model, df, y), 1.0, tolerance = 1e-8)
    close(model)
    close(builder)
  }
})
