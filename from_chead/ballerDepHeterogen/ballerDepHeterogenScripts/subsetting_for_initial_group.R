#install.packages("visreg")
#################################################
#### Get subset for Baller_Dep_Heterogeneity ####
#################################################

#load libraries
library("visreg")
library(mgcv)

#read in csvs
demographics <- read.csv("/Users/test/BBL/projects/ballerDepHeterogen/data/n9498_demographics_go1_20161212.csv", header = TRUE, sep = ",")
cnb_scores <- read.csv("/Users/test/BBL/projects/ballerDepHeterogen/data/n9498_cnb_zscores_fr_20170202.csv", header = TRUE, sep = ",")
health <- read.csv("/Users/test/BBL/projects/ballerDepHeterogen/data/n9498_health_20170405.csv", header = TRUE, sep = ",")
psych_summary <- read.csv("/Users/test/BBL/projects/ballerDepHeterogen/data/n9498_goassess_psych_summary_vars_20131014.csv", header = TRUE, sep = ",")

#remove people with NA for race, age, or sex.  START WITH N = 9498
demographics_noNA_race <- demographics[!is.na(demographics$race),] #everyone has a race, N = 9498
demographics_noNA_race_age <- demographics_noNA_race[!is.na(demographics_noNA_race$ageAtClinicalAssess1),] # 86 people do not have age at clinical assessment.  N = 9412
demographics_noNA_race_age_sex <- demographics_noNA_race_age[!is.na(demographics_noNA_race_age$sex),] #everyone has a sex, N = 9412
demographics_noNA_race_age_andCNBage_sex <- demographics_noNA_race_age_sex[!is.na(demographics_noNA_race_age_sex$ageAtCnb1),] #6 people do not have ageAtCnb1, N = 9406

#remove people with NA for depression or total psych score, START WITH N = 9498
psych_summary_no_NA_dep <- psych_summary[!is.na(psych_summary$smry_dep),] #take out those with NA for depression, 87 people N = 9411
psych_summary_no_NA_dep_and_smry_psych_overall <- psych_summary_no_NA_dep[!is.na(psych_summary_no_NA_dep$smry_psych_overall_rtg),] #take out those with NA for overall psych rtg, no additional people lost, N = 9411

#merge the csvs
#dem_cnb <- merge(demographics, cnb_scores, by = "bblid") #merge demographics and cnb #this is if we want to include people without full demographic data
dem_cnb <- merge(demographics_noNA_race_age_andCNBage_sex, cnb_scores, by = "bblid") #merge demographics and cnb, N = 9406
psych_health <- merge(psych_summary_no_NA_dep_and_smry_psych_overall, health, by = "bblid") #merge psych and health, N = 9411
dem_cnb_psych_health_merged <- merge (dem_cnb, psych_health, by = "bblid") #merge all 4 csvs, lost 1 person [134716] (had demographics, but no psych ratings): N = 9405

#make subsets
subset_just_dep_and_no_medicalratingExclude <- subset.data.frame(dem_cnb_psych_health_merged, (medicalratingExclude == 0) & (smry_dep == 4), select = "bblid") #subset people who were not medically excluded and who are depressed, N = 776
subset_no_psych_no_medicalratingExclude <- subset.data.frame(dem_cnb_psych_health_merged, (medicalratingExclude == 0) & (smry_psych_overall_rtg < 4), select = "bblid") #subset people who are psychiatrically healthy, N = 2508
subset_dep_or_no_psych_and_no_medicalratingExclude <- subset.data.frame(dem_cnb_psych_health_merged, (medicalratingExclude == 0) & ((smry_dep == 4) | (smry_psych_overall_rtg <4))) #subset including both depressed and healthies, good for regressions, N = 3284

#would binarize depression smry score to 0 and 1-- 4 and <4
dep_binarized <- ifelse(subset_dep_or_no_psych_and_no_medicalratingExclude$smry_dep == 4, 1, 0)
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED <- cbind(subset_dep_or_no_psych_and_no_medicalratingExclude, dep_binarized) #N = 3284

#test LM
lmTest_dep<- lm(adi_z~smry_dep + sex +ageAtCnb1,data=subset_dep_or_no_psych_and_no_medicalratingExclude)  #use a gam not a linear model
summary(lmTest_dep)
lmTest_dep_binarized <- lm(adi_z~dep_binarized + sex +ageAtCnb1,data=subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED)  #use a gam not a linear model
summary(lmTest_dep_binarized)

#would
#1)use gam and visreg to see effects on single columns
#2) try with a for loop
#3) try with an apply function-- can get code from toni
#4) try with `voxel` wrapper


#GLM between dep/non_dep
#first, lets make a vector with names of the cnb_scores
cnb_all_headings <- c(colnames(cnb_scores))
cnb_summary_vector <- cnb_all_headings[4:29]
#cnb_score_only_headings <- data.frame(cnb_all_headings[4:29])

#make lists and vectors to save output of linear models
resultsList <- list() #make a list for results of LM to go into
resultsList_DEPBINARIZED <- list() #make a list for results of LM to go into (binarized)
results_dep_pvalues <- vector() #make vector for p values for dep non-binarized
results_dep_binarized_pvalues <- vector() #make vector for p values with dep binarized



#for loop to go through each score, run lm, and then store all results and p value in subsequent list and vector
for (score in cnb_summary_vector) { # loop through each score 
  #non-binarized (i.e., dep coded as 1 through 4)
  linear_model_dep<- lm(subset_dep_or_no_psych_and_no_medicalratingExclude[[score]]~ smry_dep + sex +ageAtCnb1,data=subset_dep_or_no_psych_and_no_medicalratingExclude)  #linear model
  
  #store NON_BINARIZED results in list, and extract p values and put in a vector
  resultsList[[score]] <- linear_model_dep #store lm results in resultsList
  results_dep_pvalues[[score]] <- summary(linear_model_dep)$coefficients[2,4] #extract lm p value and put in vector
   
  #binarized (i.e. dep coded as 0 (for dep 1-3) or 1 (for dep == 4))
  linear_model_dep_binarized<- lm(subset_dep_or_no_psych_and_no_medicalratingExclude[[score]]~ dep_binarized + sex +ageAtCnb1,data=subset_dep_or_no_psych_and_no_medicalratingExclude)  #linear model

  #store BINARIZED results in list, and extract p values and put in a vector
  resultsList_DEPBINARIZED[[score]] <- linear_model_dep_binarized #store lm results in resultsList
  results_dep_binarized_pvalues[[score]] <- summary(linear_model_dep_binarized)$coefficients[2,4] #extract lm p value and put in vector
  
}

#make lists and vectors to save output of general additive models (GAM)

gam_resultsList <- list() #make a list for results of LM to go into
gam_resultsList_DEPBINARIZED <- list() #make a list for results of LM to go into (binarized)
gam_results_dep_pvalues <- vector() #make vector for p values for dep non-binarized
gam_results_dep_binarized_pvalues <- vector() #make vector for p values with dep binarized

#for loop to go through each score, run gam, and then store all results and p value in subsequent list and vector
for (score in cnb_summary_vector) { # loop through each score 
  #non-binarized (i.e., dep coded as 1 through 4)
  gam_model_dep <- gam(subset_dep_or_no_psych_and_no_medicalratingExclude[[score]]~ smry_dep + sex +ageAtCnb1,data=subset_dep_or_no_psych_and_no_medicalratingExclude)  #gam model
  
  #store NON_BINARIZED results in list, and extract p values and put in a vector
  gam_resultsList[[score]] <- gam_model_dep #store gam results in resultsList
  gam_results_dep_pvalues[[score]] <- summary(gam_model_dep)$p.table[2,4] #extract gam p value and put in vector
  
  #binarized (i.e. dep coded as 0 (for dep 1-3) or 1 (for dep == 4))
  gam_model_dep_binarized<- gam(subset_dep_or_no_psych_and_no_medicalratingExclude[[score]]~ dep_binarized + sex +ageAtCnb1,data=subset_dep_or_no_psych_and_no_medicalratingExclude)  #gam model
  
  #store BINARIZED results in list, and extract p values and put in a vector
  gam_resultsList_DEPBINARIZED[[score]] <- gam_model_dep_binarized #store gam results in resultsList
  gam_results_dep_binarized_pvalues[[score]] <- summary(gam_model_dep_binarized)$p.table[2,4] #extract gam p value and put in vector
  
}


#obtain just bblids if they are needed
bblid_dep <- subset_just_dep_and_no_medicalratingExclude$bblid #just bblids from dep group
bblid_no_psych <- subset_no_psych_no_medicalratingExclude$bblid

#write new csvs
write.csv(x = subset_just_dep_and_no_medicalratingExclude, file = "/Users/test/BBL/projects/ballerDepHeterogen/data/subset_just_dep_and_no_medicalratingExclude.csv", na = "NA")
write.csv(x = subset_no_psych_no_medicalratingExclude, file = "/Users/test/BBL/projects/ballerDepHeterogen/data/subset_no_psych_no_medicalratingExclude.csv", na = "NA")
write.csv(x = subset_dep_or_no_psych_and_no_medicalratingExclude, file = "/Users/test/BBL/projects/ballerDepHeterogen/data/subset_dep_or_no_psych_and_no_medicalratingExclude.csv", na = "NA")

#write files with bblids
write(x = bblid_dep, file = "/Users/test/BBL/projects/ballerDepHeterogen/data/bblid_dep.txt", ncolumns = 1)
write(x = bblid_no_psych, file = "/Users/test/BBL/projects/ballerDepHeterogen/data/bblid_no_psych.txt", ncolumns = 1)
