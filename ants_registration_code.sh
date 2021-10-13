#!/bin/bash
### ANTS registration for MS Depression
##pre- requires ms patient T1, (eventually their mimosa), mni brain: mni_icbm152_t1_tal_nlin_asym_09a.nii, mask (currently using the one that was dilated in afni, d3
## 3dmask_tool -input t1_n4_brainmask.nii.gz -prefix t1_n4_brainmask_d3.nii.gz -dilate_input 3
##Post - ms participant T1w registered to icbm_template space (and later mimosa as well)
##Uses - We have all of these great ms depression scans but they are in native space. This will get them into mni space so they can be used with HCP templates, both structural and diffusion
##Dependencies: Using ANTs/2.3.5

# Set up paths
#export ANTSPATH=/home/eballer/
#export PATH=${ANTSPATH}:$PATH

#### Run registration

#default T1: t1_n4_brain.nii.gz 
t1=t1_n4_brain.nii.gz 
#default brain mask: t1_n4_brainmask_d3.nii.gz
brain_mask=t1_n4_brainmask_d3.nii.gz
#default target/template hcp brain" mni_icbm152_t1_tal_nlin_asym_09axbrainmask.nii
mni_target_t1=mni_icbm152_t1_tal_nlin_asym_09axbrainmask.nii

#output
outfile_prefix=ms_t1_to_mni_icbm152
antsRegistrationSyN.sh -d 3 -f ${mni_target_t1} -m ${t1} -o ${outfile_prefix} -x ${brain_mask}

#now actually do the transform
mimosa_path=mimosa_binary_mask_0.25.nii.gz #this is from mimosa output
mimosa_mni_hcp_path=mimosa_binary_mask_0.25_mni_hcp.nii.gz #output file prefix
mni_hcp_path=mni_icbm152_t1_tal_nlin_asym_09axbrainmask.nii #template
affine_mat=ms_t1_to_mni_icbm1520GenericAffine.mat #affine output from last step
ms2mni_warp=ms_t1_to_mni_icbm1521Warp.nii.gz #warp from last step. There are a few, Warp, Warped InverseWarp, InverseWarped. I picked the one that matched my pnc output the closes

antsApplyTransforms -e 3 -d 3 -i ${mimosa_path} -o ${mimosa_mni_hcp_path} -r ${mni_hcp_path} -t ${ms2mni_warp} -t ${affine_mat} -n GenericLabel
