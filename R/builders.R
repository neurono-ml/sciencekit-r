# Estimator builders and configuration setters.

SK_FAMILY_CODES <- c(
  linear_regression = 0L,
  standard_scaler = 1L
)

SK_BACKEND_CODES <- c(
  faer = 0L,
  matrix_multiply = 1L,
  ndarray_linalg = 2L
)

resolve_family_code <- function(family, operation) {
  if (!is.character(family) || length(family) != 1L || is.na(family)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      "`family` must be a non-missing character scalar"
    )
  }
  idx <- match(family, names(SK_FAMILY_CODES))
  if (is.na(idx)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      sprintf(
        "unknown estimator family '%s'; supported families: %s",
        family,
        paste(names(SK_FAMILY_CODES), collapse = ", ")
      )
    )
  }
  SK_FAMILY_CODES[[idx]]
}

resolve_backend_code <- function(backend, operation) {
  if (!is.character(backend) || length(backend) != 1L || is.na(backend)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      "`backend` must be a non-missing character scalar"
    )
  }
  idx <- match(backend, names(SK_BACKEND_CODES))
  if (is.na(idx)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      sprintf(
        "unknown backend '%s'; supported backends: %s",
        backend,
        paste(names(SK_BACKEND_CODES), collapse = ", ")
      )
    )
  }
  SK_BACKEND_CODES[[idx]]
}

require_logical_flag <- function(value, name, operation) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      sprintf("`%s` must be TRUE or FALSE", name)
    )
  }
  value
}

require_builder <- function(builder, operation) {
  if (!inherits(builder, "sciencekit_builder")) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      operation,
      "expected a `sciencekit_builder` object"
    )
  }
  builder
}

#' Create a sciencekit estimator builder
#'
#' Constructs an opaque native builder wrapped in an R external pointer with an
#' automatic garbage-collector finalizer and explicit [close()] support. The R
#' binding enforces `f64`-only (`double`) numeric semantics.
#'
#' @param family Character scalar: `"linear_regression"` or `"standard_scaler"`.
#' @param dtype Character scalar; must be `"f64"`. Passing `"f32"` or any other
#'   scalar type raises a `sciencekit_error` condition.
#' @param include_intercept Optional logical scalar for `"linear_regression"`.
#' @param with_mean Optional logical scalar for `"standard_scaler"`.
#' @param with_std Optional logical scalar for `"standard_scaler"`.
#' @param backend Character scalar selecting the math backend: `"faer"`
#'   (default), `"matrix_multiply"`, or `"ndarray_linalg"`.
#' @return An object of class `"sciencekit_builder"`.
#' @export
sk_builder <- function(
  family,
  dtype = "f64",
  include_intercept = NULL,
  with_mean = NULL,
  with_std = NULL,
  backend = "faer"
) {
  if (!is.character(dtype) || length(dtype) != 1L || is.na(dtype)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      "builder_create",
      "`dtype` must be the character scalar 'f64'"
    )
  }
  if (dtype != "f64") {
    raise_sciencekit_error(
      SK_STATUS_UNSUPPORTED,
      "builder_create",
      sprintf("only 'f64' (double) semantics are supported in R; received dtype '%s'", dtype)
    )
  }

  family_code <- resolve_family_code(family, "builder_create")
  backend_code <- resolve_backend_code(backend, "builder_create")

  ptr <- unwrap_result(
    .Call(C_sciencekit_builder_create, family_code, 1L),
    "builder_create"
  )

  builder <- structure(
    list(
      ptr = ptr,
      family = family,
      dtype = "f64",
      backend = backend
    ),
    class = "sciencekit_builder"
  )

  tryCatch(
    {
      unwrap_result(
        .Call(C_sciencekit_builder_set_backend, builder$ptr, backend_code),
        "builder_set_backend"
      )
      if (!is.null(include_intercept)) {
        set_include_intercept(builder, include_intercept)
      }
      if (!is.null(with_mean)) {
        set_with_mean(builder, with_mean)
      }
      if (!is.null(with_std)) {
        set_with_std(builder, with_std)
      }
    },
    error = function(err) {
      close(builder)
      stop(err)
    }
  )

  builder
}

#' Create an ordinary-least-squares linear-regression builder
#'
#' @param include_intercept Logical scalar indicating whether to fit an
#'   intercept term (default `TRUE`).
#' @param backend Character scalar naming the math backend (default `"faer"`).
#' @return An object of class `"sciencekit_builder"`.
#' @export
sk_linear_regression <- function(include_intercept = TRUE, backend = "faer") {
  sk_builder(
    family = "linear_regression",
    dtype = "f64",
    include_intercept = include_intercept,
    backend = backend
  )
}

#' Create a standard-scaler builder
#'
#' @param with_mean Logical scalar indicating whether to center columns by their
#'   sample mean (default `TRUE`).
#' @param with_std Logical scalar indicating whether to scale columns by their
#'   standard deviation (default `TRUE`).
#' @param backend Character scalar naming the math backend (default `"faer"`).
#' @return An object of class `"sciencekit_builder"`.
#' @export
sk_standard_scaler <- function(with_mean = TRUE, with_std = TRUE, backend = "faer") {
  sk_builder(
    family = "standard_scaler",
    dtype = "f64",
    with_mean = with_mean,
    with_std = with_std,
    backend = backend
  )
}

#' Configure builder options
#'
#' @param builder A `sciencekit_builder` object.
#' @param enabled Logical scalar (`TRUE` or `FALSE`).
#' @param backend Character scalar (`"faer"`, `"matrix_multiply"`, or
#'   `"ndarray_linalg"`).
#' @return The modified `builder` (invisibly).
#' @name builder_setters
#' @export
set_include_intercept <- function(builder, enabled) {
  require_builder(builder, "builder_set_include_intercept")
  flag <- require_logical_flag(enabled, "enabled", "builder_set_include_intercept")
  unwrap_result(
    .Call(C_sciencekit_builder_set_include_intercept, builder$ptr, flag),
    "builder_set_include_intercept"
  )
  invisible(builder)
}

#' @rdname builder_setters
#' @export
set_with_mean <- function(builder, enabled) {
  require_builder(builder, "builder_set_with_mean")
  flag <- require_logical_flag(enabled, "enabled", "builder_set_with_mean")
  unwrap_result(
    .Call(C_sciencekit_builder_set_with_mean, builder$ptr, flag),
    "builder_set_with_mean"
  )
  invisible(builder)
}

#' @rdname builder_setters
#' @export
set_with_std <- function(builder, enabled) {
  require_builder(builder, "builder_set_with_std")
  flag <- require_logical_flag(enabled, "enabled", "builder_set_with_std")
  unwrap_result(
    .Call(C_sciencekit_builder_set_with_std, builder$ptr, flag),
    "builder_set_with_std"
  )
  invisible(builder)
}

#' @rdname builder_setters
#' @export
set_backend <- function(builder, backend) {
  require_builder(builder, "builder_set_backend")
  code <- resolve_backend_code(backend, "builder_set_backend")
  unwrap_result(
    .Call(C_sciencekit_builder_set_backend, builder$ptr, code),
    "builder_set_backend"
  )
  builder$backend <- backend
  invisible(builder)
}

#' @export
print.sciencekit_builder <- function(x, ...) {
  state <- if (is_closed(x)) "closed" else "open"
  cat(sprintf("<sciencekit_builder family='%s' dtype='%s' state='%s'>\n", x$family, x$dtype, state))
  invisible(x)
}
