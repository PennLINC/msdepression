#!/bin/bash

#### Welcome to the Region_making party #########
### Pre: Must have a file with full paths to the lesioned data 
### Post: Within each directory specified by the lesioned data, will have a directory that has all tractography (ROA, ROI, Full)
### Uses: For use in MS depression - take a subject's mimosa lesions and generate the fiber tracts (individual fascicles) that run through it
#dependencies: Using dsi studio downloaded 9/2021

set path='/Applications/dsi_studio.app/Contents/MacOS/'
set template='/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz'
set default='/Users/eballer/BBL/msdepression/data/mimosa_file_paths'

if ($#argv == 0) then
    echo "Please enter a 1) subject list with full paths to lesions"
    echo "OR type 1 if you would like to use default file, currently: "$default
    exit(1)
else if ($argv[1] == 1) then
    set lesion_file=$default
    else
        set lesion_file=$1 
    endif

    echo "File being read is "$lesion_file
endif 

echo "... Starting to make lesions ..."
foreach lesion (`cat ${lesion_file}`)
    echo "Working on file" $lesion
    # make directory within parent directory for tracts
    parent_dir = `echo $lesion:h`
    if (`ls $parent_dir | wc -l` == 0) then
        mkdir $parent_dir/fiber_tracking_maps
    endif
   
    foreach fiber_bundle_type (association cerebellum cranial\ nerve projection commissural)
        mkdir $parent_dir/fiber_tracking_maps/$fiber_bundle_type
        foreach fascicle (`ls Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/${fiber_bundle_type}`)
           $path/dsi_studio --action=ana --source=$template --tract=$fascicle --roa=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascile_}_lesioned_ROA.nii.gz
           $path/dsi_studio --action=ana --source=$template --tract=$fascicle --roi=$lesion --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascile_}_lesioned_ROI.nii.gz
           $path/dsi_studio --action=ana --source=$template --tract=$fascicle --output=$parent_dir/fiber_tracking_maps/${fiber_bundle_type}/${fascile_}_full.nii.gz
        end
           # $path/dsi_studio --action=ana --source=/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz --tract=/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/association/SLF2_R.tt.gz --roa=/Users/eballer/BBL/msdepression/templates/perfect_ms_subject/run-001/mimosa_binary_mask_0.25.nii.gz --output=/Users/eballer/BBL/msdepression/templates/roi_files_for_testing/SLF2R_lesioned_ROA.nii.gz
           # $path/dsi_studio --action=ana --source=/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz --tract=/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/association/SLF2_R.tt.gz --roi=/Users/eballer/BBL/msdepression/templates/perfect_ms_subject/run-001/mimosa_binary_mask_0.25.nii.gz --output=/Users/eballer/BBL/msdepression/templates/roi_files_for_testing/SLF2R_lesioned_ROI.nii.gz
           # $path/dsi_studio --action=ana --source=/Users/eballer/BBL/msdepression/templates/dti/HCP1065.1mm.fib.gz --tract=/Users/eballer/BBL/msdepression/templates/dti/HCP_YA1065_tractography/association/SLF2_R.tt.gz --output=/Users/eballer/BBL/msdepression/templates/roi_files_for_testing/SLF2R_full_ROI.nii.gz
    end
end
