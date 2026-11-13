# Installation

`sciencekitr` lives in its own repository ([`neurono-ml/sciencekit-r`](https://github.com/neurono-ml/sciencekit-r)) and links against the `sciencekit_ffi` static archive built from [`neurono-ml/sciencekit`](https://github.com/neurono-ml/sciencekit).

## Prerequisites

- **Rust 1.85+** (`rustup toolchain install 1.85`) to compile `crates/sciencekit_ffi` from the main repository.
- **R 4.1+** with C compilation headers (`r-base` and `r-base-dev` on Debian/Ubuntu).
- **`testthat` (>= 3.0.0)** to run the test suite (`r-cran-testthat` or `install.packages("testthat")`).

## Why a Vendored Header + Static Archive?

Because `sciencekit_ffi` is not yet published on crates.io, `sciencekit-r` pairs two reproducible scripts:

1. `scripts/sync-header.sh` copies `crates/sciencekit_ffi/include/sciencekit.h` into `src/sciencekit.h` so the C shim compiles against the exact ABI header from `neurono-ml/sciencekit`.
2. `scripts/build-native-library.sh` runs `cargo build -p sciencekit_ffi --release` and installs `libsciencekit_ffi.a` into `tools/native/libsciencekit_ffi.a`. `src/Makevars` links that archive directly into `sciencekitr.so`, so the installed R package requires **no `LD_LIBRARY_PATH` configuration** and **no non-portable `-Wl,-rpath` flags**.

## Step-by-Step Build & Install

```bash
# 1. Clone both repositories side by side
git clone https://github.com/neurono-ml/sciencekit.git
git clone https://github.com/neurono-ml/sciencekit-r.git
cd sciencekit-r

# 2. Sync the ABI header and build libsciencekit_ffi.a
scripts/sync-header.sh ../sciencekit
scripts/build-native-library.sh ../sciencekit

# 3. Build and install the R package
R CMD build .
R CMD INSTALL sciencekitr_0.1.0.tar.gz
```

## Verifying the Installation

Start R and verify the loaded ABI version and feature flags (derived from `tests/testthat/test-load-and-registration.R`):

```r
library(sciencekitr)

abi_version()
#> major minor patch
#>     1     0     0

abi_features()
#> linear_regression   standard_scaler model_persistence               f32               f64
#>              TRUE              TRUE              TRUE              TRUE              TRUE
```

## Running the Full Check Suite

```bash
R CMD build .
R CMD check .
```

The source tarball deliberately excludes `tools/native/`: the static Rust archive is a
build artifact, not source, and shipping it would make the tarball ~10 MB and raise an
`R CMD check` NOTE. Point the tarball check at the archive built in the checkout:

```bash
SCIENCEKIT_LIB_DIR="$PWD/tools/native" R CMD check --no-manual sciencekitr_*.tar.gz
```

`R CMD check .` on the source directory still works without the variable because
`src/Makevars` defaults `SCIENCEKIT_LIB_DIR` to `../tools/native`. The single remaining
NOTE is the installed size of the statically linked `sciencekitr.so`.

To use a custom location for `libsciencekit_ffi.a` without copying it into `tools/native/`, set `SCIENCEKIT_LIB_DIR` before invoking `R CMD INSTALL` or `R CMD check`:

```bash
SCIENCEKIT_LIB_DIR=/path/to/sciencekit/target/release R CMD INSTALL .
```
