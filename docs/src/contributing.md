# Contributing

Contributions to `sciencekit-r` follow the same engineering standards as the main [`neurono-ml/sciencekit`](https://github.com/neurono-ml/sciencekit) repository:

1. **English everywhere:** code, comments, Rd files, tests, documentation chapters, commit messages, issues, and pull requests are written in English.
2. **Test-first (`testthat`):** add a failing test under `tests/testthat/` before changing `R/` or `src/`.
3. **ABI fidelity:** never hand-edit `src/sciencekit.h`; always synchronize it from `neurono-ml/sciencekit` with `scripts/sync-header.sh`.
4. **Zero `longjmp` hazards in C:** release all `malloc` buffers and `SKFfiArray` outputs before returning from `.Call`, and surface errors through `err_result()` and `sciencekit_error` conditions.
5. **Documentation in lockstep:** update both the `man/*.Rd` reference files and the mdBook chapters on `docs/documentations` whenever public behavior changes.

## Local Verification Checklist

```bash
# Sync header and build static native library
scripts/sync-header.sh ../sciencekit
scripts/build-native-library.sh ../sciencekit

# Build and check the R package
R CMD build .
R CMD check .

# On the docs/documentations branch: build the book and regenerate sitemap.xml
mdbook build docs
node docs/scripts/postbuild.mjs
```
