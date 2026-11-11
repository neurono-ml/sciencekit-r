\name{sk_builder}
\alias{sk_builder}
\alias{sk_linear_regression}
\alias{sk_standard_scaler}
\title{Create sciencekit Estimator Builders}
\description{
Construct opaque native estimator builders over the \code{sciencekit_ffi} C ABI
with double-precision (\code{f64}) semantics.
}
\usage{
sk_builder(
  family,
  dtype = "f64",
  include_intercept = NULL,
  with_mean = NULL,
  with_std = NULL,
  backend = "faer"
)

sk_linear_regression(include_intercept = TRUE, backend = "faer")

sk_standard_scaler(with_mean = TRUE, with_std = TRUE, backend = "faer")
}
\arguments{
  \item{family}{Character scalar naming the estimator family:
    \code{"linear_regression"} or \code{"standard_scaler"}.}
  \item{dtype}{Character scalar; must be \code{"f64"}. Any other value raises a
    \code{sciencekit_error} condition.}
  \item{include_intercept}{Logical scalar configuring whether linear regression
    fits an intercept term.}
  \item{with_mean}{Logical scalar configuring whether the standard scaler
    centers each feature by its sample mean.}
  \item{with_std}{Logical scalar configuring whether the standard scaler divides
    each feature by its population standard deviation.}
  \item{backend}{Character scalar selecting the math backend: \code{"faer"},
    \code{"matrix_multiply"}, or \code{"ndarray_linalg"}.}
}
\value{
An S3 object of class \code{"sciencekit_builder"}.
}
\examples{
reg <- sk_linear_regression(include_intercept = TRUE)
close(reg)

scaler <- sk_standard_scaler(with_mean = TRUE, with_std = TRUE)
close(scaler)
}
