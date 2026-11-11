\name{sk_transform}
\alias{sk_transform}
\alias{transform.sciencekit_model}
\title{Transform Features with a Fitted sciencekit Transformer}
\description{
Applies a fitted transformer model (such as a standard scaler) to a rectangular
double-precision (\code{f64}) feature matrix. Both \code{transform(model, x)}
and \code{sk_transform(model, x)} are supported.
}
\usage{
sk_transform(model, x)

\method{transform}{sciencekit_model}(`_data`, ...)
}
\arguments{
  \item{model}{An open \code{sciencekit_model} transformer.}
  \item{x}{A rectangular \code{double} (\code{f64}) matrix or data frame.}
  \item{_data}{An open \code{sciencekit_model} transformer when dispatched via
    \code{\link[base]{transform}}.}
  \item{...}{Positional arguments; the first argument is the feature matrix
    \code{x}.}
}
\value{
A \code{double} matrix of transformed features with \code{nrow(x)} rows.
}
\examples{
x <- matrix(c(1, 2, 3, 4, 10, 20, 30, 40), nrow = 4, ncol = 2)
builder <- sk_standard_scaler()
scaler <- fit(builder, x)
transform(scaler, x)
close(scaler)
close(builder)
}
