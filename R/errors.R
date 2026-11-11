# Structured condition constructors and `.Call` result unwrapping.

SK_STATUS_OK <- 0L
SK_STATUS_INVALID_HANDLE <- 1L
SK_STATUS_SHAPE <- 2L
SK_STATUS_INVALID_ARGUMENT <- 3L
SK_STATUS_UNSUPPORTED <- 4L
SK_STATUS_NOT_FITTED <- 5L
SK_STATUS_IO <- 6L
SK_STATUS_INTERNAL <- 7L

new_sciencekit_error <- function(status_code, operation, native_message, call = NULL) {
  code <- as.integer(status_code)
  status_name <- .Call(C_sciencekit_status_name, code)
  formatted <- sprintf(
    "sciencekit %s (%d) in %s: %s",
    status_name,
    code,
    operation,
    native_message
  )
  subclass <- paste0("sciencekit_error_", gsub("-", "_", status_name, fixed = TRUE))
  structure(
    list(
      message = formatted,
      call = call,
      status = status_name,
      status_code = code,
      operation = operation,
      native_message = native_message
    ),
    class = c(subclass, "sciencekit_error", "error", "condition")
  )
}

raise_sciencekit_error <- function(status_code, operation, message, call = sys.call(-1L)) {
  stop(new_sciencekit_error(status_code, operation, message, call = call))
}

unwrap_result <- function(result, operation, call = sys.call(-1L)) {
  if (!isTRUE(result$ok)) {
    stop(
      new_sciencekit_error(
        status_code = result$status_code,
        operation = operation,
        native_message = result$message,
        call = call
      )
    )
  }
  result$value
}
