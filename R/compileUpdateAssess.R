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

#Testing
master_compiled_file = "P:\\WQ\\Integrated Report\\Automation_Development\\elise\\demo2\\303d_assessments_master.csv"

compileUpdateAssess <- function(prepped_data=prepped_data, master_compiled_file, site_use_param_assessment=site_use_param_assessments){

#Load compiled master workbook
compiled_master=read.csv(master_compiled_file, stringsAsFactors = FALSE)

#Merge roll up data to compiled master
new_master <- merge(compiled_master,site_use_param_assessments, all=TRUE)

#Read in prepped data, obtain unique site-date-param-use records in preparation for producing Ncounts

date_data <- prepped_data[!names(prepped_data)%in%c("data_flags","flag_reasons")]
date_data <- date_data[sapply(date_data, nrow)>0]

ext_dat <- function(x) x <- x[,names(x)%in%c("IR_MLID","ActivityStartDate","R3172ParameterName","BeneficialUse")]

date_data <- lapply(date_data,ext_dat)
date_Data <- do.call("rbind",date_data) #create one data frame from all separate datasets produced by dataPrep
date_Data <- unique(date_Data)

##Subset to rows where Ncount calculations needed (new assessments and updated assessments)
#New site/param/use
new <- subset(new_master, !is.na(new_master$AssessCat)& is.na(new_master$PreviousCat))

#Aggregate Ncounts of all site-use-param combinations
date_Data_new_ncount <- aggregate(ActivityStartDate~IR_MLID+BeneficialUse+R3172ParameterName, data=date_Data, FUN=length)
date_Data_new_ncount[,names(date_Data_new_ncount)%in%c("ActivityStartDate")]<-"Ncount"
#Updated sites
updated <- subset(new_master, !is.na(new_master$AssessCat)& !is.na(new_master$PreviousCat))

#Determine latest date assessed using compiled master

# Latest date = 9-30-(LastCycleAssessed year-2 years)




#Rbind prepped data back together with activity start date, MLID, parameter, use columns

# length(subset of data newer than Latest date)

#Create compiled file output from compiled master and N counts

#Update compiled master in preparation for next cycle

  


  
}