
### Make streamline volumes ###

### Pre: All template streamlines must have been made in dsi studio (these are the nii files)
### Post: fiber_volume_values.csv that contains the name of the fiber bundle and its volume
### Uses: Will be getting the volumes of the streamlines for use in later density analyses
### Dependencies: This script requires afni to be installed.

module load afni_openmp/20.1
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$LSB_DJOB_NUMPROC
num_cores=1

directory='/project/msdepression/templates/dti/HCP_YA1065_tractography/'
outfile=${directory}/fiber_volume_values.csv

#remove outfile if it exists
rm -f ${outfile}

#make the file again
touch ${outfile}
echo "fascicle,volume" >> ${outfile}
   
#go through each fiber, get volume, and store it in csv
fiber_bundle_type_list="association cerebellum cranial_nerve projection commissural"	
for fiber_bundle_type in ${fiber_bundle_type_list}; do
	echo "Fiber bundle type is " $fiber_bundle_type
fascicle_volumes=$(ls ${directory}/${fiber_bundle_type}/*.nii*)
        for fascicle in ${fascicle_volumes}; do
            fascicle_prefix=$(echo $fascicle | perl -pe 's/.*\/(.*).nii.*/$1/g')
            volume=$(3dmaskave -quiet -mask SELF -sum ${fascicle})
            echo "${fascicle_prefix},$volume" >> ${outfile}
        done
done

