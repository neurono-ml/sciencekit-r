# Fitting, inference, scoring and persistence for sciencekit models.

require_model <- function(model, operation) {
  if (!inherits(model, "sciencekit_model")) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      operation,
      "expected a `sciencekit_model` object"
    )
  }
  model
}

require_path <- function(path, operation) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      "`path` must be a non-empty character scalar"
    )
  }
  path
}

#' Fit a sciencekit estimator builder on dense data
#'
#' @param builder A `sciencekit_builder` object.
#' @param x A rectangular `double` (`f64`) matrix or data frame of features.
#' @param y Optional `double` (`f64`) target vector (required for supervised
#'   estimators such as `"linear_regression"`, `NULL` for unsupervised
#'   transformers such as `"standard_scaler"`).
#' @return A fitted object of class `"sciencekit_model"`.
#' @export
fit <- function(builder, x, y = NULL) {
  require_builder(builder, "fit")
  if (is_closed(builder)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      "fit",
      "invalid handle: the builder handle has already been closed"
    )
  }
  features <- validate_features(x, "fit")
  targets <- if (is.null(y)) {
    NULL
  } else {
    validate_targets(y, nrow(features), "fit")
  }

  model_ptr <- unwrap_result(
    .Call(C_sciencekit_fit, builder$ptr, features, targets),
    "fit"
  )

  structure(
    list(
      ptr = model_ptr,
      family = builder$family,
      dtype = "f64",
      n_features = ncol(features)
    ),
    class = "sciencekit_model"
  )
}

#' Predict responses with a fitted sciencekit model
#'
#' @param object A fitted `sciencekit_model` object.
#' @param newdata A rectangular `double` (`f64`) matrix or data frame of
#'   features.
#' @param ... Unused; present for compatibility with [stats::predict()].
#' @return A `double` vector of length `nrow(newdata)`.
#' @export
predict.sciencekit_model <- function(object, newdata, ...) {
  require_model(object, "predict")
  if (missing(newdata)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      "predict",
      "missing `newdata` feature matrix"
    )
  }
  if (is_closed(object)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      "predict",
      "invalid handle: the model handle has already been closed"
    )
  }
  features <- validate_features(newdata, "predict")
  unwrap_result(.Call(C_sciencekit_predict, object$ptr, features), "predict")
}

#' Transform a feature matrix with a fitted sciencekit transformer
#'
#' @param model A fitted `sciencekit_model` object (such as a standard scaler).
#' @param x A rectangular `double` (`f64`) matrix or data frame of features.
#' @param _data A fitted `sciencekit_model` object when called through
#'   [base::transform()].
#' @param ... Additional arguments; the first positional argument to
#'   `transform(model, x)` is the feature matrix `x`.
#' @return A `double` matrix with the transformed features.
#' @export
sk_transform <- function(model, x) {
  require_model(model, "transform")
  if (is_closed(model)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      "transform",
      "invalid handle: the model handle has already been closed"
    )
  }
  features <- validate_features(x, "transform")
  unwrap_result(.Call(C_sciencekit_transform, model$ptr, features), "transform")
}

#' @rdname sk_transform
#' @export
transform.sciencekit_model <- function(`_data`, ...) {
  dots <- list(...)
  if (length(dots) < 1L) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      "transform",
      "missing feature matrix `x`"
    )
  }
  sk_transform(`_data`, dots[[1L]])
}

#' Score a fitted sciencekit model against known targets
#'
#' Computes the estimator's native evaluation metric (for linear regression,
#' the coefficient of determination \eqn{R^2}).
#'
#' @param model A fitted `sciencekit_model` object.
#' @param x A rectangular `double` (`f64`) matrix or data frame of features.
#' @param y A `double` (`f64`) vector of ground-truth targets with length
#'   `nrow(x)`.
#' @return A scalar `double` score.
#' @export
score <- function(model, x, y) {
  require_model(model, "score")
  if (is_closed(model)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      "score",
      "invalid handle: the model handle has already been closed"
    )
  }
  features <- validate_features(x, "score")
  targets <- validate_targets(y, nrow(features), "score")
  unwrap_result(.Call(C_sciencekit_score, model$ptr, features, targets), "score")
}

#' Save and load fitted sciencekit models
#'
#' Persists fitted model state through the stable `sciencekit_ffi` interop
#' contract. Currently supported for `f64` linear-regression models; unsupported
#' families raise a `sciencekit_error` with status `"unsupported"`.
#'
#' @param model A fitted `sciencekit_model` object.
#' @param path Non-empty character scalar giving the destination or source file
#'   path.
#' @return `save_model()` invisibly returns `path`; `load_model()` returns a new
#'   `sciencekit_model` object.
#' @name model_persistence
#' @export
save_model <- function(model, path) {
  require_model(model, "save")
  if (is_closed(model)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_HANDLE,
      "save",
      "invalid handle: the model handle has already been closed"
    )
  }
  valid_path <- require_path(path, "save")
  unwrap_result(.Call(C_sciencekit_model_save, model$ptr, valid_path), "save")
  invisible(valid_path)
}

#' @rdname model_persistence
#' @export
load_model <- function(path) {
  valid_path <- require_path(path, "load")
  ptr <- unwrap_result(.Call(C_sciencekit_model_load, valid_path), "load")
  structure(
    list(
      ptr = ptr,
      family = "loaded",
      dtype = "f64",
      n_features = NA_integer_
    ),
    class = "sciencekit_model"
  )
}

#' @export
print.sciencekit_model <- function(x, ...) {
  state <- if (is_closed(x)) "closed" else "open"
  cat(sprintf("<sciencekit_model family='%s' dtype='%s' state='%s'>\n", x$family, x$dtype, state))
  invisible(x)
}
