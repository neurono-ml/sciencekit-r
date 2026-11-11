# ABI introspection and handle lifecycle helpers.

#' Query the loaded sciencekit C ABI version
#'
#' @return A named integer vector with elements `major`, `minor` and `patch`.
#' @export
abi_version <- function() {
  unwrap_result(.Call(C_sciencekit_version), "version")
}

#' Query the capability flags advertised by the sciencekit C ABI
#'
#' @return A named logical vector describing the supported estimator families,
#'   model persistence, and scalar types in the underlying native library.
#' @export
abi_features <- function() {
  unwrap_result(.Call(C_sciencekit_features), "features")
}

#' Inspect live native handle counts
#'
#' Returns the number of currently allocated native builder and fitted-model
#' handles owned by this R session. Useful for verifying handle release and
#' leak-free error paths.
#'
#' @return A named integer vector with elements `builders` and `models`.
#' @export
live_handle_counts <- function() {
  .Call(C_sciencekit_live_counts)
}

#' Test whether a sciencekit handle has been closed
#'
#' @param x A `sciencekit_builder` or `sciencekit_model` object.
#' @return `TRUE` if the underlying native handle has been released, `FALSE`
#'   otherwise.
#' @export
is_closed <- function(x) {
  if (!inherits(x, c("sciencekit_builder", "sciencekit_model"))) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      "is_closed",
      "expected a `sciencekit_builder` or `sciencekit_model` object"
    )
  }
  isTRUE(.Call(C_sciencekit_handle_is_closed, x$ptr))
}

#' Release a native sciencekit builder or model handle
#'
#' Explicitly frees the underlying C ABI handle before garbage collection.
#' Calling `close()` more than once on the same object is a safe, idempotent
#' no-op.
#'
#' @param con A `sciencekit_builder` or `sciencekit_model` object.
#' @param ... Unused; present for compatibility with [base::close()].
#' @return Invisibly returns `TRUE` if this call released the handle, or `FALSE`
#'   if it was already closed.
#' @name close.sciencekit
#' @export
close.sciencekit_builder <- function(con, ...) {
  released <- unwrap_result(.Call(C_sciencekit_handle_close, con$ptr), "close")
  invisible(released)
}

#' @rdname close.sciencekit
#' @export
close.sciencekit_model <- function(con, ...) {
  released <- unwrap_result(.Call(C_sciencekit_handle_close, con$ptr), "close")
  invisible(released)
}
