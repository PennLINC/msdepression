#!/bin/bash

#### Welcome to the Region_making party #########
### Pre: Must have a file with full paths to the lesioned data 
### Post: Within each directory specified by the lesioned data, will have a directory that has all tractography (ROA, ROI, Full)
### Uses: For use in MS depression - take a subject's mimosa lesions and generate the fiber tracts (individual fascicles) that run through it
#dependencies: Using dsi studio from docker, sif created by Tim 10/26/2021
#export PATH=${PATH}:/Applications/dsi_studio.app/Contents/MacOS/
set -euf -o pipefail

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$LSB_DJOB_NUMPROC
num_cores=1

#set default paths 
template='/project/msdepression/templates/dti/HCP1065.1mm.fib.gz'
default='/project/msdepression/data/melissa_martin_files/csv/mimosa_binary_masks_hcp_space_20211026_n2336'
#default='/project/msdepression/data/melissa_martin_files/csv/erica_mini_mimosa_paths_n3'
fascicle_directory='/project/msdepression/templates/dti/HCP_YA1065_tractography/'

if [ $# == 0 ]
then
    echo "We will use the default mimosa path file" $default
    lesion_file=$default
else  
    lesion_file=$1
fi
echo "File being read is "$lesion_file
echo "... Starting to make lesions ..."

lesion_paths=$(cat $lesion_file)

# loop through each mimosa lesion map; lesion paths contain full paths to mimosa files in hcp space
job_count=1
for lesion in ${lesion_paths}; do
	echo "working on ${lesion} ..."  
	bsub -J "job_${job_count}" -n ${num_cores} -o /project/msdepression/scripts/logfiles/out_roa_${job_count}.out /project/msdepression/scripts/indiv_mimosa_lesion_dsi_studio_script.sh $lesion
   	((job_count+=1))
done
