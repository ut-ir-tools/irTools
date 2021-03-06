% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/applyScreenTable.r
\name{applyScreenTable}
\alias{applyScreenTable}
\title{Apply screens to WQP data by selected table}
\usage{
applyScreenTable(
  data,
  wb,
  sheetname,
  flag_col_name,
  com_col_name,
  startRow = 1,
  na_dup_err = TRUE
)
}
\arguments{
\item{data}{A merged WQP result object. Must include both narrowresult & activity files. May also be a post-fillMaskedValues() results object. Note: re-application of edited domain tables to an already screened dataset is not advised, and changes to the domain table likely will not be reflected in a re-screened dataset due to merging conventions.}

\item{wb}{Full path and filename for Excel workbook containing screen table to be applied}

\item{sheetname}{Name of sheet in workbook holding desired screening decisions}

\item{flag_col_name}{Name to rename IR_FLAG column to.}

\item{com_col_name}{Name to rename IR_COMMENT column to.}

\item{startRow}{Row to start reading excel sheet from (in case additional headers have been added). Defaults to 1.}

\item{na_dup_err}{Logical. If TRUE (default), exit function with error if IR_FLAG values are NA or if duplicates detected in combinations in the domain table for which InData=="Y". Set to FALSE to apply a screen table without checking for NA values in IR_FLAG.}
}
\value{
A data.frame object of WQP data with merged columns from input screening tables.
}
\description{
Joins activity review inputs (detConditionTable, labNameActivityTable, activityMediaNameTable, masterSiteTable, paramTransTable, & activityCommentTable) to WQP data to apply decisions from input files to data.
}
