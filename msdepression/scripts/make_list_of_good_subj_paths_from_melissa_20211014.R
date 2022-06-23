library(dplyr)
melissa_file <- read.csv("/Users/eballer/BBL/msdepression/data/melissa_martin_files/csv/1yr_report_address.csv", sep = ",", header = T)

#remove rows who have a score of below 75 in column $rating
pass_qc <- melissa_file[melissa_file$rating>=75.0,]

#make a new column to indicate whether the scan has mimosa or is t1_n4_brain.nii.gz
pass_qc$mimosa_or_t1 = 0

#assign 1s if patient has pattern mimosa_binary_mask_0.25.nii.gz or t1_n4_brain.nii.gz
pass_qc$mimosa_or_t1[grep(pattern = "mimosa_binary_mask_0.25.nii.gz", x = pass_qc$scan)] <- 1 #n = 2365
pass_qc$mimosa_or_t1[grep(pattern = "t1_n4_brain.nii.gz", x = pass_qc$scan)] <- 1 #added 672, new n = 3037

new_df <- pass_qc[pass_qc$mimosa_or_t1 == 1, ]
