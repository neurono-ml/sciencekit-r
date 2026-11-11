# Errors and Status Codes

Every failure in `sciencekitr` — whether caught during R-side input validation or returned by the `sciencekit_ffi` C ABI — raises a structured R condition inheriting from `sciencekit_error`.

The C shim never calls `Rf_error()` while holding heap-allocated buffers or ABI array descriptors. Instead, it releases temporary C buffers immediately, reads `sk_ffi_status_name()` and `sk_ffi_last_error()`, and returns a tagged failure list to R, where `unwrap_result()` constructs and signals the condition.

## Condition Structure

Every `sciencekit_error` condition carries:

| Field | Type | Description |
|---|---|---|
| `message` | `character(1)` | Formatted diagnostic string containing the status name, code, operation, and native message |
| `status` | `character(1)` | Stable lowercase ABI status name from `sk_ffi_status_name()` |
| `status_code` | `integer(1)` | Numeric `SKFfiStatus` discriminant (`1L`–`7L`) |
| `operation` | `character(1)` | Failing operation (`"fit"`, `"predict"`, `"transform"`, `"score"`, `"save"`, `"load"`, etc.) |
| `native_message` | `character(1)` | Unprefixed diagnostic message |

Each condition also carries a specific S3 subclass `sciencekit_error_<status_with_underscores>` (for example, `sciencekit_error_invalid_handle` or `sciencekit_error_shape`) ahead of `"sciencekit_error"`, `"error"`, and `"condition"`.

## Stable Status Table

| Status Code | `status` Name | Condition Subclass | Typical Cause |
|---|---|---|---|
| `1L` | `"invalid-handle"` | `sciencekit_error_invalid_handle` | Operation called on a closed or invalid handle |
| `2L` | `"shape"` | `sciencekit_error_shape` | Ragged data frame, `nrow(x) != length(y)`, or wrong feature count |
| `3L` | `"invalid-argument"` | `sciencekit_error_invalid_argument` | Non-`double` matrix, empty matrix, `NaN`/`Inf` values, invalid option |
| `4L` | `"unsupported"` | `sciencekit_error_unsupported` | `dtype = "f32"`, `transform()` on regressor, `save_model()` on scaler |
| `5L` | `"not-fitted"` | `sciencekit_error_not_fitted` | Unfitted state reported by the ABI |
| `6L` | `"io"` | `sciencekit_error_io` | Missing or unreadable file path in `save_model()` / `load_model()` |
| `7L` | `"internal"` | `sciencekit_error_internal` | Allocation failure or caught Rust panic across the FFI boundary |

## Inspecting Conditions in `tryCatch()`

Derived from `tests/testthat/test-errors-and-lifecycle.R`:

```r
library(sciencekitr)

x <- matrix(c(0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 3.0), nrow = 4, ncol = 2)
y <- c(1.0, 3.0, 4.0, 14.0)

builder <- sk_linear_regression()
model <- fit(builder, x, y)

# Linear regression does not support transform()
err <- tryCatch(transform(model, x), error = identity)

inherits(err, "sciencekit_error")
#> [1] TRUE
err$status
#> [1] "unsupported"
err$status_code
#> [1] 4
err$operation
#> [1] "transform"
nzchar(err$native_message)
#> [1] TRUE

close(model)
close(builder)
```
