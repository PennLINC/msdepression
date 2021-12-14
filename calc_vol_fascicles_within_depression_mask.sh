#### calculate volume of fascicles within the depression network ####
### Pre: All streamlines must have been made in dsi studio (these are the nii files)
### Post: A depression mask resampled to template space, file <streamline_volume_within_dep_network>, containing each fascicle and its corresponding % within depression network
### Uses: Trying to figure out which fascicles are in the depression network for dimensionality reduction for use in later regressions (i.e. decrease # comparisons by only looking at fascicles within depression network)
### Dependencies: This script requires afni to be installed (currently using 20.1)

#set outfile
outfile="/project/msdepression/results/streamline_volume_within_dep_network.csv"

#set template directories, will be making our resampled mask from within this
template="Depression_Clust_mask_roi_binarized.nii.gz"
template_dir="/project/msdepression/templates/harvard_depression"
resampled_filename="resampled_${template}"
template_fullpath="/project/msdepression/templates/harvard_depression/${template}"

#set fascicle directory
fascicle_direc="/project/msdepression/templates/dti/HCP_YA1065_tractography/"
fascicle_type="association"
fascicle_for_resampling="AF_L.nii.gz"

#set home directory
homedir="/project/msdepression/scripts/"

#initiate csvs
rm -f $outfile
touch $outfile
echo "fascicle,num_voxels_total,non_zero_voxels_in_dep_map,prop_in_mask" >> $outfile

#resample Depression_Clust_amsk_roi_binarized.nii.gz to match sample fascicle - AF_L.nii.gz
if [ -f "${template_dir}/${resampled_filename}" ]; then
	rm -f ${template_dir}/${resampled_filename}
fi
3dresample -master ${fascicle_direc}/${fascicle_type}/${fascicle_for_resampling} -prefix ${template_dir}/${resampled_filename} -input ${template_fullpath} -rmode NN

#go through each fiber, get volume, and store it in csv
fiber_bundle_type_list="association cerebellum cranial_nerve projection commissural"
for fiber_bundle_type in ${fiber_bundle_type_list}; do
    echo "Fiber bundle type is " $fiber_bundle_type
    fascicle_volumes=$(ls ${fascicle_direc}/${fiber_bundle_type}/*.nii* | grep -v "dep_mask") #list all files, exclude depression ones
    for fascicle in ${fascicle_volumes}; do
	    fascicle_prefix=$(echo $fascicle | perl -pe 's/.*\/(.*).nii.gz/$1/g')
	    num_voxels_whole_mask=$(3dmaskave -quiet -mask SELF -sum ${fascicle})

	    #remove previous mask if already made
	    if [ -f "${fascicle_direc}/${fascicle_type}/${fascicle_prefix}xdep_mask.nii.gz" ]; then
		    rm -f ${fascicle_direc}/${fascicle_type}/${fascicle_prefix}xdep_mask.nii.gz
	    fi

	    3dcalc -a ${template_dir}/${resampled_filename} -b ${fascicle} -expr 'a*b' -prefix ${fascicle_direc}/${fascicle_type}/${fascicle_prefix}xdep_mask.nii.gz
	    num_nonzero_volumes=$(3dmaskave -quiet -mask SELF -sum ${fascicle_direc}/${fascicle_type}/${fascicle_prefix}xdep_mask.nii.gz)
	    prop_in_mask=$(echo ${num_nonzero_volumes}/${num_voxels_whole_mask} | bc -l)
	    echo "num_voxels" $num_voxels_whole_mask "num_nonzero" $num_nonzero "prop_in_mask" $prop_in_mask

	    echo "${fascicle_prefix},${num_voxels_whole_mask},${num_nonzero_volumes},${prop_in_mask}" >> $outfile
    done
done

   
