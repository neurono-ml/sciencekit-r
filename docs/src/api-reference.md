# API Reference

## Builders and Configuration

### `sk_builder(family, dtype = "f64", include_intercept = NULL, with_mean = NULL, with_std = NULL, backend = "faer")`

Creates a `sciencekit_builder` external-pointer object for `"linear_regression"` or `"standard_scaler"`.

- `family`: `"linear_regression"` or `"standard_scaler"`.
- `dtype`: must be `"f64"`; any other scalar name raises `sciencekit_error` (`status = "unsupported"`, `status_code = 4L`).
- `include_intercept`: optional `logical(1)` for `"linear_regression"`.
- `with_mean`, `with_std`: optional `logical(1)` for `"standard_scaler"`.
- `backend`: `"faer"` (default), `"matrix_multiply"`, or `"ndarray_linalg"`.

### `sk_linear_regression(include_intercept = TRUE, backend = "faer")`

Convenience constructor returning a `sciencekit_builder` for ordinary least squares.

### `sk_standard_scaler(with_mean = TRUE, with_std = TRUE, backend = "faer")`

Convenience constructor returning a `sciencekit_builder` for column-wise standardization.

### Builder Setters

- `set_include_intercept(builder, enabled)`
- `set_with_mean(builder, enabled)`
- `set_with_std(builder, enabled)`
- `set_backend(builder, backend)`

Each setter updates the native `SKFfiBuilder` handle and returns `builder` invisibly.

---

## Fitting, Inference, and Scoring

### `fit(builder, x, y = NULL)`

Fits `builder` on dense `double` features `x` (2D matrix or rectangular `double` data frame) and optional `double` target vector `y`. Returns a `sciencekit_model`.

### `predict(object, newdata, ...)` (`predict.sciencekit_model`)

S3 method for `stats::predict()`. Computes responses for each row of `newdata` and returns a `double` vector of length `nrow(newdata)`.

### `transform(_data, ...)` (`transform.sciencekit_model`) & `sk_transform(model, x)`

Transforms feature matrix `x` using a fitted transformer `sciencekit_model` and returns a `double` matrix with `nrow(x)` rows.

### `score(model, x, y)`

Computes the model's native evaluation metric ($R^2$ for linear regression) as a `double(1)` scalar.

---

## Persistence

### `save_model(model, path)`

Writes a fitted `f64` linear-regression model to `path`. Invisibly returns `path`.

### `load_model(path)`

Loads a persisted model from `path` and returns a `sciencekit_model`.

---

## Lifecycle & Introspection

### `close(con, ...)` (`close.sciencekit_builder`, `close.sciencekit_model`)

S3 methods for `base::close()`. Eagerly and idempotently releases the native handle. Returns `TRUE` invisibly on first release and `FALSE` on subsequent calls.

### `is_closed(x)`

Returns `TRUE` if the underlying native handle of `x` has been released, `FALSE` otherwise.

### `live_handle_counts()`

Returns a named integer vector `c(builders = ..., models = ...)` counting currently active native handles in this R session.

### `abi_version()` & `abi_features()`

Return the linked `sciencekit_ffi` semantic version (`c(major = 1L, minor = 0L, patch = 0L)`) and advertised capability flags.

---

## Printing

### `print(x, ...)` (`print.sciencekit_builder`, `print.sciencekit_model`)

S3 methods for `base::print()`. Both print a one-line summary of the form
`<sciencekit_builder family='...' dtype='f64' state='open|closed'>` and return `x`
invisibly. The `state` field flips to `"closed"` as soon as `close()` releases the
native handle. Runnable examples live in
[Printing and Object Inspection](guides/inspection.md).
