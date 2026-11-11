\name{abi_version}
\alias{abi_version}
\alias{abi_features}
\title{Query the Loaded sciencekit C ABI Version and Capabilities}
\description{
Inspect the semantic version and feature bitmask reported by the linked
\code{sciencekit_ffi} native library.
}
\usage{
abi_version()

abi_features()
}
\value{
\code{abi_version()} returns a named integer vector with elements \code{major},
\code{minor}, and \code{patch}. \code{abi_features()} returns a named logical
vector advertising supported estimator families, model persistence, and scalar
types.
}
\examples{
abi_version()
abi_features()
}
