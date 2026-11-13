test_that("print methods report family, dtype and handle state", {
  builder <- sk_linear_regression()
  on.exit(close(builder), add = TRUE)

  expect_invisible(print(builder))
  expect_output(print(builder), "sciencekit_builder", fixed = TRUE)
  expect_output(print(builder), "family='linear_regression'", fixed = TRUE)
  expect_output(print(builder), "dtype='f64'", fixed = TRUE)
  expect_output(print(builder), "state='open'", fixed = TRUE)

  close(builder)
  expect_output(print(builder), "state='closed'", fixed = TRUE)

  scaler_builder <- sk_standard_scaler()
  on.exit(close(scaler_builder), add = TRUE)
  scaler <- fit(scaler_builder, matrix(c(1.0, 2.0, 3.0, 4.0), nrow = 2))
  on.exit(close(scaler), add = TRUE)

  expect_invisible(print(scaler))
  expect_output(print(scaler), "sciencekit_model", fixed = TRUE)
  expect_output(print(scaler), "family='standard_scaler'", fixed = TRUE)
  expect_output(print(scaler), "dtype='f64'", fixed = TRUE)
  expect_output(print(scaler), "state='open'", fixed = TRUE)

  close(scaler)
  expect_output(print(scaler), "state='closed'", fixed = TRUE)
})

test_that("include_intercept toggles change the fitted least-squares solution", {
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

  # Ordinary least squares without an intercept: beta = (X'X)^-1 X'y.
  expected_without_intercept <- as.vector(
    x %*% solve(crossprod(x), crossprod(x, y))
  )
  expected_with_intercept <- y

  constructor_builder <- sk_linear_regression(include_intercept = FALSE)
  on.exit(close(constructor_builder), add = TRUE)
  constructor_model <- fit(constructor_builder, x, y)
  on.exit(close(constructor_model), add = TRUE)

  expect_equal(
    predict(constructor_model, x),
    expected_without_intercept,
    tolerance = 1e-9
  )
  expect_false(isTRUE(all.equal(
    predict(constructor_model, x),
    expected_with_intercept,
    tolerance = 1e-9
  )))

  setter_builder <- sk_builder("linear_regression", include_intercept = FALSE)
  on.exit(close(setter_builder), add = TRUE)
  expect_invisible(set_include_intercept(setter_builder, FALSE))
  setter_model <- fit(setter_builder, x, y)
  on.exit(close(setter_model), add = TRUE)

  expect_equal(
    predict(setter_model, x),
    expected_without_intercept,
    tolerance = 1e-9
  )
})

test_that("with_mean and with_std toggles change the scaler output", {
  x <- matrix(c(2.0, 4.0, 6.0, 10.0, 20.0, 30.0), nrow = 3, ncol = 2)

  # Centering disabled, scaling enabled: divide by the population standard
  # deviation without subtracting the column mean.
  only_scale_builder <- sk_standard_scaler(with_mean = FALSE, with_std = TRUE)
  on.exit(close(only_scale_builder), add = TRUE)
  only_scale <- fit(only_scale_builder, x)
  on.exit(close(only_scale), add = TRUE)

  population_sd <- function(column) sqrt(mean((column - mean(column))^2))
  expected_only_scale <- cbind(
    x[, 1] / population_sd(x[, 1]),
    x[, 2] / population_sd(x[, 2])
  )
  expect_equal(transform(only_scale, x), expected_only_scale, tolerance = 1e-9)

  # Both toggles disabled: the identity transformation.
  identity_builder <- sk_standard_scaler(with_mean = FALSE, with_std = FALSE)
  on.exit(close(identity_builder), add = TRUE)
  expect_invisible(set_with_mean(identity_builder, FALSE))
  expect_invisible(set_with_std(identity_builder, FALSE))
  identity_scaler <- fit(identity_builder, x)
  on.exit(close(identity_scaler), add = TRUE)

  expect_equal(transform(identity_scaler, x), x, tolerance = 1e-12)
})
