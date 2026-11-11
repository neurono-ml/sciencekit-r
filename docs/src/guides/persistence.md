# Model Persistence

`save_model()` and `load_model()` expose the `sciencekit_ffi` model-state persistence contract (`sk_ffi_model_save` and `sk_ffi_model_load`).

Because R's `base::save()` and `base::load()` are non-generic functions for R workspace serialization, `sciencekitr` names its persistence entry points `save_model(model, path)` and `load_model(path)` so attaching the package never masks base R functions.

## Round-Trip Example

Derived from `tests/testthat/test-persistence.R`:

```r
library(sciencekitr)

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
model <- fit(builder, x, y)
baseline <- predict(model, x)

path <- tempfile(fileext = ".skmodel")
save_model(model, path)
close(model)
close(builder)

restored <- load_model(path)
stopifnot(all.equal(predict(restored, x), baseline, tolerance = 1e-12))
stopifnot(all.equal(score(restored, x, y), 1.0, tolerance = 1e-12))

close(restored)
unlink(path)
```

## Current ABI Scope and Error Handling

Per `sciencekit.h`, native persistence currently covers fitted `f64` linear-regression models:

- Calling `save_model()` on a fitted `standard_scaler` raises a `sciencekit_error` with `status = "unsupported"` and `status_code = 4L`.
- Calling `load_model()` on a missing or unreadable path raises a `sciencekit_error` with `status = "io"` and `status_code = 6L`.

```r
scaler_builder <- sk_standard_scaler()
scaler <- fit(scaler_builder, matrix(c(1.0, 2.0, 3.0, 4.0), nrow = 2))

tryCatch(
  save_model(scaler, tempfile()),
  sciencekit_error = function(err) {
    cat(err$status, err$status_code, "\n")
  }
)
#> unsupported 4

close(scaler)
close(scaler_builder)
```
