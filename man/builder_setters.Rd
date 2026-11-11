\name{builder_setters}
\alias{set_include_intercept}
\alias{set_with_mean}
\alias{set_with_std}
\alias{set_backend}
\title{Configure Options on a sciencekit Builder}
\description{
Update hyperparameter or math-backend settings on an open
\code{sciencekit_builder} handle.
}
\usage{
set_include_intercept(builder, enabled)

set_with_mean(builder, enabled)

set_with_std(builder, enabled)

set_backend(builder, backend)
}
\arguments{
  \item{builder}{An open \code{sciencekit_builder} object.}
  \item{enabled}{Logical scalar (\code{TRUE} or \code{FALSE}).}
  \item{backend}{Character scalar (\code{"faer"}, \code{"matrix_multiply"}, or
    \code{"ndarray_linalg"}).}
}
\value{
Invisibly returns \code{builder}.
}
\examples{
builder <- sk_builder("linear_regression")
set_include_intercept(builder, TRUE)
set_backend(builder, "faer")
close(builder)
}
