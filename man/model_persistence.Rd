\name{model_persistence}
\alias{save_model}
\alias{load_model}
\title{Save and Load Fitted sciencekit Models}
\description{
Persists and restores fitted model state through the \code{sciencekit_ffi}
interop model-state contract. Currently supported for double-precision
(\code{f64}) linear-regression models.
}
\usage{
save_model(model, path)

load_model(path)
}
\arguments{
  \item{model}{An open \code{sciencekit_model} object.}
  \item{path}{Non-empty character scalar giving the file path.}
}
\value{
\code{save_model()} invisibly returns \code{path}. \code{load_model()} returns a
new \code{sciencekit_model} object.
}
\examples{
x <- matrix(c(0, 1, 0, 2, 0, 0, 1, 3), nrow = 4, ncol = 2)
y <- c(1, 3, 4, 14)
builder <- sk_linear_regression()
model <- fit(builder, x, y)

tmp <- tempfile(fileext = ".skmodel")
save_model(model, tmp)
restored <- load_model(tmp)
predict(restored, x)

close(restored)
close(model)
close(builder)
unlink(tmp)
}
