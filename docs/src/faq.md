# Frequently Asked Questions

## Why is the R package named `sciencekitr` in `neurono-ml/sciencekit-r`?

R package names must be alphanumeric (`[A-Za-z0-9.]`) and cannot contain hyphens, so `sciencekit-r` becomes `sciencekitr` in `DESCRIPTION`, `NAMESPACE`, and `library(sciencekitr)`.

## Why does `fit(builder, matrix(1:4, nrow = 2), ...)` raise an error instead of converting integers to doubles?

In R, `1:4` produces an `integer` vector (`INTSXP`), whereas `c(1, 2, 3, 4)` produces a `double` vector (`REALSXP`). Silent coercion hides accidental integer truncation, factor codes, or logical masks. Convert explicitly with `storage.mode(m) <- "double"` or `as.numeric()` before calling `fit()`, `predict()`, `transform()`, or `score()`.

## Do I have to call `close()` on every builder and model?

Calling `close()` is optional for correctness because every external pointer registers a C finalizer (`R_RegisterCFinalizerEx(..., TRUE)`) that frees the native handle when R garbage-collects the object or exits. Calling `close()` explicitly (for example via `on.exit(close(model), add = TRUE)`) is recommended in tight loops or large workflows so Rust memory is reclaimed immediately rather than waiting for the next GC cycle.

## Why does `save_model()` reject a fitted `standard_scaler`?

`sciencekitr` delegates persistence directly to `sk_ffi_model_save` in `sciencekit_ffi`, which currently supports `f64` linear-regression models and returns `SK_FFI_STATUS_UNSUPPORTED` (`4L`) for other families. As additional families gain persistence in `sciencekit_ffi`, `save_model()` and `load_model()` inherit them automatically.

## Does `sciencekitr` require `LD_LIBRARY_PATH` at runtime?

No. `scripts/build-native-library.sh` installs the static archive `libsciencekit_ffi.a` into `tools/native/`, and `src/Makevars` links it directly into `sciencekitr.so`.
