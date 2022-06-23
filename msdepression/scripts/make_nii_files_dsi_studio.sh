#!/bin/bash

#### Welcome to the Region_making party #########
### Pre: Must have a file with full paths to the lesioned data 
### Post: Within each directory specified by the lesioned data, will have a directory that has all tractography (ROA, ROI, Full)
### Uses: For use in MS depression - take a subject's mimosa lesions and generate the fiber tracts (individual fascicles) that run through it
#dependencies: Using dsi studio downloaded 9/2021

export PATH=${PATH}:/Applications/dsi_studio.app/Contents/MacOS/
template='/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz'
default='/Users/eballer/BBL/msdepression/data/mimosa_file_paths'
fascicle_directory='/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/'

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

for lesion in ${lesion_paths}; do
    echo "Working on file" $lesion
    # make directory within parent directory for tracts
    #parent_dir=$(echo $lesion | perl -pe s'/(.*)\/.*/$1/g')
    mask_prefix=$(echo $lesion | perl -pe s'/(.*)\/(.*).nii.gz/$2/g')
    if [ ! -d $parent_dir/fiber_tracking_maps ] 
    then
        mkdir $parent_dir/fiber_tracking_maps
    fi

    fiber_bundle_type_list=(
        "association"
        "cerebellum"
        "cranial_nerve"
        "projection"
        "commissural")
    for fiber_bundle_type in "${fiber_bundle_type_list[@]}"; do
        echo "Fiber bundle type is " $fiber_bundle_type
        echo "making directory" $parent_dir/fiber_tracking_maps/$fiber_bundle_type
        #mkdir $parent_dir/fiber_tracking_maps/$fiber_bundle_type
        fascicles=$(ls ${fascicle_directory}/${fiber_bundle_type}/*.tt.gz)
        for fascicle in ${fascicles}; do
            echo "Fascicle is  " $fascicle
            fascicle_root_name=$(echo $fascicle | perl -pe s'/(.*)\/(.*).tt.gz/$2/g') 
          #  dsi_studio --action=ana --source=$template --tract=$fascicle --roa=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_lesioned_ROA.tt.gz
          #  dsi_studio --action=ana --source=$template --tract=$fascicle --roi=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_lesioned_ROI.tt.gz
           # dsi_studio --action=ana --source=$template --tract=$fascicle --output=${fascicle_directory}/${fiber_bundle_type}/${fascicle_root_name}_${mask_prefix}_full.tt.gz
            dsi_studio --action=ana --source=$template --tract=$fascicle --output=${fascicle_directory}/${fiber_bundle_type}/${fascicle_root_name}.nii.gz
        done
        # $path/dsi_studio --action=ana --source=/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz --tract=/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/association/SLF2_R.tt.gz --roa=/Users/eballer/BBL/msdepression/templates/perfect_ms_subject/run-001/mimosa_binary_mask_0.25.nii.gz --output=/Users/eballer/BBL/msdepression/templates/roi_files_for_testing/SLF2R_lesioned_ROA.nii.gz
        # $path/dsi_studio --action=ana --source=/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz --tract=/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/association/SLF2_R.tt.gz --roi=/Users/eballer/BBL/msdepression/templates/perfect_ms_subject/run-001/mimosa_binary_mask_0.25.nii.gz --output=/Users/eballer/BBL/msdepression/templates/roi_files_for_testing/SLF2R_lesioned_ROI.nii.gz
        # $path/dsi_studio --action=ana --source=/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz --tract=/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/association/SLF2_R.tt.gz --output=/Users/eballer/BBL/msdepression/templates/roi_files_for_testing/SLF2R_full_ROI.nii.gz
    done
done