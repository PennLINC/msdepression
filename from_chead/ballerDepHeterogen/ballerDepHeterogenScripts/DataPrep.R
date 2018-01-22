#################
### LOAD DATA ###
#################

#Demographic data (n=1629)
data.demo <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/demographics/n1601_demographics_go1_20161212.csv", header=TRUE) 

##Clinical data
#Screening diagnoses (n=1601)
data.diag <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/clinical/n1601_goassess_psych_summary_vars_20131014.csv", header=TRUE, na.strings=".")

#Bifactors and correlated traits (n=1601)
data.factors <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/clinical/n1601_goassess_clinical_factor_scores_20161212.csv", header=TRUE, na.strings=".")

#State trait anxiety data (n=1391)
data.stai <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/clinical/n1601_stai_pre_post_itemwise_smry_factors_20170131.csv", header=TRUE, na.strings=".")

#Exclusion data (n=1601)
#Health exclusion (use the new healthExcludev2 variable)
data.healthExclude <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/health/n1601_health_20170421.csv", header=TRUE, na.strings=".")

#T1 QA exclusion (n=1601)
data.t1QA <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/neuroimaging/t1struct/n1601_t1QaData_20170306.csv", header=TRUE, na.strings=".")

##################
#### DATA PREP ###
##################

#Transform the age variable from months to years
data.demo$age <- (data.demo$ageAtScan1)/12

#Recode male as 0 and female as 1
data.demo$sex[which(data.demo$sex==1)] <- 0
data.demo$sex[which(data.demo$sex==2)] <- 1

##################
### MERGE DATA ###
##################
dataMerge1 <-merge(data.demo,data.diag, by=c("bblid","scanid"), all=TRUE) 
dataMerge2 <-merge(dataMerge1,data.factors, by=c("bblid","scanid"), all=TRUE) 
dataMerge3 <-merge(dataMerge2,data.stai, by=c("bblid","scanid"), all=TRUE) 
dataMerge4 <-merge(dataMerge3,data.healthExclude, by=c("bblid","scanid"), all=TRUE)
dataMerge5 <-merge(dataMerge4,data.t1QA, by=c("bblid","scanid"), all=TRUE)

#Retain only the 1601 bblids (demographics has 1629)
data.n1601 <- dataMerge5[match(data.t1QA$bblid, dataMerge5$bblid, nomatch=0),] 

#Put bblids in ascending order
data.ordered <- data.n1601[order(data.n1601$bblid),]

#Count the number of subjects (should be 1601)
n <- nrow(data.ordered)

#################################
### APPLY EXCLUSIONS AND SAVE ### 
#################################
##Count the total number excluded for healthExcludev2=1 (1=Excludes those with medical rating 3/4, major incidental findings that distort anatomy, psychoactive medical medications)
#Included: n=1447; Excluded: n=154, but medical.exclude (n=81) + incidental.exclude (n=20) + medicalMed.exclude (n=64) = 165, so 11 people were excluded on the basis of two or more of these criteria
data.final <- data.ordered
data.final$ACROSS.INCLUDE.health <- 1
data.final$ACROSS.INCLUDE.health[data.final$healthExcludev2==1] <- 0
health.include<-sum(data.final$ACROSS.INCLUDE.health)
health.exclude<-1601-health.include

#Count the number excluded just medical rating 3/4 (GOAssess Medial History and CHOP EMR were used to define one summary rating for overall medical problems) (n=81)
data.final$ACROSS.INCLUDE.medical <- 1
data.final$ACROSS.INCLUDE.medical[data.final$medicalratingExclude==1] <- 0
medical.include<-sum(data.final$ACROSS.INCLUDE.medical)
medical.exclude<-1601-medical.include

#Count the number excluded for just major incidental findings that distort anatomy (n=20)
data.final$ACROSS.INCLUDE.incidental <- 1
data.final$ACROSS.INCLUDE.incidental[data.final$incidentalFindingExclude==1] <- 0
incidental.include<-sum(data.final$ACROSS.INCLUDE.incidental)
incidental.exclude<-1601-incidental.include

#Count the number excluded for just psychoactive medical medications (n=64)
data.final$ACROSS.INCLUDE.medicalMed <- 1
data.final$ACROSS.INCLUDE.medicalMed[data.final$psychoactiveMedMedicalv2==1] <- 0
medicalMed.include<-sum(data.final$ACROSS.INCLUDE.medicalMed)
medicalMed.exclude<-1601-medicalMed.include

#Subset the data to just the  that pass healthExcludev2 (n=1447)
data.subset <-data.final[which(data.final$ACROSS.INCLUDE.health == 1), ]

##Count the number excluded for failing to meet structural image quality assurance protocols
#Included: n=1396; Excluded: n=51
data.subset$ACROSS.INCLUDE.QA <- 1
data.subset$ACROSS.INCLUDE.QA[data.subset$t1Exclude==1] <- 0
QA.include<-sum(data.subset$ACROSS.INCLUDE.QA)
QA.exclude<-1447-QA.include

###Exclude those with ALL problems (health problems and problems with their t1 data) (included n=1396)
data.exclude <- data.subset[which(data.subset$healthExcludev2==0 & data.subset$t1Exclude == 0 ),]

#Demographics for the paper
meanAge<-mean(data.exclude$age)
sdAge<-sd(data.exclude$age)
rangeAge<-range(data.exclude$age)
genderTable<-table(data.exclude$sex)

#Save final dataset
saveRDS(data.exclude,"/data/joy/BBL/projects/pncNmf/subjectData/n1396_T1_subjData.rds")

#Save the bblids and scanids for the final sample (n=1396)
IDs <- c("bblid", "scanid")
bblidsScanids <- data.exclude[IDs]

#Remove header
names(bblidsScanids) <- NULL

#Save list
write.csv(bblidsScanids, file="/data/joy/BBL/projects/pncNmf/subjectData/n1396_T1_bblids_scanids.csv", row.names=FALSE)

############################
### SENSITIVITY ANALYSES ###
############################

#Count the number taking psychotropic psychiatric medications 
#Included: n=1240; Excluded: n=156
data.exclude$ACROSS.INCLUDE.psychMeds <- 1
data.exclude$ACROSS.INCLUDE.psychMeds[data.exclude$psychoactiveMedPsychv2==1] <- 0
psychMeds.include<-sum(data.exclude$ACROSS.INCLUDE.psychMeds)
psychMeds.exclude<-1396-psychMeds.include

#Exclude those who were on psychiatric medications (included n=1240)
data.sensitivity <- data.exclude[which(data.exclude$ACROSS.INCLUDE.psychMeds==1),]

#Save sensitivity dataset
saveRDS(data.sensitivity,"/data/joy/BBL/projects/pncNmf/subjectData/n1240_T1_subjData_NoPsychMeds.rds")
