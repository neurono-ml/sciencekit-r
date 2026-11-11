# Development Explained: `.Call` Registration & External Pointers

This chapter explains the engineering choices inside `src/init.c` and `src/sciencekitr.c` for readers who want to understand *why* an R binding to a Rust C ABI looks the way `sciencekitr` does.

## 1. Why `.Call` Registration Instead of `dyn.load` Strings?

R has two ways to invoke compiled C routines:

1. **Unregistered dynamic lookup:** calling `dyn.load("foo.so")` and `.Call("some_c_function", ...)`, which asks the operating system's dynamic linker to resolve `"some_c_function"` by name on every call without checking argument counts.
2. **Static routine registration (`R_registerRoutines`):** declaring an `R_CallMethodDef` table in `R_init_<pkg>(DllInfo *dll)` with each routine's exact function pointer and expected `SEXP` argument count, paired with `useDynLib(sciencekitr, .registration = TRUE)` in `NAMESPACE`.

`src/init.c` locks down the shared object with three calls:

```c
void R_init_sciencekitr(DllInfo *dll) {
    R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
```

- `R_registerRoutines` binds every `C_sciencekit_*` symbol into the package namespace as a typed `NativeSymbolInfo` object and checks argument counts at call time.
- `R_useDynamicSymbols(dll, FALSE)` prevents `dlsym` lookups of internal symbols such as `sk_ffi_fit`.
- `R_forceSymbols(dll, TRUE)` rejects string-based `.Call("C_sciencekit_fit", ...)` calls outright, guaranteeing that native code is entered exclusively through the package's validated R wrappers.

## 2. Bridging R's Garbage Collector and Rust's Handle Registry

In `sciencekit_ffi`, `sk_ffi_builder_create()` and `sk_ffi_fit()` return opaque handles (`SKFfiBuilder*` and `SKFfiModel*`) backed by a Rust handle table. Freeing a handle twice returns `SK_FFI_STATUS_INVALID_HANDLE`; forgetting to free a handle leaks its estimator state for the lifetime of the process.

R objects, meanwhile, have value-like copy semantics and non-deterministic garbage collection. If we stored the raw `SKFfiModel*` directly as the address of an `EXTPTRSXP`, we would face a dilemma when a user calls `close(model)` eagerly and the GC finalizer runs later: clearing the external pointer address loses handle metadata, whereas leaving it untouched risks freeing twice.

`src/sciencekitr.c` solves this with a tiny heap-allocated `SKRHandleBox`:

```c
typedef struct SKRHandleBox {
    SKRHandleKind kind;
    void *raw; /* NULL once closed */
} SKRHandleBox;
```

- Both `close()` (`c_sciencekit_handle_close`) and the C finalizer (`c_sciencekit_finalize_handle`) call the **same** `release_handle_box(box)` function.
- `release_handle_box()` checks `if (box == NULL || box->raw == NULL) return SK_FFI_STATUS_OK;`, nulls `box->raw` *before* calling `sk_ffi_builder_free` / `sk_ffi_model_free`, and decrements `live_builders` or `live_models`.
- Only `c_sciencekit_finalize_handle` frees `box` itself when R's garbage collector reclaims the `EXTPTRSXP`.

As a result, `close(x)` can be called zero, one, or ten times in any order relative to `gc()`, and any subsequent `predict(x, ...)` sees `box->raw == NULL` and raises a clean `invalid-handle` error.

## 3. Why the C Shim Never Calls `Rf_error()`

In R's C API, `Rf_error()` performs a C `longjmp` back to the top-level R evaluator, skipping every local C stack frame and leaking any `malloc`'d buffer or `SKFfiArray` output still in flight.

`src/sciencekitr.c` avoids `Rf_error()` completely. Every `.Call` routine frees its temporary `malloc` buffers and `SKFfiArray` outputs first, then returns a small `VECSXP` list (`list(ok = FALSE, status_code = ..., status = ..., message = ...)`). Back in R, `unwrap_result()` turns that failure record into a rich S3 `sciencekit_error` condition via `stop()`. That design is verified directly by the repeated-failure test in `tests/testthat/test-errors-and-lifecycle.R`.
