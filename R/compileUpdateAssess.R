#' Create compiled 303d file for current cycle and update last assessed MLID/parameter/use master list
#'
#'
#' @param prepped_data A prepped object produced in the dataPrep step of irTools 
#' @param master_compiled_file Path to a spreadsheet containing a master list of MLID/R3172Parameter/Use/Category records assessed in previous IR cycles.
#' @param site_use_param_assessment Dataframe with assessment categories for each MLID/Use/R3172ParameterName from current IR cycle.
#' @return Produces 303d compiled file for current cycle and updates master compiled MLID list.
#' @importFrom plyr rbind.fill
#' @importFrom reshape2 colsplit

#' @export
#' 

compileUpdateAssess <- function(prepped_data=prepped_data, master_compiled_file, site_use_param_assessment=site_use_param_assessments){

#Testing
master_compiled_file = "P:\\WQ\\Integrated Report\\Automation_Development\\elise\\demo2\\303d_assessments_master.csv"
#Load compiled master workbook
compiled_master=read.csv(master_compiled_file, stringsAsFactors = FALSE)

#Bring in site assessments
site_asmt <- site_use_param_assessments

#Merge roll up data to compiled master
new_master <- merge(compiled_master,site_asmt, all=TRUE)

##Subset to rows where Ncount calculations needed (new assessments and updated assessments)
#New site/param/use
new <- subset(new_master, !is.na(new_master$AssessCat)& is.na(new_master$PreviousCat))
new <- new[,!names(new)%in%c("PreviousCat","CycLastAssessed")]

#Updated sites
updated <- subset(new_master, !is.na(new_master$AssessCat)& !is.na(new_master$PreviousCat))
updated <- updated[,!names(updated)%in%c("PreviousCat","CycLastAssessed")]

#Determine latest date assessed using compiled master

# Latest date = 9-30-(LastCycleAssessed year-2 years)


#Count number of samples in prepped_data after latest date assessed, or all samples in current IR cycle if no overlap with last cycle assessed (or new site)

date_data <- prepped_data[!names(prepped_data)%in%c("data_flags","flag_reasons")]
date_data <- date_data[sapply(date_data, nrow)>0]

#Rbind prepped data back together with activity start date, MLID, parameter, use columns

# length(subset of data newer than Latest date)

#Create compiled file output from compiled master and N counts

#Update compiled master in preparation for next cycle

  


  
}