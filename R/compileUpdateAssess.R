#' Create compiled 303d file for current cycle and update last assessed MLID/parameter/use master list
#'
#'
#' @param prepped_data A prepped object produced in the dataPrep step of irTools 
#' @param master_compiled_file Path to a spreadsheet containing a master list of MLID/R3172Parameter/Use/Category records assessed in previous IR cycles.
#' @param site_use_param_assessment Dataframe with assessment categories for each MLID/Use/R3172ParameterName from current IR cycle.
#' @return Produces 303d compiled file for current cycle and updates master compiled MLID list.
#' @importFrom plyr rbind.fill
#' @importFrom reshape2 colsplit
#' @importFrom openxlsx loadWorkbook
#' @importFrom openxlsx readWorkbook
#' @importFrom openxlsx saveWorkbook
#' @importFrom openxlsx writeData
#' @importFrom openxlsx removeFilter

#' @export
#' 

compileUpdateAssess <- function(prepped_data=prepped_data, master_compiled_file, site_use_param_assessment=site_use_param_assessments){
  
  master_compiled <- read.csv(master_compiled)
  
  date_data <- prepped_data[!names(prepped_data)%in%c("data_flags","flag_reasons")]
  date_data <- date_data[sapply(date_data, nrow)>0]

  
}