\name{print.sciencekit}
\alias{print.sciencekit_builder}
\alias{print.sciencekit_model}
\title{Print sciencekit Builders and Models}
\description{
Displays a compact summary of a \code{sciencekit_builder} or
\code{sciencekit_model}, including its estimator family, scalar type, and handle
state (\code{open} or \code{closed}).
}
\usage{
\method{print}{sciencekit_builder}(x, ...)

\method{print}{sciencekit_model}(x, ...)
}
\arguments{
  \item{x}{A \code{sciencekit_builder} or \code{sciencekit_model} object.}
  \item{...}{Unused arguments passed to or from other methods.}
}
\value{
Invisibly returns \code{x}.
}
\examples{
b <- sk_linear_regression()
print(b)
close(b)
}
