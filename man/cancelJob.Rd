% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrapper-functions.R
\name{cancelJob}
\alias{cancelJob}
\title{Terminates a running job}
\usage{
cancelJob(con, job_id)
}
\arguments{
\item{con}{authenticated Connection}

\item{job_id}{id of job that will be canceled}
}
\value{
a success / failure notification
}
\description{
Informs the server that the specified job needs to be terminate and taken "canceled" to prevent from
further executions and related costs.
}
