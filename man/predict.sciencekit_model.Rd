\name{predict.sciencekit_model}
\alias{predict.sciencekit_model}
\title{Predict Responses with a Fitted sciencekit Model}
\description{
Generates responses for each row of a rectangular double-precision (\code{f64})
feature matrix using a fitted \code{sciencekit_model}.
}
\usage{
\method{predict}{sciencekit_model}(object, newdata, ...)
}
\arguments{
  \item{object}{An open \code{sciencekit_model} object.}
  \item{newdata}{A rectangular \code{double} (\code{f64}) matrix or data frame
    of features.}
  \item{...}{Unused arguments passed to or from other methods.}
}
\value{
A \code{double} vector of length \code{nrow(newdata)}.
}
\examples{
x <- matrix(c(0, 1, 0, 2, 0, 0, 1, 3), nrow = 4, ncol = 2)
y <- c(1, 3, 4, 14)
builder <- sk_linear_regression()
model <- fit(builder, x, y)
predict(model, x)
close(model)
close(builder)
}
