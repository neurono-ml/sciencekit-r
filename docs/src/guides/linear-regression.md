# Linear Regression

`sk_linear_regression()` (or `sk_builder("linear_regression", ...)`) configures an ordinary-least-squares regressor backed by `sciencekit_linear_model` via `sciencekit_ffi`.

## Creating and Configuring the Builder

```r
library(sciencekitr)

builder <- sk_linear_regression(
  include_intercept = TRUE,
  backend = "faer"
)
```

You can also mutate an open builder in place before calling `fit()`:

```r
builder <- sk_builder("linear_regression")
set_include_intercept(builder, TRUE)
set_backend(builder, "matrix_multiply")
```

Supported math backends match `SKFfiBackendKind`:

- `"faer"` (default)
- `"matrix_multiply"`
- `"ndarray_linalg"`

## Fitting, Predicting, and Scoring

From `tests/testthat/test-linear-regression.R`:

```r
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
stopifnot(all.equal(preds, y, tolerance = 1e-9))

r2 <- score(model, x, y)
stopifnot(all.equal(r2, 1.0, tolerance = 1e-9))
```

## Using Rectangular Double Data Frames

`fit()`, `predict()`, and `score()` also accept rectangular `data.frame` inputs when every column has `double` storage:

```r
df <- data.frame(
  x1 = c(1.0, 2.0, 3.0, 4.0, 5.0),
  x2 = c(2.0, 1.0, 4.0, 3.0, 5.0)
)
y <- 0.5 + 1.5 * df$x1 - 2.0 * df$x2

builder <- sk_linear_regression(include_intercept = TRUE, backend = "faer")
model <- fit(builder, df, y)

predict(model, df)
score(model, df, y)

close(model)
close(builder)
```
