#!/bin/bash
### ANTS registration for MS Depression
##pre- requires ms mimosa file that contains the directory, mni brain: mni_icbm152_t1_tal_nlin_asym_09a.nii
##Post - ms participant T1w and mimosa registered to icbm_template space
##Uses - We have all of these great ms depression scans but they are in native space. This will get them into mni space so they can be used with HCP templates, both structural and diffusion
#Steps
## 1 - take all file paths to data with good qc, extract file paths, and make shadow directories with linksin out local data directory
## 2 - make the dilated mask
     #####mask (currently using the one that was dilated in afni, d3
     ## 3dmask_tool -input t1_n4_brainmask.nii.gz -prefix t1_n4_brainmask_d3.nii.gz -dilate_input 3
## 3 - for each subject, run the registration, and then apply the transpforms
##Dependencies: Using ANTs/2.3.5
# Set up paths
module load ANTs/2.3.5
export ANTSPATH=/appl/ANTs-2.3.5/bin
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8
#######if it doesn't work, fix this ###
#export PATH=${ANTSPATH}:$PATH




#set default templatesfiles/paths

base_dir='/project/msdepression/scripts'

#Primary directorie - CHANGE THESE IF ANYTHING EVER CHANGES, IT WILL UPDATE FILE NAMES BELOW

qc_file_path='/project/msdepression/data/melissa_martin_files/csv/minimelissa_list_for_testing_n3'
mni_t1_root='mni_icbm152_t1_tal_nlin_asym_09a'
mask_dilation=3
brain_mask_root="t1_n4_brainmask"
t1="t1_n4_reg_brain_ws.nii.gz"
mimosa_root="mimosa_binary_mask_0.25"
out_data_path='/project/msdepression/data/subj_directories/'
mni_t1_direc='/project/msdepression/templates/mni_icbm152_nlin_asym_09a/'

#set outfile prefix
outfile_prefix=ms_t1_to_mni_icbm152

#for transform
mimosa_path=${mimosa_root}.nii.gz #this is from mimosa output
mimosa_mni_hcp_path=${mimosa_root}_mni_hcp.nii.gz #output file prefix
affine_mat=${outfile_prefix}0GenericAffine.mat #affine output from last step
ms2mni_warp=${outfile_prefix}1Warp.nii.gz #warp from last step. There are a few, Warp, Warped InverseWarp, InverseWarped. I picked the one that matched out pnc output the closes


#making some secondary files
mni_t1_path="${mni_t1_direc}/${mni_t1_root}.nii"
mni_t1_target="${mni_t1_root}xbrainmask.nii"
brain_mask="${brain_mask_root}.nii.gz"
brain_mask_dilated="${brain_mask_root}_d${mask_dilation}.nii.gz"

directories=$(cat $qc_file_path)

#multiply with mni t1 to get appropriate coverage. Have to do it locally b/c afni
cd ${mni_t1_direc}
	3dcalc -a ${mni_t1_root}.nii -b ${mni_t1_root}_mask.nii -expr 'a*b' -prefix ${mni_t1_target}
cd $base_dir

#extract name of directory and create shadow directory in out own data directory, with appropriate file names
for directory in $directories; do
        sub_sess_run=$(echo ${directory} | perl -pe 's/.*(sub.*)/$1/') #grab sub/sess/run
        echo $sub_sess_run
        echo "making dir" ${out_data_path}/${sub_sess_run}

	#remove directory if it already exists
	if [ -d ${out_data_path}/${sub_sess_run} ] 
	then
		rm ${out_data_path}/${sub_sess_run}/*
	else
		#make new directory
        	mkdir -p ${out_data_path}/${sub_sess_run}
	fi
	
	#link mimosa path
        ln -s ${directory}/${mimosa_path} ${out_data_path}/${sub_sess_run}/.
	
	#link patient's t1_n4_reg_brain_ws.nii.gz
        ln -s ${directory}/${t1} ${out_data_path}/${sub_sess_run}/.
        
	#link brain mask t1_n4_brainmask
	ln -s ${directory}/${brain_mask} ${out_data_path}/${sub_sess_run}/.
        
	#copy mni target (mni template xmask dilation) 
	cp ${mni_t1_direc}/${mni_t1_target} ${out_data_path}/${sub_sess_run}/.

        #go into directory for afni stuff, then pop back out
        cd ${out_data_path}/${sub_sess_run}

        	#make the dilated mask
        	3dmask_tool -input ${brain_mask} -prefix ${brain_mask_dilated} -dilate_input ${mask_dilation}
	cd ${base_dir}

        	#multiply with mni t1 to get appropriate coverage - this is the problem!!! 
        	#3dcalc -a ${mni_t1_root}.nii -b ${mni_t1_root}_mask.nii -expr 'a*b' -prefix ${mni_t1_target}

         
	#### Run registration
        antsRegistrationSyN.sh -d 3 -f ${out_data_path}/${sub_sess_run}/${mni_t1_target} -m ${out_data_path}/${sub_sess_run}/${t1} -o ${out_data_path}/${sub_sess_run}/${outfile_prefix} -x ${out_data_path}/${sub_sess_run}/${brain_mask_dilated}

        #now actually do the transform${brain
       
       	 antsApplyTransforms -e 3 -d 3 -i ${out_data_path}/${sub_sess_run}/${mimosa_path} -o ${out_data_path}/${sub_sess_run}/${mimosa_mni_hcp_path} -r ${out_data_path}/${sub_sess_run}/${mni_t1_target} -t ${out_data_path}/${sub_sess_run}/${ms2mni_warp} -t ${out_data_path}/${sub_sess_run}/${affine_mat} -n GenericLabel

done
