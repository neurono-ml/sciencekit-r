test_that("structured errors carry ABI status, status_code, operation and native message", {
  x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
  y <- c(1.0, 3.0, 4.0, 14.0)

  builder <- sk_linear_regression()
  on.exit(close(builder), add = TRUE)
  model <- fit(builder, x, y)
  on.exit(close(model), add = TRUE)

  # Calling transform on a linear-regression model triggers a native ABI failure.
  err <- tryCatch(transform(model, x), error = identity)
  expect_s3_class(err, "sciencekit_error")
  expect_identical(err$status, "unsupported")
  expect_identical(err$status_code, 4L)
  expect_identical(err$operation, "transform")
  expect_true(nzchar(err$native_message))
  expect_true(grepl(err$native_message, err$message, fixed = TRUE))
})

test_that("close is idempotent and operations on closed handles raise invalid-handle", {
  gc()
  baseline <- live_handle_counts()

  x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
  y <- c(1.0, 3.0, 4.0, 14.0)

  builder <- sk_linear_regression()
  expect_false(is_closed(builder))
  expect_identical(live_handle_counts()[["builders"]], baseline[["builders"]] + 1L)

  model <- fit(builder, x, y)
  expect_false(is_closed(model))
  expect_identical(live_handle_counts()[["models"]], baseline[["models"]] + 1L)

  # First close releases; second close is a safe no-op.
  expect_true(close(builder))
  expect_false(close(builder))
  expect_true(is_closed(builder))
  expect_identical(live_handle_counts()[["builders"]], baseline[["builders"]])

  expect_true(close(model))
  expect_false(close(model))
  expect_true(is_closed(model))
  expect_identical(live_handle_counts()[["models"]], baseline[["models"]])

  err_fit <- tryCatch(fit(builder, x, y), error = identity)
  expect_s3_class(err_fit, "sciencekit_error")
  expect_identical(err_fit$status, "invalid-handle")
  expect_identical(err_fit$status_code, 1L)

  err_setter <- tryCatch(set_backend(builder, "invalid"), error = identity)
  expect_s3_class(err_setter, "sciencekit_error")
  expect_identical(err_setter$status, "invalid-handle")
  expect_identical(err_setter$status_code, 1L)

  err_pred <- tryCatch(predict(model, x), error = identity)
  expect_s3_class(err_pred, "sciencekit_error")
  expect_identical(err_pred$status, "invalid-handle")
  expect_identical(err_pred$status_code, 1L)

  err_tr <- tryCatch(transform(model, x), error = identity)
  expect_s3_class(err_tr, "sciencekit_error")
  expect_identical(err_tr$status, "invalid-handle")
  expect_identical(err_tr$status_code, 1L)

  err_sc <- tryCatch(score(model, x, y), error = identity)
  expect_s3_class(err_sc, "sciencekit_error")
  expect_identical(err_sc$status, "invalid-handle")
  expect_identical(err_sc$status_code, 1L)

  err_sv <- tryCatch(save_model(model, tempfile()), error = identity)
  expect_s3_class(err_sv, "sciencekit_error")
  expect_identical(err_sv$status, "invalid-handle")
  expect_identical(err_sv$status_code, 1L)
})

test_that("ABI error message survives GC finalizer activity under gctorture", {
  x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
  y <- c(1.0, 3.0, 4.0, 14.0)
  builder <- sk_linear_regression()
  on.exit(close(builder), add = TRUE)
  model <- fit(builder, x, y)
  on.exit(close(model), add = TRUE)

  # Leave an unreachable handle eligible for finalization during error allocation.
  local({
    unused <- sk_standard_scaler()
    invisible(unused)
  })

  gctorture(TRUE)
  err <- tryCatch(
    transform(model, x),
    error = identity,
    finally = gctorture(FALSE)
  )
  expect_s3_class(err, "sciencekit_error")
  expect_identical(err$status, "unsupported")
  expect_true(nzchar(err$native_message))
})

test_that("garbage collector finalizers release unreachable handles", {
  gc()
  baseline <- live_handle_counts()

  allocate_scoped <- function() {
    x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
    y <- c(1.0, 3.0, 4.0, 14.0)
    b <- sk_linear_regression()
    m <- fit(b, x, y)
    invisible(predict(m, x))
  }

  allocate_scoped()
  gc()
  gc()

  expect_identical(live_handle_counts(), baseline)
})

test_that("repeated failures do not leak native handles", {
  gc()
  baseline <- live_handle_counts()

  x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
  y <- c(1.0, 3.0, 4.0, 14.0)
  x_bad_cols <- matrix(c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0), nrow = 2, ncol = 3)
  x_nan <- matrix(c(NaN, 1.0, 2.0, 3.0), nrow = 2, ncol = 2)

  builder <- sk_linear_regression()
  model <- fit(builder, x, y)

  for (i in seq_len(100L)) {
    tryCatch(fit(builder, x_nan, c(1.0, 2.0)), error = identity)
    tryCatch(fit(builder, x, c(1.0, 2.0)), error = identity)
    tryCatch(predict(model, x_bad_cols), error = identity)
    tryCatch(transform(model, x), error = identity)
    tryCatch(load_model("/nonexistent/sciencekitr/path.bin"), error = identity)
  }

  close(model)
  close(builder)
  gc()

  expect_identical(live_handle_counts(), baseline)
})
