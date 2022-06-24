#### calculate volume of fascicles within the yeo 7 networks ####
### Pre: All streamlines must have been made in dsi studio (these are the nii files)
### Post: Yeo7 network mask resampled to template space, file <streamline_volume_within_${network}_network>, containing each fascicle and its corresponding % within yeo networ. Additionally, will have a file that contains all of the overlaps per each network, and another with a binarized (yes/no)k
### Uses: Trying to figure out which fascicles are in the yeo 7 network for dimensionality reduction for use in later regressions (i.e. decrease # comparisons by only looking at fascicles within yeo 7 networks)
### Dependencies: This script requires afni to be installed (currently using 20.1)

#output directory
outdir="/project/msdepression/results/"

#assemble yeo 7 networks

yeo_7_net_list=("VIS"
                "MOT"
                "DA"
                "VA"
                "LIM"
                "FP"
                "DM")

#set up output file names
all_net_overlap_proportions="${outdir}/yeo_7_network_overlap_proportions.txt"
all_net_overlap_proportions_binarized="${outdir}/yeo_7_network_overlap_proportions_binarized.txt"

#set counter to keep track of whether it is the first iteration (and you need to do a special column add), or just take the last line and pr it
counter=1
for network in "${yeo_7_net_list[@]}"; do
	#set outfile
	outfile="/project/msdepression/results/streamline_volume_within_${network}_network.csv"

	#set template directories, will be making our resampled mask from within this
	template="yeo_7_net_${network}.nii"
	template_dir="/project/msdepression/templates/Yeo_JNeurophysiol11_MNI152/"
	resampled_filename="resampled_${template}"
	template_fullpath="${template_dir}/${template}"

	#set fascicle directory
	fascicle_direc="/project/msdepression/templates/dti/HCP_YA1065_tractography/"
	fascicle_type="association"
	fascicle_for_resampling="AF_L.nii.gz"

	#set home directory
	homedir="/project/msdepression/scripts/"

	#initiate csvs
	rm -f $outfile
	touch $outfile
	echo "fascicle,num_voxels_total,non_zero_voxels_in_${network}_map,prop_in_mask_${network}" >> $outfile

	#resample yeo_7_net_${network}.nii to match sample fascicle - AF_L.nii.gz
	if [ -f "${template_dir}/${resampled_filename}" ]; then
		rm -f ${template_dir}/${resampled_filename}
	fi
	3dresample -master ${fascicle_direc}/${fascicle_type}/${fascicle_for_resampling} -prefix ${template_dir}/${resampled_filename} -input ${template_fullpath} -rmode NN

	#go through each fiber, get volume, and store it in csv
	fiber_bundle_type_list="association cerebellum cranial_nerve projection commissural"
	for fiber_bundle_type in ${fiber_bundle_type_list}; do
	    echo "Fiber bundle type is " $fiber_bundle_type
	    fascicle_volumes=$(ls ${fascicle_direc}/${fiber_bundle_type}/*.nii* | grep -v "_mask") #list all files, exclude ones with mask in them
	    for fascicle in ${fascicle_volumes}; do
		    fascicle_prefix=$(echo $fascicle | perl -pe 's/.*\/(.*).nii.gz/$1/g')
		    num_voxels_whole_mask=$(3dmaskave -quiet -mask SELF -sum ${fascicle})

		    #remove previous mask if already made
		    if [ -f "${fascicle_direc}/${fascicle_type}/${fascicle_prefix}x${network}_mask.nii.gz" ]; then
			    rm -f ${fascicle_direc}/${fascicle_type}/${fascicle_prefix}x${network}_mask.nii.gz
		    fi

		    3dcalc -a ${template_dir}/${resampled_filename} -b ${fascicle} -expr 'a*b' -prefix ${fascicle_direc}/${fascicle_type}/${fascicle_prefix}x${network}_mask.nii.gz
		    num_nonzero_volumes=$(3dmaskave -quiet -mask SELF -sum ${fascicle_direc}/${fascicle_type}/${fascicle_prefix}x${network}_mask.nii.gz)
		    prop_in_mask=$(echo ${num_nonzero_volumes}/${num_voxels_whole_mask} | bc -l)
		    echo "num_voxels" $num_voxels_whole_mask "num_nonzero" $num_nonzero "prop_in_mask" $prop_in_mask
		    echo "${fascicle_prefix},${num_voxels_whole_mask},${num_nonzero_volumes},${prop_in_mask}" >> $outfile
	    done
	done

	#add column to output file
	if [ ${counter} == 1 ]; then
		#remove the file if it exists
		rm -rf ${all_net_overlap_proportions}
		#take the 1st and 4th columns and write new file
		cat ${outfile} | cut -d ',' -f 1,4 > ${all_net_overlap_proportions} 
	else
		#paste the last column into the building table
		cat $outfile | cut -d ',' -f 4 > to_add.txt
		pr -mts, ${all_net_overlap_proportions} to_add.txt > temp.txt

		#remove to_add file
		rm to_add.txt

		#move temp to the file, so everything is up to date
		mv temp.txt ${all_net_overlap_proportions}
		
	fi
	((counter++))
done

#binarize the all_net_overlap_proportions file, takes every value and puts a 0 - this takes the ,, cases and makes them 0s. And then it takes any decimals (meaning some overlap, makes them 1s)
cat ${all_net_overlap_proportions} | perl -pe 's/,/,0/g' | perl -pe 's/0\.\d+/1/g' > ${all_net_overlap_proportions_binarized}

