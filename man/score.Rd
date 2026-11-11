\name{score}
\alias{score}
\title{Score a Fitted sciencekit Model Against Targets}
\description{
Computes the estimator's native evaluation metric (coefficient of determination
\eqn{R^2} for linear regression) on a feature matrix and ground-truth target
vector.
}
\usage{
score(model, x, y)
}
\arguments{
  \item{model}{An open \code{sciencekit_model} object.}
  \item{x}{A rectangular \code{double} (\code{f64}) matrix or data frame.}
  \item{y}{A \code{double} (\code{f64}) target vector of length \code{nrow(x)}.}
}
\value{
A scalar \code{double} score.
}
\examples{
x <- matrix(c(0, 1, 0, 2, 0, 0, 1, 3), nrow = 4, ncol = 2)
y <- c(1, 3, 4, 14)
builder <- sk_linear_regression()
model <- fit(builder, x, y)
score(model, x, y)
close(model)
close(builder)
}
