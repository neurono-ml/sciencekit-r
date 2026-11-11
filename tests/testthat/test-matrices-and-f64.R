test_that("ragged non-rectangular input raises a shape error before native call", {
  ragged_df <- structure(
    list(x1 = c(1.0, 2.0), x2 = c(1.0, 2.0, 3.0)),
    class = "data.frame",
    row.names = c(NA, -2L)
  )
  builder <- sk_standard_scaler()
  on.exit(close(builder), add = TRUE)

  err <- tryCatch(fit(builder, ragged_df), error = identity)
  expect_s3_class(err, "sciencekit_error")
  expect_identical(err$status, "shape")
  expect_identical(err$status_code, 2L)
  expect_match(err$message, "ragged", ignore.case = TRUE)
})

test_that("integer, logical, character and f32 inputs are rejected without silent coercion", {
  builder <- sk_linear_regression()
  on.exit(close(builder), add = TRUE)

  int_mat <- matrix(1L:4L, nrow = 2, ncol = 2)
  err_int <- tryCatch(fit(builder, int_mat, c(1.0, 2.0)), error = identity)
  expect_s3_class(err_int, "sciencekit_error")
  expect_match(err_int$message, "only double \\(f64\\)", ignore.case = TRUE)

  lgl_mat <- matrix(c(TRUE, FALSE, TRUE, FALSE), nrow = 2, ncol = 2)
  err_lgl <- tryCatch(fit(builder, lgl_mat, c(1.0, 2.0)), error = identity)
  expect_s3_class(err_lgl, "sciencekit_error")
  expect_match(err_lgl$message, "only double \\(f64\\)", ignore.case = TRUE)

  chr_mat <- matrix(c("a", "b", "c", "d"), nrow = 2, ncol = 2)
  err_chr <- tryCatch(fit(builder, chr_mat, c(1.0, 2.0)), error = identity)
  expect_s3_class(err_chr, "sciencekit_error")
  expect_match(err_chr$message, "only double \\(f64\\)", ignore.case = TRUE)

  dbl_mat <- matrix(c(1.0, 2.0, 3.0, 4.0), nrow = 2, ncol = 2)
  err_int_y <- tryCatch(fit(builder, dbl_mat, c(1L, 2L)), error = identity)
  expect_s3_class(err_int_y, "sciencekit_error")
  expect_match(err_int_y$message, "only double \\(f64\\)", ignore.case = TRUE)

  err_f32 <- tryCatch(sk_builder("linear_regression", dtype = "f32"), error = identity)
  expect_s3_class(err_f32, "sciencekit_error")
  expect_identical(err_f32$status, "unsupported")
  expect_identical(err_f32$status_code, 4L)
})

test_that("shape mismatches raise structured shape errors", {
  x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
  y_wrong <- c(1.0, 2.0)

  builder <- sk_linear_regression()
  on.exit(close(builder), add = TRUE)

  err_fit <- tryCatch(fit(builder, x, y_wrong), error = identity)
  expect_s3_class(err_fit, "sciencekit_error")
  expect_identical(err_fit$status, "shape")
  expect_identical(err_fit$status_code, 2L)

  model <- fit(builder, x, c(1.0, 3.0, 4.0, 14.0))
  on.exit(close(model), add = TRUE)

  x_wrong_cols <- matrix(c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0), nrow = 2, ncol = 3)
  err_pred <- tryCatch(predict(model, x_wrong_cols), error = identity)
  expect_s3_class(err_pred, "sciencekit_error")
  expect_identical(err_pred$status, "shape")
  expect_identical(err_pred$status_code, 2L)
})
