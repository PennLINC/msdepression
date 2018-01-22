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

#divide groups into males and females

#males, n = 1555
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males <- subset.data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$sex == 1)

#females, n = 1729
subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females <- subset.data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED$sex == 2)

#get CNB measure names
cnb_measure_names <- names(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED)[grep("_z", names(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED))] #get the names of all the columns with _z in the name
#cnb_measure_names_lm <- paste0(cnb_measure_names, "_lm", sep='')
#cnb_measure_names_gam <- paste0(cnb_measure_names, "_gam", sep='')

####GAM comparing depressed with non-depressed, using Lapply.  Only looking at depression, binarized beyond this point 
#Also looking at males (n = 1555) and females (n = 1729) from this point on

#using gam, results stored in list
CNB_cog_score_stats_gam_dep_binarized_males <- lapply(cnb_measure_names, function(x) 
{
  gam(substitute(i ~ dep_binarized + age_in_years, list(i = as.name(x))), data = subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males)
}) 

CNB_cog_score_stats_gam_dep_binarized_females <- lapply(cnb_measure_names, function(x) 
{
  gam(substitute(i ~ dep_binarized + age_in_years, list(i = as.name(x))), data = subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females)
}) 

#add names for each list element
names(CNB_cog_score_stats_gam_dep_binarized_males) <- cnb_measure_names
names(CNB_cog_score_stats_gam_dep_binarized_females) <- cnb_measure_names

#####Only looking at gam models beyond this point#####
#Look at model summaries
models_gam_males <- lapply(CNB_cog_score_stats_gam_dep_binarized_males, summary)
models_gam_females <- lapply(CNB_cog_score_stats_gam_dep_binarized_females, summary)

#Pull p-values
p_gam_males <- sapply(CNB_cog_score_stats_gam_dep_binarized_males, function(v) summary(v)$p.table[2,4])
p_gam_females <- sapply(CNB_cog_score_stats_gam_dep_binarized_females, function(v) summary(v)$p.table[2,4])


#Convert to data frame
p_gam_males <- as.data.frame(p_gam_males)
p_gam_females <- as.data.frame(p_gam_females)

#Print original p-values to three decimal places
p_round_gam_males <- round(p_gam_males,3)
p_round_gam_females <- round(p_gam_females,3)

#FDR correct p-values
pfdr_gam_males <- p.adjust(p_gam_males[,1],method="fdr")
pfdr_gam_females <- p.adjust(p_gam_females[,1],method="fdr")

#Convert to data frame
pfdr_gam_males <- as.data.frame(pfdr_gam_males)
row.names(pfdr_gam_males) <- cnb_measure_names
pfdr_gam_females <- as.data.frame(pfdr_gam_females)
row.names(pfdr_gam_females) <- cnb_measure_names

#To print fdr-corrected p-values to three decimal places
pfdr_round_gam_males <- round(pfdr_gam_males,4)
pfdr_round_gam_females <- round(pfdr_gam_females,4)

#List the NMF components that survive FDR correction
CNB_fdr_gam_males <- row.names(pfdr_gam_males)[pfdr_gam_males<0.05]
CNB_fdr_gam_females <- row.names(pfdr_gam_females)[pfdr_gam_females<0.05]

#make a data frame with names and fdr values (rounded to 3 decimals)
CNB_names_and_fdr_values_gam_males <- data.frame(cbind(CNB_fdr_gam_males, round(pfdr_gam_males[pfdr_gam_males<0.05],4)))
CNB_names_and_fdr_values_gam_females <- data.frame(cbind(CNB_fdr_gam_females, round(pfdr_gam_females[pfdr_gam_females<0.05],4)))

#add titles to names_and_fdr tables
names(CNB_names_and_fdr_values_gam_males) <- c("CNB_measure", "p_FDR_corr")
names(CNB_names_and_fdr_values_gam_females) <- c("CNB_measure", "p_FDR_corr")

#write the results of the mass univariate stats to files
write.csv(CNB_names_and_fdr_values_gam_males, file = "/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/mass_univ_FDR_corrected_gam_males_n1555.csv")
write.csv(CNB_names_and_fdr_values_gam_females, file = "/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/mass_univ_FDR_corrected_gam_females_n1729.csv")

#checkmodel with visreg
lapply(CNB_cog_score_stats_gam_dep_binarized_males, function(x) {visreg(x)}) 
lapply(CNB_cog_score_stats_gam_dep_binarized_females, function(x) {visreg(x)}) 

#Make table 1 (demographics)
#subset demographics
listVars <- c("Race", "Maternal Ed", "Age", "Depression") #Race 1 = caucasian, Maternal Ed = years, age = years, dep 1 = dep, 0 = non_dep
#listVars <- c("Race", "Maternal Ed", "Age") #Race 1 = caucasian, Maternal Ed = years, age = years, dep 1 = dep, 0 = non_dep

subset_demographics_for_table1_males <- data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$race, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$medu1, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$age_in_years, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$dep_binarized)
names(subset_demographics_for_table1_males) <- c(listVars)
subset_demographics_for_table1_females <- data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$race, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$medu1, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$age_in_years, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$dep_binarized)
names(subset_demographics_for_table1_females) <- c(listVars)

#subset_demographics_for_table1_males <- data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$race, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$medu1, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$age_in_years)
#names(subset_demographics_for_table1_males) <- c(listVars)
#subset_demographics_for_table1_females <- data.frame(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$race, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$medu1, subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$age_in_years)
#names(subset_demographics_for_table1_females) <- c(listVars)

#Change categorical values to have names
subset_demographics_for_table1_males$Depression <- ifelse(subset_demographics_for_table1_males$Depression == 1, "Depressed", "Non-depressed")
subset_demographics_for_table1_males$Race <- ifelse(subset_demographics_for_table1_males$Race == "1", "Caucasian","Non-caucasian")
subset_demographics_for_table1_females$Depression <- ifelse(subset_demographics_for_table1_females$Depression == 1, "Depressed", "Non-depressed")
subset_demographics_for_table1_females$Race <- ifelse(subset_demographics_for_table1_females$Race == "1", "Caucasian","Non-caucasian")

#make variable list
table_titles_males <- c("Males Non-depressed", "Males depressed", "p-value")
table_titles_males <- c("Females Non-depressed", "Females depressed", "p-value")

#Define Categorical Variables
cat_variables <- c("Race", "Depression")
#cat_variables <- c("Race")

#create demographics table
#males depressed 262, non-depressed 1293
demographics_table_males <- CreateTableOne(vars = listVars, data = subset_demographics_for_table1_males, factorVars = cat_variables, strata = c("Depression"))
print(demographics_table_males, showAllLevels = TRUE)

#females depressed = 514, non-depressed 1215
demographics_table_females <- CreateTableOne(vars = listVars, data = subset_demographics_for_table1_females, factorVars = cat_variables, strata = c("Depression"))
print(demographics_table_females, showAllLevels = TRUE)


############
####Matching###
###By Race and by 
#Creating 0/1 vs. T/F variable for groups
dat_males<-mutate(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males, dep_binarized_males_TF=as.logical(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_males$dep_binarized=="1"))
dat_females<-mutate(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females, dep_binarized_females_TF=as.logical(subset_dep_or_no_psych_and_no_medicalratingExclude_DEPBINARIZED_females$dep_binarized=="1"))

#Alternative method
new <- dat_males$dep_binarized
data.frame(dat_males, new)

new <- dat_females$dep_binarized
data.frame(dat_females, new)

#Match
matchstats_males<-Match(Tr=dat_males$dep_binarized_males_TF, X=as.matrix(cbind(dat_males$race, dat_males$age_in_years)), replace=FALSE, ties=FALSE)
str(matchstats_males)

matchstats_females<-Match(Tr=dat_females$dep_binarized_females_TF, X=as.matrix(cbind(dat_females$race, dat_females$age_in_years)), replace=FALSE, ties=FALSE)
str(matchstats_females)

#Stiching together matched rows

#Total males: 262 dep, 262 non-dep (total: 524)
matchDep_males<-dat[matchstats_males$index.treated,]
matchNonDep_males<-dat[matchstats_males$index.control,]

match_males<-rbind(matchDep_males, matchNonDep_males)
match_males<-group_by(match_males, dep_binarized_males)
str(match_males)

#Total females 467 dep, 480 non-dep (total 947))
matchDep_females<-dat[matchstats_females$index.treated,]
matchNonDep_females<-dat[matchstats_females$index.control,]

match_females<-rbind(matchDep_females, matchNonDep_females)
match_females<-group_by(match_females, dep_binarized_females)
str(match_females)
#View(match_males)
#View(matchDep_males)
#View(matchNonDep_males)

#save(match, file="/Users/ericwpetersen/Desktop/Olfaction R Files/match.R")
##save(matchq22, file="/Users/ericwpetersen/Desktop/Olfaction R Files/matchq22.R")
#save(matchcontrol, file="/Users/ericwpetersen/Desktop/Olfaction R Files/matchcontrol.R")

###Matched Sample Description
#Demographics
#summary(match[,2:5])
summary(matchDep_males[,2:5])
summary(matchNonDep_males[,2:5])
summary(matchDep_females[,2:5])
summary(matchNonDep_females[,2:5])

#check results
t.test(matchDep_males$age_in_years, y=matchNonDep_males$age_in_years)
hist(matchDep_males$age_in_years)
hist(matchNonDep_males$age_in_years)
hist(matchDep_males$race)
hist(matchNonDep_males$race)

t.test(matchDep_females$age_in_years, y=matchNonDep_females$age_in_years)
hist(matchDep_females$age_in_years)
hist(matchNonDep_females$age_in_years)
hist(matchDep_females$race)
hist(matchNonDep_females$race)

save(match_males, file="/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/match_males R match_males.R")
save(match_females, file="/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/match_females R match_females.R")
save(matchDep_males, file="/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/matchDep_males R matchDep_males.R")
save(matchDep_females, file="/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/matchDep_females R matchDep_females.R")
save(matchNonDep_males, file="/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/matchNonDep_males R matchNonDep_males.R")
save(matchNonDep_females, file="/Users/eballer/BBL/from_chead/ballerDepHeterogen/results/matchNonDep_females R matchNonDep_females.R")

#save(matchcontrol, file="/Users/ericwpetersen/Desktop/Olfaction R Files/matchcontrol.R")


