test_that("persistence round-trips a fitted linear regression model", {
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

  builder <- sk_linear_regression()
  on.exit(close(builder), add = TRUE)

  model <- fit(builder, x, y)
  baseline_preds <- predict(model, x)

  path <- tempfile(fileext = ".skmodel")
  on.exit(unlink(path), add = TRUE)

  expect_invisible(save_model(model, path))
  expect_true(file.exists(path))
  close(model)

  restored <- load_model(path)
  on.exit(close(restored), add = TRUE)

  expect_equal(predict(restored, x), baseline_preds, tolerance = 1e-12)
  expect_equal(score(restored, x, y), 1.0, tolerance = 1e-12)
})

test_that("persistence surfaces ABI errors for unsupported families and missing files", {
  x <- matrix(c(1.0, 2.0, 3.0, 4.0), nrow = 2, ncol = 2)
  scaler_builder <- sk_standard_scaler()
  on.exit(close(scaler_builder), add = TRUE)
  scaler <- fit(scaler_builder, x)
  on.exit(close(scaler), add = TRUE)

  path <- tempfile(fileext = ".skmodel")
  err_save <- tryCatch(save_model(scaler, path), error = identity)
  expect_s3_class(err_save, "sciencekit_error")
  expect_identical(err_save$status, "unsupported")
  expect_identical(err_save$status_code, 4L)

  missing_path <- file.path(tempdir(), "does-not-exist-sciencekitr-model.bin")
  err_load <- tryCatch(load_model(missing_path), error = identity)
  expect_s3_class(err_load, "sciencekit_error")
  expect_identical(err_load$status, "io")
  expect_identical(err_load$status_code, 6L)
})
