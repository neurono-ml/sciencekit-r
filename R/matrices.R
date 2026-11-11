# Strict f64-only dense matrix and target vector validation.

is_supported_double <- function(x) {
  typeof(x) == "double" && !is.factor(x) && !inherits(x, c("float32", "POSIXt", "Date", "difftime"))
}

describe_element_type <- function(x) {
  if (is.factor(x)) {
    return("factor")
  }
  if (inherits(x, "float32")) {
    return("float32 (f32)")
  }
  typeof(x)
}

validate_features <- function(x, operation) {
  if (is.null(x)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      "features `x` cannot be NULL; expected a rectangular double (f64) matrix"
    )
  }

  if (is.data.frame(x) || (is.list(x) && !is.object(x))) {
    ncols <- length(x)
    if (ncols < 1L) {
      raise_sciencekit_error(
        SK_STATUS_SHAPE,
        operation,
        "features `x` must have at least one column"
      )
    }
    col_lengths <- vapply(x, length, integer(1L))
    if (length(unique(col_lengths)) != 1L) {
      raise_sciencekit_error(
        SK_STATUS_SHAPE,
        operation,
        "features `x` must be rectangular: data frame/list columns have ragged lengths"
      )
    }
    nrows <- col_lengths[[1L]]
    for (j in seq_len(ncols)) {
      col <- x[[j]]
      if (!is.null(dim(col)) && length(dim(col)) > 1L) {
        raise_sciencekit_error(
          SK_STATUS_SHAPE,
          operation,
          sprintf("column %d of `x` is multi-dimensional; expected 1D double columns", j)
        )
      }
      if (!is_supported_double(col)) {
        raise_sciencekit_error(
          SK_STATUS_INVALID_ARGUMENT,
          operation,
          sprintf(
            "only double (f64) matrices are supported; column %d has type '%s'",
            j,
            describe_element_type(col)
          )
        )
      }
    }
    if (nrows < 1L) {
      raise_sciencekit_error(
        SK_STATUS_INVALID_ARGUMENT,
        operation,
        "features `x` must have at least one row"
      )
    }
    mat <- matrix(unlist(x, use.names = FALSE), nrow = nrows, ncol = ncols)
    return(mat)
  }

  dims <- dim(x)
  if (is.null(dims) || length(dims) != 2L) {
    raise_sciencekit_error(
      SK_STATUS_SHAPE,
      operation,
      "features `x` must be a 2D matrix or rectangular data frame of double (f64) values"
    )
  }

  if (!is_supported_double(x)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      sprintf(
        "only double (f64) matrices are supported; received '%s' matrix",
        describe_element_type(x)
      )
    )
  }

  if (dims[[1L]] < 1L || dims[[2L]] < 1L) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      sprintf(
        "features `x` must be non-empty; received shape (%d, %d)",
        dims[[1L]],
        dims[[2L]]
      )
    )
  }

  x
}

validate_targets <- function(y, expected_rows, operation) {
  if (is.null(y)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      "targets `y` cannot be NULL for this operation; expected a double (f64) vector"
    )
  }

  dims <- dim(y)
  if (!is.null(dims)) {
    if (length(dims) == 2L && dims[[2L]] == 1L) {
      if (!is_supported_double(y)) {
        raise_sciencekit_error(
          SK_STATUS_INVALID_ARGUMENT,
          operation,
          sprintf(
            "only double (f64) targets are supported; received '%s'",
            describe_element_type(y)
          )
        )
      }
      y <- as.vector(y)
    } else if (length(dims) >= 2L) {
      raise_sciencekit_error(
        SK_STATUS_SHAPE,
        operation,
        "targets `y` must be a 1D double (f64) vector or single-column matrix"
      )
    }
  }

  if (!is_supported_double(y)) {
    raise_sciencekit_error(
      SK_STATUS_INVALID_ARGUMENT,
      operation,
      sprintf(
        "only double (f64) targets are supported; received '%s'",
        describe_element_type(y)
      )
    )
  }

  if (length(y) != expected_rows) {
    raise_sciencekit_error(
      SK_STATUS_SHAPE,
      operation,
      sprintf(
        "shape mismatch between features (%d rows) and targets (%d elements)",
        expected_rows,
        length(y)
      )
    )
  }

  y
}
