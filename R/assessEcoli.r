#E Coli specific functions

#######################
#dataPreProc
#function for data preprocessing: subs 1 for <1 and 2420 for >2419.6, calculates site/date geomeans, trims to rec season, creates flat file (MLID+Date+Use=UID, repeats data as necessary)
# Testing
#load R packages
require(lubridate)
require(reshape2)
require(plyr)
require(dplyr)
require(lubridate)


#data_raw = prepped_data$ecoli
# data_raw <- read.csv("P:\\WQ\\Integrated Report\\Automation_Development\\elise\\e.coli_demo\\01_rawdata\\ecoli_example_data.csv")
#Define rec season ("mm-dd"):
# SeasonStartDate="05-01"
# SeasonEndDate="10-31"
# rec_season = TRUE

assessEColi <- function(prepped_data, rec_season = TRUE, SeasonStartDate="05-01", SeasonEndDate="10-31"){

  ecoli_assessments <- list() 

  # Geometric mean function
  gmean=function(x){exp(mean(log(x)))}
  
  # Obtain unique use/criterion 
  uses_stds <- unique(data_raw[c("BeneficialUse","CriterionLabel","NumericCriterion")])
  
  # Remove duplicates from data
  data_raw <- data_raw[,!names(data_raw)%in%c("AsmntAggPeriod","AsmntAggPeriodUnit","AsmntAggFun","CriterionLabel","NumericCriterion")]
  data_raw <- unique(data_raw)
  
  # Convert dates to R dates
  data_raw$ActivityStartDate=as.Date(data_raw$ActivityStartDate,format='%m/%d/%Y')
  
  # Create year column for scenario calculations
  data_raw$Year=year(data_raw$ActivityStartDate)
  
  # Restrict assessments to data collected during recreation season.
  if(rec_season){
    data_raw=data_raw[month(data_raw$ActivityStartDate)>=month(as.Date(SeasonStartDate,format='%m-%d'))
                      &day(data_raw$ActivityStartDate)>=day(as.Date(SeasonStartDate,format='%m-%d'))
                      &month(data_raw$ActivityStartDate)<=month(as.Date(SeasonEndDate,format='%m-%d'))
                      &day(data_raw$ActivityStartDate)<=day(as.Date(SeasonEndDate,format='%m-%d')),]
  }
  
  # Substitute numbers for ND and OD limits and aggregate to daily values.
  data_raw$IR_Value=gsub("<1",1,data_raw$IR_Value)
  data_raw$IR_Value=as.numeric(gsub(">2419.6",2420,data_raw$IR_Value))
  daily_agg=aggregate(IR_Value~IR_MLID+BeneficialUse+ActivityStartDate,data=data_raw,FUN='gmean')
  data_processed <- merge(daily_agg,data_raw, all.x=TRUE)
  
  # maxSamps48hr function - counts the maximum number of samples collected over the rec season that were not collected within 48 hours of another sample(s).
  maxSamps48hr = function(x){
    x = sort(x) # order by DOY
    consecutive.groupings <- c(0, which(diff(x) != 1), length(x)) # Determine breaks in 1 by 1 sequence
    consec.groups <- sum(ceiling(diff(consecutive.groupings)/2)) # Determine length of each sequential group, divide by two, and round up to get the max number of samples occurring at least 48 hours apart
    return(consec.groups)
  }
  
##### SCENARIO A #####
  
  assessA = function(x){
    out_48_hr = maxSamps48hr(x$ActivityStartDate)
    stdcrit = uses_stds$NumericCriterion[uses_stds$BeneficialUse==x$BeneficialUse[1]&uses_stds$CriterionLabel=="max_crit"]
    out <- x[1,c("IR_MLID","BeneficialUse","Year")]
    out$Scenario = "A"
    out$Ncount = length(x$ActivityStartDate)
    out$ExcCountLim = ifelse(out_48_hr>=5,ceiling(out_48_hr*.1),1)
    out$ExcCount = length(x$IR_Value[x$IR_Value>stdcrit])
    if(out$Ncount<5){
      out$IR_Cat = ifelse(out$ExcCount>out$ExcCountLim,"idE","idNE")
    }else{
      out$IR_Cat = ifelse(out$ExcCount>out$ExcCountLim,"NS","ScenB")
    }
    return(out)
    }

##### SCENARIO B #####

  assessB <- function(x){
    out_48_hr = maxSamps48hr(x$ActivityStartDate)
    if(out_48_hr<5){
      out <- x[1,c("IR_MLID","BeneficialUse","Year")]
      out$Ncount = out_48_hr
      out$IR_Cat = "Not Assessed"
      out$Scenario = "B"
    }
    stdcrit = uses_stds$NumericCriterion[uses_stds$BeneficialUse==x$BeneficialUse[1]&uses_stds$CriterionLabel=="30-day"]
    # Create empty vector to hold geometric means
    geomeans <- vector()
    n = 1 # counter for geomeans vector population
    # Loop through each day 
    for(i in 1:dim(x)[1]){
      dmax = x$ActivityStartDate[i]+29 # create 30 day window
      samps = x[x$ActivityStartDate>=x$ActivityStartDate[i]&x$ActivityStartDate<=dmax,] # Isolate samples occurring within that window
      # Calculate geometric mean on ALL samples IF 5 or more samples are spaced at least 48 hours apart
      geomeans[i] <- ifelse(maxSamps48hr(samps$ActivityStartDate)>=5,gmean(samps$IR_Value),0)
      }
    # Create output dataframe with MLID/Use/Year/Ncount...etc.
      out <- samps[1,c("IR_MLID","BeneficialUse","Year")]
      out$Ncount = length(geomeans)
      out$ExcCountLim = 1
      out$ExcCount = length(geomeans[geomeans>=stdcrit])
      out$IR_Cat = ifelse(any(geomeans>=stdcrit),"NS","ScenC")
      out$Scenario = "B"
      return(out)
  }

##### SCENARIO C #####
  
  assessC <- function(x){
    out_48_hr = maxSamps48hr(x$ActivityStartDate)
    if(out_48_hr<5){
      out <- x[1,c("IR_MLID","BeneficialUse","Year")]
      out$Ncount = out_48_hr
      out$IR_Cat = "Not Assessed"
      out$Scenario = "C"
    }else{
      stdcrit = uses_stds$NumericCriterion[uses_stds$BeneficialUse==x$BeneficialUse[1]&uses_stds$CriterionLabel=="30-day"]
      out <- x[1,c("IR_MLID","BeneficialUse","Year")]
      out$Scenario = "C"
      out$Ncount = length(x$ActivityStartDate)
      geomean <- gmean(x$IR_Value)
      if(out$Ncount<10){
        out$IR_Cat = ifelse(geomean>stdcrit,"idE","idNE")
      }else{
        out$IR_Cat = ifelse(geomean>stdcrit,"NS","FS")
      }
    }
    return(out)
  }
  
##### COMBINE SCENARIOS ####
  
    ScenA = ddply(.data=data_processed,.(IR_MLID,BeneficialUse,Year),.fun=assessA)
    ScenB = ddply(.data=data_processed,.(IR_MLID,BeneficialUse,Year),.fun=assessB)
    ScenC = ddply(.data=data_processed,.(IR_MLID,BeneficialUse,Year),.fun=assessC)

    ecoli_assessments$ScenABC = bind_rows(ScenA,ScenB,ScenC)

## Rank Scenarios ##
  
  ScenABC = ecoli_assessments$ScenABC
  ScenABC = ScenABC[!(ScenABC$IR_Cat=="ScenB"|ScenABC$IR_Cat=="ScenC"|ScenABC$IR_Cat=="Not Assessed"),]
  ScenABC$S.rank = 3
  ScenABC$S.rank[ScenABC$Scenario=="B"] = 2
  ScenABC$S.rank[ScenABC$Scenario=="C"] = 1
  
  ## Roll up by scenario ##
  
  ScenABC_agg <- aggregate(S.rank~IR_MLID+BeneficialUse+Year, data=ScenABC, FUN=max)
  ScenABC_agg$Scenario = "A"
  ScenABC_agg$Scenario[ScenABC_agg$S.rank==2]="B"
  ScenABC_agg$Scenario[ScenABC_agg$S.rank==1]="C"
  ScenABC_assess <- merge(ScenABC_agg, ScenABC, all.x=TRUE)
  ScenABC_assess = ScenABC_assess[,!names(ScenABC_assess)%in%c("S.rank")]

  # Merge data back to original dataset
  data_raw1 <- unique(data_raw[,c("IR_MLID","ASSESS_ID","BeneficialUse","BEN_CLASS","R3172ParameterName")])
 
  ecoli.assessed <- merge(ScenABC_assess,data_raw1, all.x=TRUE)
 
  ecoli.site.dat <- rollUp(ecoli.assessed, group_vars=c("IR_MLID", "ASSESS_ID","BeneficialUse","R3172ParameterName"), expand_uses=TRUE, ecoli=TRUE)
  
  ecoli_assessments$ecoli_site_rollup <- ecoli.site.dat
  
  return(ecoli_assessments)
} 
  #Old code:
#####################################
  ####################
  ######MLIDYr_rollup#
  #Rolls up assessments for MLIDs w/ multiple years
  #Categories: 5>3A>3E>2
  #Input data is output from assessEColi_MLIDYr
  
#   MLIDYr_rollup=function(data){
#     ru=dcast(data,MLID+Use~Year,value.var="Cat")
#     ru[is.na(ru)]=0 #note, 0 here denotes no data for each year
#     AssessCat=vector()
#     for(n in 1:dim(ru)[1]){
#       data_n=ru[n,]
#       if(any(data_n[3:dim(data_n)[2]]==5)){assess_n=5
#       }else{if(any(data_n[3:dim(data_n)[2]]=="3A")){assess_n="3A"
#       }else{if(any(data_n[3:dim(data_n)[2]]=="3E")){assess_n="3E"
#       }else{if(all(data_n[3:dim(data_n)[2]]==2)){assess_n=2}}}}
#       AssessCat=append(AssessCat,assess_n)
#     }
#     ru=cbind(ru,AssessCat)
#   }
#   
# }

# maxSamps48hr=function(x){
#   count=vector()
#   for(n in 1:dim(x)[1]){
#     data_n=x 
#     if(dim(data_n)[1]>0){
#       doy_seed=data_n$doy[n] 
#       data_n=data_n[data_n$doy-doy_seed>1|data_n$doy-doy_seed<(-1)|data_n$doy-doy_seed==0,]
#       data_ni=data_n
#       i=n+1
#       if(i>dim(data_ni)[1]){i=1}
#       while(doy_seed!=data_ni[i,"doy"]){	
#         data_ni=data_ni[data_ni$doy-data_ni[i,"doy"]>1|data_ni$doy-data_ni[i,"doy"]<(-1)|data_ni$doy-data_ni[i,"doy"]==0|data_ni$doy==doy_seed,]
#         if(i<dim(data_ni)[1]){i=i+1}else{i=1}
#       }
#       count=append(count,dim(data_ni)[1])
#       max_count=max(count)}}
#   if(dim(data_n)[1]==0){max_count=0}
#   return(max_count)
# }


# assessA=function(data){
#   #maxSamps48hr=maxSamps48hr(data)#48 hr spacing turned off
#   maxSamps48hr=dim(data)[1]#48 hr spacing turned off
#   Use=data$Use[1]
#   if(Use=="2A"){max_crit=std2A_max}
#   if(Use=="2B"){max_crit=std2B_max}
#   if(Use=="1C"){max_crit=std1C_max}
#   if(maxSamps48hr<5){
#     if(any(data$MPN_FINAL>max_crit)){assessed=c(paste(dim(data)[1]),"3A","A")
#     }else{assessed=c(paste(dim(data)[1]),"3E","A")}
#   }
#   if(maxSamps48hr>=5){
#     tenpct=ceiling(dim(data)[1]/10)
#     if(dim(data[data$MPN_FINAL>max_crit,])[1]>tenpct){assessed=c(paste(dim(data)[1]),"5","A")
#     }else{assessed=c(paste(dim(data)[1]),"BC","BC")}
#   }
#   return(assessed)	
# }
# 
# assessBC=function(data){
#   Year=data$Year[1]
#   Use=data$Use[1]
#   rec_season=format(seq(from=as.Date(paste0(Year,"-",SeasonStartDate)),to=as.Date(paste0(Year,"-",SeasonEndDate)),by=1),format="%m-%d-%Y")
#   if(Use[1]=="2A"){gmean30d_crit=std2A_30Dgmean}
#   if(Use[1]=="2B"){gmean30d_crit=std2B_30Dgmean}
#   if(Use[1]=="1C"){gmean30d_crit=std1C_30Dgmean}
#   if(dim(data)[1]<5){assess=c(paste(dim(data)[1]),"C","C")}
#   if(dim(data)[1]>=5){
#     gmean=vector(length=length(rec_season))
#     for(j in 1:length(rec_season)){
#       dmin=as.Date(rec_season[j],format='%m-%d-%Y')
#       dmax=as.Date(rec_season[j],format='%m-%d-%Y')+29
#       data_j=data[data$Date>=dmin&data$Date<=dmax,]
#       maxSamps48hr_j=maxSamps48hr(data_j)
#       if(maxSamps48hr_j>=5){gmean_j=gmean(data_j$MPN_FINAL)}else{gmean_j=0}#Note that 0s here denote no gmean calculated, not a gmean of 0
#       gmean[j]=gmean_j}
#     if(any(gmean>gmean30d_crit)==TRUE){assess=c(paste(dim(data)[1]),5,"B")}else{assess=c(paste(dim(data)[1]),"C","C")
#     }
#   }
#   if(assess[3]=="C"){
#     gmean_recseason=gmean(data$MPN_FINAL)
#     if(dim(data)[1]<10&gmean_recseason<=gmean30d_crit){assess=c(paste(dim(data)[1]),2,"C")}
#     if(dim(data)[1]<10&gmean_recseason>gmean30d_crit){assess=c(paste(dim(data)[1]),"3A","C")}
#     if(dim(data)[1]>=10&gmean_recseason<=gmean30d_crit){assess=c(paste(dim(data)[1]),2,"C")}
#     if(dim(data)[1]>=10&gmean_recseason>gmean30d_crit){assess=c(paste(dim(data)[1]),5,"C")}
#   }	
#   return(assess)
# }
#
#
# assessEColi_MLIDYr=function(data){
# assessedA=ddply(.data=data_preprocessed,.(MLID,Year,Use),.fun=assessA)
# colnames(assessedA)=c("MLID","Year","Use","totalSamps","Cat","Scen")
# 
# data_bc=merge(data_preprocessed,assessedA)
# data_bc=data_bc[data_bc$Scen=="BC",]
# 
# assessedBC=ddply(.data=data_bc,.(MLID,Year,Use),.fun=assessBC)
# colnames(assessedBC)=c("MLID","Year","Use","totalSamps","Cat","Scen")
# 
# assessedA=assessedA[assessedA$Scen=="A",]
# ecoli_assessments=rbind(assessedA,assessedBC)
# return(ecoli_assessments)
# }
#
#makeKey=function(data){
#	data=cbind(data,uses)
#	key=melt(data[,c("MLID","Year",paste0(rep("u",15),seq(1,15,1)))],id.vars=c("MLID","Year"),na.rm=T)
#	key=key[key$value=="1C"|key$value=="2A"|key$value=="2B",]
#	key=unique(key[,c("MLID","Year","value")])
#	colnames(key)=c("MLID","Year","Use")
#	data_preprocessed=data.frame(data_preprocessed)
#	return(data_preprocessed)
#	}
#
#
#key_BC=data.frame(unique(assess_A[assess_A[,"Scen"]=="BC",c("MLID","Year","Use")]),row.names=NULL)
#assess_A=assess_A[assess_A[,"Scen"]=="A",]
#assess_BC=matrix(ncol=7,nrow=0)
#for(n in 1:dim(key_BC)[1]){
#	MLID_n=as.vector(key_BC[n,1])
#	Year_n=as.vector(key_BC[n,2])
#	data_n=data_preprocessed[data_preprocessed$MLID==MLID_n&data_preprocessed$Year==Year_n,]
#	rec_season=format(seq(from=as.Date(paste0(Year_n,"-",SeasonStartDate)),to=as.Date(paste0(Year_n,"-",SeasonEndDate)),by=1),format="%m-%d-%Y")
#	if(key$Use[n]=="2A"){gmean30d_crit=std2A_30Dgmean}
#	if(key$Use[n]=="2B"){gmean30d_crit=std2B_30Dgmean}
#	if(key$Use[n]=="1C"){gmean30d_crit=std1C_30Dgmean}
#	if(dim(data_n)[1]<5){assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,NA,"C","C")}
#	if(dim(data_n)[1]>=5){
#	gmean_n=vector()
#		for(j in 1:length(rec_season)){
#			dmin=as.Date(rec_season[j],format='%m-%d-%Y')
#			dmax=as.Date(rec_season[j],format='%m-%d-%Y')+29
#			data_nj=data_n[data_n$Date>=dmin&data_n$Date<=dmax,]
#			maxSamps48hr_nj=maxSamps48hr(data_nj)
#			if(maxSamps48hr_nj>=5){gmean_ni=gmean(data_nj$MPN_FINAL)}else{gmean_ni=0}#Note that 0s here denote no gmean calculated, not a gmean of 0
#			gmean_n=append(gmean_n,gmean_ni)}
#		if(any(gmean_n>gmean30d_crit)==TRUE){assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,paste(dim(data_n)[1]),5,"B")}else{assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,paste(dim(data_n)[1]),"C","C")}}
#		if(assess_n[7]=="C"){
#			gmean_recseason=gmean(data_n$MPN_FINAL)
#			if(dim(data_n)[1]<10&gmean_recseason<=gmean30d_crit){assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,paste(dim(data_n)[1]),2,"C")}
#			if(dim(data_n)[1]<10&gmean_recseason>gmean30d_crit){assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,paste(dim(data_n)[1]),"3A","C")}
#			if(dim(data_n)[1]>=10&gmean_recseason<=gmean30d_crit){assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,paste(dim(data_n)[1]),2,"C")}
#			if(dim(data_n)[1]>=10&gmean_recseason>gmean30d_crit){assess_n=c(paste(MLID_n),paste(key_BC$Use[n]),paste(Year_n),NA,paste(dim(data_n)[1]),5,"C")}
#			}			
#		assess_BC=rbind(assess_BC,assess_n)}
#
#colnames(assess_BC)=c("MLID","Use","Year","maxSamps48hr","totalSamps","Cat","Scen")
#MLID_Yr_assessed=data.frame(rbind(assess_A,assess_BC),row.names=NULL)
#return(MLID_Yr_assessed)
#}
#
#
#
#
#
#
#assessEColi_MLIDYr=function(data){
#
#
##Scenario A
#assess_A=matrix(ncol=7,nrow=0)
#for(n in 1:dim(key)[1]){
#	data_n=data[data$MLID==key$MLID[n]&data$Year==key$Year[n],]
#	#maxSamps48hr_n=maxSamps48hr(data_n)#48 hr spacing turned off
#	maxSamps48hr_n=dim(data_n)[1]#48 hr spacing turned off
#	if(key$Use[n]=="2A"){max_crit=std2A_max}
#	if(key$Use[n]=="2B"){max_crit=std2B_max}
#	if(key$Use[n]=="1C"){max_crit=std1C_max}
#		if(maxSamps48hr_n<5){
#			if(any(data_n$MPN_FINAL>max_crit)){assess_n=c(paste(key$MLID[n]),paste(key$Use[n]),paste(key$Year[n]),paste(maxSamps48hr_n),paste(dim(data_n)[1]),"3A","A")
#			}else{assess_n=c(paste(key$MLID[n]),paste(key$Use[n]),paste(key$Year[n]),paste(maxSamps48hr_n),paste(dim(data_n)[1]),"3E","A")}}
#		if(maxSamps48hr_n>=5){
#			tenpct=ceiling(dim(data_n)[1]/10)
#			if(dim(data_n[data_n$MPN_FINAL>max_crit,])[1]>tenpct){assess_n=c(paste(key$MLID[n]),paste(key$Use[n]),paste(key$Year[n]),paste(maxSamps48hr_n),paste(dim(data_n)[1]),"5","A")
#			}else{assess_n=c(paste(key$MLID[n]),paste(key$Use[n]),paste(key$Year[n]),paste(maxSamps48hr_n),paste(dim(data_n)[1]),"BC","BC")}}
#		assess_A=rbind(assess_A,assess_n)
#	}
#colnames(assess_A)=c("MLID","Use","Year","maxSamps48hr","totalSamps","Cat","Scen")
#
#}
#
#
#
##Scenarios B&C (conceptual outline)
##cycle through MLID by year
#	#cycle through calendar, for each 30d window:
#		#Weed out any MLID-years w/ <5 samples {send MLID/year to scen C}
#		#Calculate max # of samples w/ 48 hr spacing
#		#Calc 30d geomean for each window w/ sufficient data
#	#Record all 30d geomeans for each MLID/year
#		#if no 30d geomeans are calculated {send MLID/year to scen C}
#		#if >1 geomeans calculated & 0 exceed {send MLID/year to scen C}
#		#if >1 geomeans & >0 exceed {Cat 5}
#	#For data sent to scen C:
#		#Calc rec season geomean
#		#If >=10 events in MLID-year
#			#Geomean exceed: cat 5
#			#Geomean not exceeded: cat 2
#		#If <10 events in MLID-year
#			#Geomean exceed: cat 3A
#			#Geomean not exceeded: cat 2	
#		
#
#
#####################
#######MLIDYr_rollup#
##Rolls up assessments for MLIDs w/ multiple years
##Categories: 5>3A>3E>2
##Input data is output from assessEColi_MLIDYr
#
#MLIDYr_rollup=function(data){
#ru=dcast(data,MLID+Use~Year,value.var="Cat")
#ru[is.na(ru)]=0 #note, 0 here denotes no data for each year
#AssessCat=vector()
#for(n in 1:dim(ru)[1]){
#	data_n=ru[n,]
#	if(any(data_n[3:dim(data_n)[2]]==5)){assess_n=5
#	}else{if(any(data_n[3:dim(data_n)[2]]=="3A")){assess_n="3A"
#	}else{if(any(data_n[3:dim(data_n)[2]]=="3E")){assess_n="3E"
#	}else{if(all(data_n[3:dim(data_n)[2]]==2)){assess_n=2}}}}
#	AssessCat=append(AssessCat,assess_n)
#	}
#ru=cbind(ru,AssessCat)
#}
#
#
#
#
##Other rollup possibility
##MLID_list=unique(data$MLID)
##rolledup=matrix(nrow=0,ncol=6)
##colnames(rolledup)=c("MLID","AssessCat","CntCat2","CntCat3E","CntCat3A","CntCat5")
##for(n in 1:length(MLID_list)){
##	data_n=data[data$MLID==MLID_list[n],]
##	cat_counts=table(data_n$Cat)
##	if(any(data_n$Cat==5)){assess_n=5
##	}else{if(any(data_n$Cat=="3A")){assess_n="3A"
##	}else{if(any(data_n$Cat=="3E")){assess_n="3E"
##	}else{if(all(data_n$Cat==2)){assess_n=2}}}}
##	rolledup=rbind(rolledup,c(paste(MLID_list[n]),paste(assess_n),cat_counts))
##	}
##rolledup=data.frame(rolledup,row.names=NULL)
##return(rolledup)
#
#####################ELISE OLD CODE###############################
# Restrict to records without aggregating function (used for geometric means in Scenarios B and C)
# Aggregate by rec season year and determine max exceedance count for Scenario A
# data_48hr_check <- aggregate(ActivityStartDate~IR_MLID+BeneficialUse+Year, data=data_processed_max, FUN='maxSamps48hr')
# names(data_48hr_check)[names(data_48hr_check)=="ActivityStartDate"]<- "Ncount"
# data_48hr_check$ExcCountLim = ifelse(data_48hr_check$Ncount>=5,ceiling(data_48hr_check$Ncount*.1),1)
# 
# data_ScenA <- merge(data_48hr_check, data_processed_max, all=TRUE)
# data_ScenA$ExcCount = 0
# data_ScenA$ExcCount[data_ScenA$IR_Value>data_ScenA$NumericCriterion] = 1
# 
# # Obtain Scenario A Exc Counts for each MLID/Use/Year
# ScenarioA_agg <- aggregate(ExcCount~IR_MLID+BeneficialUse+Year+Ncount+ExcCountLim, data=data_ScenA, FUN=sum)
# ScenarioA_agg$Cat <- NA
# 
# ScenarioA <- within(ScenarioA_agg,{
#   Scenario = "A"
#   Cat[Ncount<5&ExcCount>ExcCountLim] = "idE"
#   Cat[Ncount<5&ExcCount<=ExcCountLim] = "idNE"
#   Cat[Ncount>=5&ExcCount<=ExcCountLim] = "ScenB"
#   Cat[Ncount>=5&ExcCount>ExcCountLim] = "NS"
# })

# ScenA_only <- ScenarioA[!ScenarioA$Cat=="ScenB",] # Assessed in ScenA (not FS)
# ScenB_mlids <- ScenarioA$IR_MLID[ScenarioA$Cat=="ScenB"] # Sent to ScenB (FS)
# ScenB_only <- ScenarioB[ScenarioB$IR_MLID%in%ScenB_mlids&!ScenarioB$Cat=="ScenC",] # Assessed in ScenB and not sent to ScenC
# ScenC_mlids <- ScenarioB$IR_MLID[ScenarioB$IR_MLID%in%ScenB_mlids&!ScenarioB$IR_MLID%in%ScenA_mlids&ScenarioB$Cat=="ScenC"] # MLIDS sent to ScenC from ScenB
# ScenC_only <- ScenarioC[ScenarioC$IR_MLID%in%ScenC_mlids,] # Assessed in ScenC
# 
# # Combine Scenarios
# ABC_assessments_lim <- rbind(ScenA_only,ScenB_only,ScenC_only)
# 
# # Isolate those with NS cats
# ABC_asmt_NS <- ABC_assessments_lim[ABC_assessments_lim$Cat=="NS",]
# 
# # Aggregate multiple years of NS cats to most recent year of NS
# if(dim(ABC_asmt_NS)[1]>0){
#   ABC_asmt_NS <- aggregate(Year~IR_MLID+BeneficialUse+Cat+Scenario,data=ABC_asmt_NS, FUN=max) 
# }
# NS_mlids <- unique(ABC_asmt_NS$IR_MLID)
# 
# # Remove MLIDs with NS cat(s)
# ABC_asmt_notNS <- ABC_assessments_lim[!ABC_assessments_lim$IR_MLID%in%NS_mlids,]
# 
# # Isolate those with idE cats
# ABC_asmt_idE <- ABC_asmt_notNS[ABC_asmt_notNS$Cat=="idE",]
# 
# # Aggregate multiple years of idE cats to most recent year of idE
# if(dim(ABC_asmt_idE)[1]>0){
#   ABC_asmt_idE <- aggregate(Year~IR_MLID+BeneficialUse+Cat+Scenario,data=ABC_asmt_idE, FUN=max) 
# }
# idE_mlids <- unique(ABC_asmt_idE$IR_MLID)
# 
# # Remove MLIDs with idE cat(s)
# ABC_asmt_notidE <- ABC_asmt_notNS[!ABC_asmt_notNS$IR_MLID%in%idE_mlids,]
# 
# # Aggregate multiple years of idNE and FS to most recent year, and choose that designation
# if(dim(ABC_asmt_notidE)[1]>0){
#   ABC_asmt_support <- aggregate(Year~IR_MLID+BeneficialUse+Cat+Scenario,data=ABC_asmt_notidE, FUN=max)
# }
# 
# 
