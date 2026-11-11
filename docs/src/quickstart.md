# Quickstart

The example below walks through the core workflow tested in `tests/testthat/test-linear-regression.R` and `tests/testthat/test-standard-scaler.R`: scaling features, fitting an ordinary-least-squares linear regression model, predicting on new rows, scoring $R^2$, persisting the model to disk, and releasing native handles.

## 1. Fit, Predict, and Score Linear Regression

```r
library(sciencekitr)

# Exact linear fixture: y = 1 + 2 * x1 + 3 * x2
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
model <- fit(builder, x, y)

predict(model, x)
#> [1]  1  3  4 14

score(model, x, y)
#> [1] 1

# Out-of-sample rows
x_new <- matrix(c(3.0, 4.0, -1.0, 2.0), nrow = 2, ncol = 2, byrow = TRUE)
predict(model, x_new)
#> [1] 19  5
```

## 2. Save and Reload the Fitted Model

```r
path <- tempfile(fileext = ".skmodel")
save_model(model, path)

# Release the original handle eagerly
close(model)
close(builder)

restored <- load_model(path)
predict(restored, x_new)
#> [1] 19  5

close(restored)
unlink(path)
```

## 3. Standardize Features with `sk_standard_scaler()`

```r
raw_x <- matrix(
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

scaler_builder <- sk_standard_scaler(with_mean = TRUE, with_std = TRUE)
scaler <- fit(scaler_builder, raw_x)

scaled_x <- transform(scaler, raw_x)
dim(scaled_x)
#> [1] 4 2

close(scaler)
close(scaler_builder)
```
