#!/bin/bash

##### Welcome to make_afni_map_w_fascicles_colored_by_prop_overlap ###
### Pre: A file that has two columns, no headers. First column is the abbreviation of a fascicle, second is proportion overlap (or volume overlap)
### Post: A nifti where each fascicle is colored by the proportion of overlap, or any value you give it
### Uses: I wanted to find a way to show, in a brain, which fascicles have the most overlap with lesions (though this can be done w/depression, non-dep, volume). This will go through a table, and for each fascicle, multiply it times the value in the second column, add a suffix, and then at the end, sum them all to make a final image
### Dependencies: Afni

#change this if doing on pmacs
homedir="/Users/eballer/BBL/msdepression/"

default=${homedir}/results/fascicle_mean_proportion_overlap_nfasc_77.csv
default_suffix="prop"

if [ $# == 0 ]
then
	echo "We will use the default path file" $default
    	echo "We will use the default suffix " $default_suffix
    	fascicle_file=${default}
	suffix=${default_suffix}

else  
	fascicle_file=$1
	suffix=$2
fi


echo "File being read is "$fascicle_file
echo "Suffix being used is " $suffix

fascicles=$(cat $fascicle_file)

cd ${homedir}/templates/dti/HCP_YA1065_tractography/niftis_excluding_cranial_nerves

(pwd)
for fascicle in ${fascicles}; do
	# extract fascicle name and value
	fascicle_name=$(echo ${fascicle} | perl -pe 's/(.*),.*/$1/')
	fascicle_value=$(echo ${fascicle} | perl -pe 's/.*,(.*)/$1/')
	
	# remove nifti w/values if already there
	rm -rf ${fascicle_name}_${suffix}.nii.gz

	#take the fascicle .nii, multiply it with the value
	command=$(echo 3dcalc -a ${fascicle_name}.nii.gz -expr \'a*${fascicle_value}\' -prefix ${fascicle_name}_${suffix}.nii.gz)
	echo "Here is the command: "${command}
	
	#run command, have to do separately to get variable into afni command
	eval "${command}";
done

#remove old file
rm -rf fascicle_${suffix}_sum.nii.gz
rm -rf fascicle_${suffix}_max.nii.gz
 
all_files=$(ls *${suffix}.nii.gz)

#take sum
command_sum=$(3dMean -prefix fascicle_${suffix}_sum.nii.gz -sum ${all_files})
eval "${command_sum}";

#take max
command_max=$(3dMean -prefix fascicle_${suffix}_max.nii.gz -max ${all_files})
eval "${command_max}";

cd ${homedir}/scripts
