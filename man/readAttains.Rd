% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/readAttains.r
\name{readAttains}
\alias{readAttains}
\title{Read data from EPA's ATTAINS database}
\usage{
readAttains(type = "assessments", ...)
}
\arguments{
\item{type}{ATTAINS data type to read. One of: "assessmentUnits", "assessments", "actions", or "domains".}

\item{...}{Additional arguments to be passed to ATTAINS web service path.}

\item{stateCode}{Two letter state code (for all pulls where type != "assessments")}

\item{state}{Two letter state code (for read type == "assessments")}

\item{reportingCycle}{Four digit year of interest. Must be specified for type == "assessments" (NOTE: EPA working on update that will return the most recent cycle).}
}
\value{
Returns a data.frame or list of queried ATTAINS data. Note that some results may contain additional lists of results that can be further flattened.
}
\description{
This function pulls information from EPA ATTAINS database based on submitted arguments via ATTAINS web service. Any ATTAINS web service compatible argument can be submitted to this funciton. Depending on type, at least one argument may be required. See https://link-to-be-obtained.gov for a list of required and compatible arguments.
The function is essentially an ATTAINS specific wrapper for jsonlite::fromJSON. It generates the appropriate web path to connect to ATTAINS web service and converts JSON to R object.
}
\examples{
#Read Utah assessment unit information
UT_AUs=readAttains(type="assessmentUnits", stateCode="UT")

#Read Utah actions
UT_actions=readAttains(type="actions", stateCode="UT")

#Read Utah assessments
UT_assessments=readAttains(type="assessments", state="UT", reportingCycle=2016)
}
