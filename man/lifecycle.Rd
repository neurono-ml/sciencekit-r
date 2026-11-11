\name{lifecycle}
\alias{close.sciencekit_builder}
\alias{close.sciencekit_model}
\alias{is_closed}
\alias{live_handle_counts}
\title{Manage Native Handle Lifecycles}
\description{
Builders and fitted models own opaque C ABI handles wrapped in R external
pointers with garbage-collector finalizers. \code{close()} releases a native
handle eagerly and idempotently; \code{is_closed()} checks whether the handle
has already been released; \code{live_handle_counts()} reports active handles
in the current R process.
}
\usage{
\method{close}{sciencekit_builder}(con, ...)

\method{close}{sciencekit_model}(con, ...)

is_closed(x)

live_handle_counts()
}
\arguments{
  \item{con}{A \code{sciencekit_builder} or \code{sciencekit_model} object.}
  \item{...}{Unused arguments passed to or from other methods.}
  \item{x}{A \code{sciencekit_builder} or \code{sciencekit_model} object.}
}
\value{
\code{close()} invisibly returns \code{TRUE} when the call releases the native
handle and \code{FALSE} when it was already closed. \code{is_closed()} returns
a logical scalar. \code{live_handle_counts()} returns a named integer vector
with elements \code{builders} and \code{models}.
}
\examples{
builder <- sk_linear_regression()
is_closed(builder)
close(builder)
close(builder)
is_closed(builder)
}
