### Make streamline volumes ###

### Pre: All streamlines must have been made in dsi studio (these are the nii files)
### Post: One csv that contains the name of the streamline as one column, and the volume of the streamline in a second column, separated by a ','
### Uses: Will be getting the volumes of the streamlines for use in later density analyses
### Dependencies: This script requires afni to be installed.

#module load afni

#module load singularity
#export PATH=${PATH}:/Applications/dsi_studio.app/Contents/MacOS/
#export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$LSB_DJOB_NUMPROC
num_cores=1

#set default directory/templates. This will change when we use local, personal dwi
#template='/project/msdepression/templates/dti/HCP1065.1mm.fib.gz'
#fascicle_directory='/project/msdepression/templates/dti/HCP_YA1065_tractography/'
fascicle_directory='/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/'

output_csv="${fascicle_directory}/fiber_volume_values.csv"

#initiate csv
rm -f $output_csv
touch $output_csv
echo "fascicle,volume" >> $output_csv
#if [ $# == 0 ]
#then
 #   echo "You did not enter a file. Make sure your call makes sense"
  #  echo "for now, using default $fascicle_directory"
 #else  
 #   lesion=$1
    #parent_dir=$(echo ${lesion} | perl -pe s'/(.*)\/.*/$1/g')
    parent_dir=${fascicle_directory}
#	echo "File being read is "$l
#	echo "... Starting to make tracts"
# make directory within parent directory for tracts
   
    echo "$parent_dir"
	#mask_prefix=$(echo ${lesion} | perl -pe s'/(.*)\/(.*).nii.gz/$2/g')
    #echo $mask_prefix
	#if [ ! -d $parent_dir/fiber_tracking_maps ] 
    #	then
     #   	mkdir $parent_dir/fiber_tracking_maps
    #	fi

    #make sub directories for each bundle type, so within fiber_tracking_maps, there will be subdirectories for each type of map
	fiber_bundle_type_list="association cerebellum cranial_nerve projection commissural"	
    	for fiber_bundle_type in ${fiber_bundle_type_list}; do
        	echo "Fiber bundle type is " $fiber_bundle_type
        	#echo "making directory" $parent_dir/fiber_tracking_maps/$fiber_bundle_type
           # echo "making directory" $parent_dir/$fiber_bundle_type
        	#mkdir $parent_dir/fiber_tracking_maps/$fiber_bundle_type
        	fascicle_volumes=$(ls ${fascicle_directory}/${fiber_bundle_type}/*.nii.gz)
            for fascicle in ${fascicle_volumes}; do
                fascicle_prefix=$(echo $fascicle | perl -pe 's/.*\/(.*).nii.gz/$1/g')
                volume=$(3dmaskave -quiet -mask SELF -sum ${fascicle})
                echo "${fascicle_prefix}, $volume" >> $output_csv
            done
        done

