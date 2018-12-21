#' Create compiled 303d file for current cycle and update last assessed MLID/parameter/use master list
#'
#'
#' @param prepped_data A prepped object produced in the dataPrep step of irTools 
#' @param master_compiled_file Path to a spreadsheet containing a master list of MLID/R3172Parameter/Use/Category records assessed in previous IR cycles.
#' @param site_use_param_assessment Dataframe with assessment categories for each MLID/Use/R3172ParameterName from current IR cycle.
#' @return Produces 303d compiled file for current cycle and updates master compiled MLID list.
#' 

#' @export
#' 

#Testing
# master_compiled_file = "P:\\WQ\\Integrated Report\\Automation_Development\\elise\\demo2\\303d_assessments_master.csv"
# outfile_path = "P:\\WQ\\Integrated Report\\Automation_Development\\elise\\demo2"

#####NOTES TO EH##### add lines about updating master when older data run through code than data used to produce master....
compileUpdateAssess <- function(prepped_data=prepped_data, master_compiled_file, site_use_param_assessment=site_use_param_assessments, outfile_path){

## Load compiled master workbook
compiled_master=read.csv(master_compiled_file, stringsAsFactors = FALSE)

## Merge roll up data to compiled master
new_master <- merge(compiled_master,site_use_param_assessments, all=TRUE)

## Read in prepped data, obtain unique site-date-param-use records in preparation for producing Ncounts
date_data <- prepped_data[!names(prepped_data)%in%c("data_flags","flag_reasons")]
date_data <- date_data[sapply(date_data, nrow)>0]

ext_dat <- function(x) x <- x[,names(x)%in%c("IR_MLID","ActivityStartDate","R3172ParameterName","BeneficialUse")]

date_data <- lapply(date_data,ext_dat)
date_Data <- do.call("rbind",date_data) #create one data frame from all separate datasets produced by dataPrep
date_Data <- unique(date_Data)
date_Data$ActivityStartDate <- as.Date(date_Data$ActivityStartDate,"%Y-%m-%d")

cyc_year <- lubridate::year(max(date_Data$ActivityStartDate))+2

## Subset to rows where Ncount calculations needed (new assessments and updated assessments)
## New site/param/use
new <- subset(new_master, !is.na(new_master$AssessCat)& is.na(new_master$PreviousCat))

# Aggregate Ncounts of all site-use-param combinations
date_Data_new_ncount <- aggregate(ActivityStartDate~IR_MLID+BeneficialUse+R3172ParameterName, data=date_Data, FUN=length)
names(date_Data_new_ncount)[names(date_Data_new_ncount)=="ActivityStartDate"]<-"Ncount"

# Merge Ncount with new site/use/param
new_ncount <- merge(new,date_Data_new_ncount, all.x=TRUE)

## Updated sites
updated <- subset(new_master, !is.na(new_master$AssessCat)& !is.na(new_master$PreviousCat))

# Convert dates to date format in both updated and date_Data
updated$last_dat <- paste("09-30-",updated$CycLastAssessed-2,sep="")
updated$last_dat <- as.Date(last_dat, "%m-%d-%Y")

# Find all records associated with those with additional data this cycle
up_key <- updated[,c("IR_MLID","R3172ParameterName","BeneficialUse","last_dat")]
date_Data_update <- merge(up_key,date_Data, all.x=TRUE)

# Determine which samples occurred more recently than the last cycle assessment cutoff
date_Data_update$Ncount = ifelse(date_Data_update$ActivityStartDate>date_Data_update$last_dat,1,0)

# Aggregate (by summing 1's) Ncounts of all site-use-param combinations
date_Data_up_ncount <- aggregate(Ncount~IR_MLID+BeneficialUse+R3172ParameterName, data=date_Data_update, FUN=sum)

# Merge Ncount with updated site/use/param
updated_ncount <- merge(updated,date_Data_up_ncount, all.x=TRUE)
updated_ncount <- updated_ncount[,!names(updated_ncount)%in%c("last_dat")]

# Rbind updated and new data back together
ncount_data <- rbind(new_ncount, updated_ncount)

# Merge to master
new_master_ncount <- merge(new_master, ncount_data, all.x=TRUE)
new_master_ncount$Ncount[is.na(new_master_ncount$Ncount)]<-0
new_master_ncount$CycYear[new_master_ncount$Ncount>0] <- cyc_year

compiled_ncount =new_master_ncount
compiled_ncount$CycYear[!compiled_ncount$Ncount>0] = "Not assessed this cycle"

#Create compiled file output from compiled master and N counts
write.csv(compiled_ncount,paste0(outfile_path,"\\compiled_assessment_file",cyc_year,".csv"), row.names=FALSE)

#Update compiled master in preparation for next cycle
new_master_ncount$CycLastAssessed = ifelse(!is.na(new_master_ncount$CycYear),cyc_year,new_master_ncount$CycLastAssessed)
new_master_ncount$PreviousCat = ifelse(!is.na(new_master_ncount$CycYear),new_master_ncount$AssessCat,new_master_ncount$PreviousCat)
new_master_ncount <- new_master_ncount[,!names(new_master_ncount)%in%c("CycYear","Ncount","AssessCat")]

write.csv(new_master_ncount,paste0(outfile_path,"\\master_assessment_ledger",cyc_year,".csv"), row.names = FALSE)
print(paste("Compiled assessment file and master assessment ledger successfully saved in",outfile_path))
}