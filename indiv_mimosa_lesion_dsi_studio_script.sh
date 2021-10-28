
### The Inner Script... Doing all the dsi studio action for each individual mimosa brain ###

### Pre: path to an individual's mimosa lesion in HCP/MNI space
### Post: Filtered tracts; ROA and ROI voxel maps/niftis that can be used for data analysis
### Uses: In trying to find a way to speed everything along, it made the most sense to separate this piece of the script out. 
#          - it takes a subject's mimosa path, and makes a fiber_tracking_map directory as well as sub directories for each bundle type
#          - it then runs ROA/ROI filtration and makes output maps. 

#set -euf -o pipefail
module load singularity
export PATH=${PATH}:/Applications/dsi_studio.app/Contents/MacOS/
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$LSB_DJOB_NUMPROC
num_cores=1

#set default directory/templates. This will change when we use local, personal dwi
template='/project/msdepression/templates/dti/HCP1065.1mm.fib.gz'
fascicle_directory='/project/msdepression/templates/dti/HCP_YA1065_tractography/'

if [ $# == 0 ]
then
    echo "You did not enter a file. Make sure your call makes sense"
else  
    lesion=$1

	echo "File being read is "$lesion
	echo "... Starting to make tracts"
# make directory within parent directory for tracts
    	parent_dir=$(echo ${lesion} | perl -pe s'/(.*)\/.*/$1/g')
    	echo "$parent_dir"
	mask_prefix=$(echo ${lesion} | perl -pe s'/(.*)\/(.*).nii.gz/$2/g')
    	echo $mask_prefix
	if [ ! -d $parent_dir/fiber_tracking_maps ] 
    	then
        	mkdir $parent_dir/fiber_tracking_maps
    	fi

    #make sub directories for each bundle type, so within fiber_tracking_maps, there will be subdirectories for each type of map
	fiber_bundle_type_list="association cerebellum cranial_nerve projection commissural"	
    	for fiber_bundle_type in ${fiber_bundle_type_list}; do
        	echo "Fiber bundle type is " $fiber_bundle_type
        	echo "making directory" $parent_dir/fiber_tracking_maps/$fiber_bundle_type
        	mkdir $parent_dir/fiber_tracking_maps/$fiber_bundle_type
        	fascicles=$(ls ${fascicle_directory}/${fiber_bundle_type}/*.tt.gz)
    

	# set a job counter to be used to name the jobs
		job_count=1
		for fascicle in ${fascicles}; do
            		echo "Fascicle is  " $fascicle
            		fascicle_root_name=$(echo $fascicle | perl -pe s'/(.*)\/(.*).tt.gz/$2/g') 
   			echo  "Fascicle root name is ${fascicle_root_name}" 
    	    		singularity exec --bind /project /project/singularity_images/dsistudio_latest.sif dsi_studio --action=ana --source=$template --tract=$fascicle --roa=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_lesioned_ROA.tt.gz
            		singularity exec --bind /project /project/singularity_images/dsistudio_latest.sif dsi_studio --action=ana --source=$template --tract=$fascicle --roi=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_lesioned_ROI.tt.gz
           
     			singularity exec --bind /project /project/singularity_images/dsistudio_latest.sif dsi_studio --action=ana --source=$template --tract=$fascicle --roa=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_lesioned_ROA.nii.gz
           		singularity exec --bind /project /project/singularity_images/dsistudio_latest.sif dsi_studio --action=ana --source=$template --tract=$fascicle --roi=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_lesioned_ROI.nii.gz
 
		# I have removed this line to save space. All hcp fibers are in the directory: /project/msdepression/templates/dti/HCP_YA1065_tractography/ . Can uncomment this if at some point I need to make them for each individual, like when we have their personal DWI
#singularity exec --bind /project /project/singularity_images/dsistudio_latest.sif dsi_studio --action=ana --source=$template --tract=$fascicle --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_full.tt.gz
			((job_count+=1))
		done
    	done
fi
