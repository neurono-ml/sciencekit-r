# Standard Scaler

`sk_standard_scaler()` standardizes each feature column independently using population statistics learned during `fit(builder, x)`:

$$z_{i,j} = \frac{x_{i,j} - \mu_j}{\sigma_j}$$

where $\mu_j$ is the column mean (enabled when `with_mean = TRUE`) and $\sigma_j$ is the population standard deviation (enabled when `with_std = TRUE`).

## Fitting and Transforming

Both the S3 method `transform(scaler, x)` (dispatched via `base::transform()`) and the direct helper `sk_transform(scaler, x)` call the same native `sk_ffi_transform` entry point.

Example derived from `tests/testthat/test-standard-scaler.R`:

```r
library(sciencekitr)

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
scaler <- fit(builder, x)

transformed <- transform(scaler, x)
print(transformed)
#>            [,1]       [,2]
#> [1,] -1.3416408 -1.3416408
#> [2,] -0.4472136 -0.4472136
#> [3,]  0.4472136  0.4472136
#> [4,]  1.3416408  1.3416408

# Equivalent explicit call:
identical(transformed, sk_transform(scaler, x))
#> [1] TRUE

close(scaler)
close(builder)
```

## Centering Without Scaling

Toggle `with_mean` and `with_std` either at construction time or via `set_with_mean()` and `set_with_std()`:

```r
x <- matrix(c(2.0, 4.0, 6.0, 10.0, 20.0, 30.0), nrow = 3, ncol = 2)

builder <- sk_standard_scaler(with_mean = TRUE, with_std = FALSE)
scaler <- fit(builder, x)

centered <- transform(scaler, x)
colMeans(centered)
#> [1] 0 0

close(scaler)
close(builder)
```
