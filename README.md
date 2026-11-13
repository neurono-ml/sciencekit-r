# sciencekit-r (`sciencekitr`)

[![R-CMD-check](https://github.com/neurono-ml/sciencekit-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/neurono-ml/sciencekit-r/actions/workflows/R-CMD-check.yaml)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://neurono-ml.github.io/sciencekit-r/)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

Idiomatic R bindings (`sciencekitr`) for the [`sciencekit`](https://github.com/neurono-ml/sciencekit) machine-learning library over its stable `sciencekit_ffi` C ABI.

Full documentation is published at **<https://neurono-ml.github.io/sciencekit-r/>**.

## Architecture & Native ABI Choice

Because `sciencekit_ffi` is not yet published on crates.io, `sciencekit-r` uses **a vendored C ABI header plus a documented native build step**:

1. **Vendored C ABI header (`src/sciencekit.h`):** synchronized directly from `crates/sciencekit_ffi/include/sciencekit.h` in `neurono-ml/sciencekit` via `scripts/sync-header.sh` so compilation never drifts from the target ABI.
2. **Static native archive (`tools/native/libsciencekit_ffi.a`):** built from a checkout of `neurono-ml/sciencekit` via `scripts/build-native-library.sh` (`cargo build -p sciencekit_ffi --release`) and linked statically into `sciencekitr.so` through `src/Makevars`. No external `LD_LIBRARY_PATH` or non-portable `rpath` flags are needed at runtime.
3. **Registered `.Call` C shim (`src/init.c`, `src/sciencekitr.c`):** native entry points are registered with `R_registerRoutines()`, `R_useDynamicSymbols(dll, FALSE)`, and `R_forceSymbols(dll, TRUE)`, and exposed to R via `useDynLib(sciencekitr, .registration = TRUE)`.

## Building & Running Checks

Clone `neurono-ml/sciencekit` next to `sciencekit-r`, build the native library, and run `R CMD build .` and `R CMD check .`:

```bash
git clone https://github.com/neurono-ml/sciencekit.git ../sciencekit
scripts/sync-header.sh ../sciencekit
scripts/build-native-library.sh ../sciencekit

R CMD build .
R CMD check .
```

The source tarball excludes `tools/native/` (the 37 MB static Rust archive is a build
artifact, not source), so checking the tarball requires pointing the compiler at the
checkout's archive:

```bash
SCIENCEKIT_LIB_DIR="$PWD/tools/native" R CMD check --no-manual sciencekitr_*.tar.gz
```

`R CMD check .` on the source directory still works without the variable because
`src/Makevars` defaults `SCIENCEKIT_LIB_DIR` to `../tools/native`.

## Quick Example

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

builder <- sk_linear_regression(include_intercept = TRUE, backend = "faer")
model <- fit(builder, x, y)

predict(model, x)
#> [1]  1  3  4 14
score(model, x, y)
#> [1] 1

close(model)
close(builder)
```

## Key Guarantees

- **Lifecycle safety:** every builder and fitted model wraps an R external pointer with both a garbage-collector C finalizer (`R_RegisterCFinalizerEx`) and an explicit, idempotent `close()` S3 method. Operations on closed handles raise a `sciencekit_error` with status `"invalid-handle"` (`1L`) without touching freed memory.
- **Strict `f64`-only dense conversion:** R column-major `double` matrices and rectangular `double` data frames are validated and transposed cleanly to and from row-major C buffers. Integer, logical, character, ragged, and `f32` inputs are rejected explicitly rather than silently coerced.
- **Structured conditions:** every failure raises an S3 condition inheriting from `sciencekit_error` with `status`, `status_code`, `operation`, `native_message`, and `message`.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
