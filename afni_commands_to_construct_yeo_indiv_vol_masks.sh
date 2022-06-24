#!/bin/sh

# pre: Yeo cortical parcellations (7 network) in volumetric space: https://surfer.nmr.mgh.harvard.edu/fswiki/CorticalParcellation_Yeo2011
# post: 7 individual network maps: VIS, MOT, DA, VA, LIM, FP, DM, labeled yeo_7_vol_[network abbreviation]
# uses: This script takes the parcellations in volume (Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii) and makes 7 individual maps. In the Yeo2011 volume mask, each network is given a number (1-7), with 1 corresponding to VIS, and 7 corresponding to DM. In order to make individual maps, I need to separate out each network in the map based on intensity. Will try to code in the following way: 1) make a vector where each item is the name of the network 2) make a loop that iterates 1-7, have a second counter that goes in the reverse direction 3) For each iteration, the count corresponds to both the intensity in the mask as well as its position in the name vector 4) To separate out the values with a specific intensity, need to do some weird math (b/c I can't just pull out intensity directly: If my count is 1, I need to pull out only values that are 1 from the map. This is equivalent to ispositive(a-[1-1])+isnegative(a-[1+1]). For 2, ispositive(a-[2-1]+isnegative(a-[2+1]) 
# dependencies: Afni 

#make list of yeo network abbreviations
yeo_7_net_list=("VIS"
		"MOT"
		"DA"
		"VA"
		"LIM"
		"FP"
		"DM")

#network path
network_path=/Users/eballer/BBL/msdepression/templates/Yeo_JNeurophysiol11_MNI152/

#current working directory
cwd=`pwd`
echo $cwd

#set volume mask [change this if I ever want to use a diff mask
volume_mask=Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii

#assign generic network_prefix_list variable; this is in case I decide I want to do this for 17 networks
network_prefix=yeo_7_net
network_list=$(echo ${network_prefix}_list)

echo "network list = ${network_list}"

#set counter, this will be used in loop
network_counter=1

echo "Volume mask = ${volume_mask}"

echo "Deleting old masks"
rm -f ${network_path}/${network_prefix}_*.nii

echo "Making individual network maps"
#for loop; goes through each network, pulls out the mask that corresponds to that network number, and stores it with the appropriate prefix

#have to write out yeo_7_net_list because bash can't handle too many extractions. Prob because I'm not referencing an object but a name when pointing network list to yeo_7_net_list
for network in "${yeo_7_net_list[@]}"; do
	echo "making ${network} mask, counter = ${network_counter}"
	afni_command=("3dcalc -a ${network_path}/${volume_mask} -expr 'ispositive(a-(${network_counter}-1))+isnegative(a-(${network_counter}+1))' -prefix ${network_path}/${network_prefix}_${network}.nii")
	echo $afni_command
	eval $afni_command
	((network_counter++))
done

#go back to current working directory
#cd $cwd
