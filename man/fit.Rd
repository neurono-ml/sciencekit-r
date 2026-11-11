\name{fit}
\alias{fit}
\title{Fit a sciencekit Estimator Builder on Dense Data}
\description{
Fits an open \code{sciencekit_builder} on a rectangular double-precision
(\code{f64}) design matrix and optional target vector.
}
\usage{
fit(builder, x, y = NULL)
}
\arguments{
  \item{builder}{An open \code{sciencekit_builder} object.}
  \item{x}{A rectangular \code{double} (\code{f64}) matrix or data frame.}
  \item{y}{Optional \code{double} (\code{f64}) vector of target values with
    length \code{nrow(x)} (required for supervised estimators, \code{NULL} for
    unsupervised transformers).}
}
\value{
An S3 object of class \code{"sciencekit_model"} owning the fitted native model
handle.
}
\examples{
x <- matrix(c(0, 1, 0, 2, 0, 0, 1, 3), nrow = 4, ncol = 2)
y <- c(1, 3, 4, 14)
builder <- sk_linear_regression()
model <- fit(builder, x, y)
close(model)
close(builder)
}
