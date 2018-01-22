#install.packages("visreg")
#install.packages("mgcv")
#install.packages("tableone")
#################################################
#### Get subset for Baller_DepHeterogeneity ####
#################################################

#This does the subsetting, runs statistics with lapply instead of loop, visualizes progress with visreg, and does fdr correction
# it then makes table 1 (demographics)
#load libraries
library(visreg)
library(mgcv)
library(tableone)

#read in csvs
demographics <- read.csv("/Users/eballer/BBL/from_chead/ballerDepHeterogen/data/n9498_demographics_go1_20161212.csv", header = TRUE, sep = ",") #from /data/joy/BBL/projects/ballerDepHeterogen/data/n9498_demographics_go1_20161212.csv
cnb_scores <- read.csv("/Users/eballer/BBL/from_chead/ballerDepHeterogen/data/n9498_cnb_zscores_fr_20170202.csv", header = TRUE, sep = ",") #from /data/joy/BBL/projects/ballerDepHeterogen/data/n9498_cnb_zscores_fr_20170202.csv
health <- read.csv("/Users/eballer/BBL/from_chead/ballerDepHeterogen/data/n9498_health_20170405.csv", header = TRUE, sep = ",") #from /data/joy/BBL/projects/ballerDepHeterogen/data/n9498_health_20170405.csv
psych_summary <- read.csv("/Users/eballer/BBL/from_chead/ballerDepHeterogen/data/n9498_goassess_psych_summary_vars_20131014.csv", header = TRUE, sep = ",") #from /data/joy/BBL/projects/ballerDepHeterogen/data/n9498_goassess_psych_summary_vars_20131014.csv

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

#would binarize depression smry score to 0 (less than 4, not depressed) and 1 (score 4 , depressed)
dep_binarized <- ifelse(subset_dep_or_no_psych_and_no_medicalratingExclude$smry_dep == 4, 1, 0)
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED <- cbind(subset_dep_or_no_psych_and_no_medicalratingExclude, dep_binarized) #N = 3284

#make depression and gender into factor scores
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$dep_binarized <- as.factor(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$dep_binarized)
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$sex <- as.factor(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$sex)

#divide ageAtCNB by 12 for age
age_in_years <- subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$ageAtCnb1/12
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED <- cbind(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED, age_in_years)

#would
#1) use gam and visreg to see effects on single columns CHECK
#2) try with a for loop CHECK
#3) try with an apply function-- can get code from toni CHECK
#4) try with `voxel` wrapper -> NOT imaging data... stuck on this part


#get CNB measure names
cnb_measure_names <- names(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED)[grep("_z", names(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED))] #get the names of all the columns with _z in the name
#cnb_measure_names_lm <- paste0(cnb_measure_names, "_lm", sep='')
#cnb_measure_names_gam <- paste0(cnb_measure_names, "_gam", sep='')

####GLM/GAM comparing depressed with non-depressed, using Lapply.  Only looking at depression, binarized beyond this point 

#using lm, results stored in list
CNB_cog_score_stats_lm_dep_binarized <- lapply(cnb_measure_names, function(x) 
{
  lm(substitute(i ~ dep_binarized + sex + age_in_years, list(i = as.name(x))), data = subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED)
})

#using gam, results stored in list
CNB_cog_score_stats_gam_dep_binarized <- lapply(cnb_measure_names, function(x) 
{
  gam(substitute(i ~ dep_binarized + sex + age_in_years, list(i = as.name(x))), data = subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED)
}) 

#add names for each list element
names(CNB_cog_score_stats_lm_dep_binarized) <- cnb_measure_names
names(CNB_cog_score_stats_gam_dep_binarized) <- cnb_measure_names

#####Only looking at gam models beyond this point#####
#Look at model summaries
models_lm <- lapply(CNB_cog_score_stats_lm_dep_binarized, summary)
models_gam <- lapply(CNB_cog_score_stats_gam_dep_binarized, summary)

#Pull p-values
p_lm <- sapply(CNB_cog_score_stats_lm_dep_binarized, function(v) summary(v)$coef[,"Pr(>|t|)"][2]) #get the p value for dep binarized
p_gam <- sapply(CNB_cog_score_stats_gam_dep_binarized, function(v) summary(v)$p.table[2,4])

#Convert to data frame
p_lm <- as.data.frame(p_lm)
p_gam <- as.data.frame(p_gam)

#Print original p-values to three decimal places
p_round_lm <- round(p_lm,3)
p_round_gam <- round(p_gam,3)

#FDR correct p-values
pfdr_lm <- p.adjust(p_lm[,1],method="fdr")
pfdr_gam <- p.adjust(p_gam[,1],method="fdr")

#Convert to data frame
pfdr_lm <- as.data.frame(pfdr_lm)
row.names(pfdr_lm) <- cnb_measure_names
pfdr_gam <- as.data.frame(pfdr_gam)
row.names(pfdr_gam) <- cnb_measure_names

#To print fdr-corrected p-values to three decimal places
pfdr_round_lm <- round(pfdr_lm,3)
pfdr_round_gam <- round(pfdr_gam,3)

#List the NMF components that survive FDR correction
CNB_fdr_lm <- row.names(pfdr_lm)[pfdr_lm<0.05]
CNB_fdr_gam <- row.names(pfdr_gam)[pfdr_gam<0.05]

#make a data frame with names and fdr values (rounded to 3 decimals)
CNB_names_and_fdr_values_lm <- data.frame(cbind(CNB_fdr_lm, round(pfdr_lm[pfdr_lm<0.05],3)))
CNB_names_and_fdr_values_gam <- data.frame(cbind(CNB_fdr_gam, round(pfdr_gam[pfdr_gam<0.05],3)))

#add titles to names_and_fdr tables
names(CNB_names_and_fdr_values_lm) <- c("CNB_measure", "p_FDR_corr")
names(CNB_names_and_fdr_values_gam) <- c("CNB_measure", "p_FDR_corr")

#write the results of the mass univariate stats to files
write.csv(CNB_names_and_fdr_values_lm, file = "/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/n3284_dep776_nondep2508_mass_univ_FDR_corrected_lm_20171211.csv")
write.csv(CNB_names_and_fdr_values_gam, file = "/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/n3284_dep776_nondep2508_mass_univ_FDR_corrected_gam_20171211.csv")

#checkmodel with visreg
lapply(CNB_cog_score_stats_lm_dep_binarized, function(x) {visreg(x)}) 
lapply(CNB_cog_score_stats_gam_dep_binarized, function(x) {visreg(x)}) 

#Make table 1 (demographics)
#subset demographics
subset_demographics_for_table1 <- data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$sex, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$race, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$medu1, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$age_in_years, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$dep_binarized)
listVars <- c("Gender", "Race", "Maternal Ed", "Age") #Gender 1 = male, 2 = female, Race 1 = caucasian, Maternal Ed = years, age = years, dep 1 = dep, 0 = non_dep
names(subset_demographics_for_table1) <- c(listVars, "Depression")

#Change categorical values to have names
subset_demographics_for_table1$Gender <- ifelse(subset_demographics_for_table1$Gender == 1, "Male", "Female")
subset_demographics_for_table1$Depression <- ifelse(subset_demographics_for_table1$Depression == 1, "Depressed", "Non-depressed")
subset_demographics_for_table1$Race <- ifelse(subset_demographics_for_table1$Race == "1", "Caucasian","Non-caucasian")

#make variable list
table_titles <- c("Non-depressed", "depressed", "p-value")

#Define Categorical Variables
cat_variables <- c("Gender", "Race", "Depression")

#create demographics table
demographics_table <- CreateTableOne(vars = listVars, data = subset_demographics_for_table1, factorVars = cat_variables, strata = c("Depression"))
print(demographics_table, showAllLevels = TRUE)

