# Printing and Object Inspection

Builders and fitted models are ordinary R S3 objects, so `print()` works without
`print()`-specific user code. Both methods report the estimator family, the numeric
dtype and the native handle state, which makes it easy to see whether `close()` has
already released the underlying C ABI handle.

## Printing a Builder

Derived from `tests/testthat/test-print-and-configuration.R`:

```r
library(sciencekitr)

builder <- sk_linear_regression(include_intercept = FALSE)
print(builder)
#> <sciencekit_builder family='linear_regression' dtype='f64' state='open'>

set_include_intercept(builder, FALSE)
print(builder)
#> <sciencekit_builder family='linear_regression' dtype='f64' state='open'>

close(builder)
print(builder)
#> <sciencekit_builder family='linear_regression' dtype='f64' state='closed'>
```

`print()` returns its argument invisibly, so it can be used in the middle of a
pipeline without changing the value.

## Printing a Fitted Model

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

builder <- sk_standard_scaler()
scaler <- fit(builder, x)
print(scaler)
#> <sciencekit_model family='standard_scaler' dtype='f64' state='open'>

close(scaler)
print(scaler)
#> <sciencekit_model family='standard_scaler' dtype='f64' state='closed'>

close(builder)
```

The `state` field reads `"closed"` as soon as `close()` runs, even before the garbage
collector reclaims the R object. See [Handle Lifecycle](lifecycle.md) for the full
release protocol.

## Configuration Toggles and Their Effect

`sk_builder()` accepts the same knobs as the convenience constructors, and the
setters mutate the builder before `fit()`:

```r
builder <- sk_builder("linear_regression", include_intercept = FALSE)
set_include_intercept(builder, FALSE)

model <- fit(builder, x, y)
predict(model, x)
#> [1]  0.000000  2.428571  3.142857 14.285714

close(model)
close(builder)
```

Without an intercept the ordinary-least-squares solution is
$\hat\beta = (X^\top X)^{-1} X^\top y$, so the fixture that is reproduced exactly by
the intercept model is no longer reproduced exactly here. The same numbers are
asserted in `tests/testthat/test-print-and-configuration.R`.

For the scaler, `with_mean` and `with_std` are independent:

```r
x_scaler <- matrix(c(2.0, 4.0, 6.0, 10.0, 20.0, 30.0), nrow = 3, ncol = 2)

only_scale_builder <- sk_standard_scaler(with_mean = FALSE, with_std = TRUE)
only_scale <- fit(only_scale_builder, x_scaler)
transform(only_scale, x_scaler)
#>          [,1]     [,2]
#> [1,] 1.224745 1.224745
#> [2,] 2.449490 2.449490
#> [3,] 3.674235 3.674235

identity_builder <- sk_standard_scaler(with_mean = FALSE, with_std = FALSE)
identity_scaler <- fit(identity_builder, x_scaler)
transform(identity_scaler, x_scaler)
#>      [,1] [,2]
#> [1,]    2   10
#> [2,]    4   20
#> [3,]    6   30

close(identity_scaler)
close(identity_builder)
close(only_scale)
close(only_scale_builder)
```

With both toggles disabled the scaler is the identity transformation; with scaling
only, each column is divided by its population standard deviation without subtracting
the mean.
