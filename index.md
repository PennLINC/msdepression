<br>
<br>



### Project Lead
Erica B. Baller

### Faculty Leads
Theodore D. Satterthwaite and Russell T. Shinohara

### Brief Project Description:
380 participants with multiple sclerosis were included (MS+Depression=232, MS-Depression=148). Lesions from research-grade clinical scans were segmented with MIMoSA and normalized to the HCP template. Streamline filtering was performed in DSI studio to generate measures of the degree of fascicle and network impact by lesions. A white matter depression network than connected previously described gray matter regions associated with depression (Siddiqi et al., 2021) was constructed. Main effect of network, depression diagnosis, and diagnosis by network interactions were assessed. 

### Analytic Replicator:
Elizabeth Sweeney, Ph.D.

### Collaborators:
Erica B. Baller, M.D., M.S., Elizabeth M. Sweeney, Ph.D., Amit Bar-Or, M.D., Matthew C. Cieslak, Ph.D., Sydney C. Covitz, B.A., John A. Detre, M.D., Ameena Elahi, Abigail R. Manning, B.A., Clyde E. Markowitz, Melissa Martin, B.A., Christopher M. Perrone, M.D., Victoria Rautman, Timothy Robert-Fitzgerald, B.A., Matthew K. Schindler, M.D., Ph.D., Shan Siddiqi, M.D., Sunil Thomas, Michael D. Fox, M.D., Ph.D., Russell T. Shinohara, Ph.D.^, Theodore D. Satterthwaite, M.D., M.A.^
^shared last author

### Project Start Date:
1/2021

### Current Project Status:
Completed

### Dataset:
Multiple Sclerosis Cohort

### Github repo:
https://github.com/PennLINC/MSDepression

### Path to data on filesystem:
PMACS:/project/msdepression/ 

### Slack Channel:
#msdepression and #msminigroup

### Zotero library:
K23 MS and Depression 

### Current work products:
ECTRIMS Poster 10/27/2022 - "Characterizing the relationship between white matter lesions and depression in patients with multiple sclerosis."

ACNP Poster 12/8/2022 - "Depression as a disease of white matter network disruption: characterizing the relationship between white matter lesions and depression in patients with multiple sclerosis."

### Path to Data on Filesystem **PMACS**

All clinical data was drawn from the electronic medical record via the Data Acquisition Center (DAC). All images were obtained from the PACS system from the Department of Radiology.

DAC Pull: 

     /project/msdepression/data/erica_dac_pull/investigatingdepressioninmspatients_dates_right_format.csv
 
Psychiatry medication information: 

     /project/msdepression/drugs_data/nami_psych_meds_antidepressants.csv

Patients with parsable depression diagnosis (after incorporating medications):

     /project/msdepression/drugs_data/parsable_msdepression.csv *fed into R analysis*

Subject imaging data: 

     /project/msdepression/data/subj_directories

Cubids : 

     /project/msdepression/cubids/v1_validation.csv
     /project/msdepression/CuBIDS_outputs/*

Fascicle proportions (for each subject (one row), % of injured fascicle (each column is a fascicle)): 

     /project/msdepression/results/fascicle_volumes_all_subjects_roi_n2336.csv

Overlap of each fascicle (volume and proportion) with depression network: 

     /project/msdepression/results/streamline_volume_within_dep_network_3_09.csv

Volume of all lesions (NOT fascicles) for each subject: 

     /project/msdepression/results/mimosa_binary_masks_hcp_space_20211026_n2336_volumes.csv

Volume of each healthy (full volume) fascicle: 

     /project/msdepression/templates/dti/HCP_YA1065_tractography/fiber_volume_values.csv

MIMoSA QA info:

     /project/msdepression/data/melissa_martin_files/csv/mimosa_dataframe


<br>
<br>

# CODE DOCUMENTATION

**The analytic workflow implemented in this project is described in detail in the following sections. Analysis steps are described in the order they were implemented; the script(s) used for each step are identified and links to the code on github are provided.** 
<br>

#### * Functions for project *
[msdepression_functions.R](https://github.com/ballere/msdepression/blob/main/msdepression_functions.R)

### Sample Construction

We first constructed our sample from n=890 individuals who were diagnosed with multiple sclerosis by a Multiple Sclerosis provider and received their clinical scans at the University of Pennsylvania. 

The following code takes the n=890 sample, and goes through a variety of exclusions to get the final n. Specifically, after excluding participants with poor image quality (n = 107), 783 were eligible for depression classification.  Inclusion in the depression group (MS+Depression) required 1) an ICD-10 depression diagnosis (F32-F34.\*), 2) a prescription for antidepressant medication, or screening positive via Patient Health Questionairre-2(PHQ2) or -9(PHQ9). The age- and sex-matched nondepressed comparators (MS-Depression) included persons with 1) no prior depression diagnosis, 2) no psychiatric medications, and 3) were asymptomatic on PHQ2/9. 
  
### Automated white matter lesion segmentation

After we obtained our sample, we used the Method for Intermodal Segmentation Analysis (MIMoSA) to extract white matter lesions for each subject. MIMoSA has been previously described: 

Valcarcel AM, Linn KA, Vandekar SN, Satterthwaite TD, Muschelli J, Calabresi PA, Pham DL, Martin ML, Shinohara RT. MIMoSA: An Automated Method for Intermodal Segmentation Analysis of Multiple Sclerosis Brain Lesions. J Neuroimaging. 2018 Jul;28(4):389-398. [doi: 10.1111/jon.12506](https://pubmed.ncbi.nlm.nih.gov/29516669/). Epub 2018 Mar 8. PMID: 29516669; PMCID: PMC6030441.

#### Streamline Filtering
Streamline filtering is an interative process performed in DSI studio. For each individual, the MIMoSA binary map was considered a region of interest. For each of the 77 fascicles, streamlines that ran through the lesion were "filtered" or kept, whereas the fascicles that avoided the MIMoSA mask were eliminated. Streamlines that passed through the MIMoSA were then saved binary .nii files, where 1 indicated that disease was present in that voxel, and 0 indicated either 1) that fascicle did not cross through that voxel or there was no disease in it. 
  
I was then able to calculate the "volume" of the disease in a fascicle (i.e. volume of the streamlines that were affected) by summing the # of 1s in the map. At the end, each individual had 77 single values that represented the volume of affected streamlines within each fascicle.
  
Full fascicle volumes were also calculated and saved as .niis. 

##### Step 1: Registering/normalizing MIMoSA binary maps to HCP template

[ants_registration_code.sh](https://github.com/ballere/msdepression/blob/main/ants_registration_code.sh)

##### Step 2: Take a subject's mimosa lesions and generate the fiber tracts (individual fascicles) that run through it

*Script that cycles through all subjects to do streamline filtering*

[dsi_studio_bash.sh](https://github.com/ballere/msdepression/blob/main/dsi_studio_bash.sh)

*Individual subject streamline filtering, called from dsi_studio_bash*

[indiv_mimosa_lesion_dsi_studio_script.sh](https://github.com/ballere/msdepression/blob/main/indiv_mimosa_lesion_dsi_studio_script.sh)

##### Step 3: Calculate the volume of each fascicle in a template (healthy) brain

*Make the volume of each of the healthy fascicles*

[make_streamline_volumes_for_template.sh](https://github.com/ballere/msdepression/blob/main/make_streamline_volumes_for_template.sh)

*Calculate the volume within each healthy fascicle*

[get_volume_of_mimosa_lesions.sh](https://github.com/ballere/msdepression/blob/main/get_volume_of_mimosa_lesions.sh)

##### Step 4: Calculate the volume of the fiber tracts that are impaired

*Make streamline volumes for all subjects*

[streamline_volumes_all_subjs.sh](https://github.com/ballere/msdepression/blob/main/streamline_volumes_all_subjs.sh)

*Make streamline volumes for a single subject, called from streamline_volumes_all_subjs.sh*

[make_streamline_volumes_single_subj_pmacs.sh](https://github.com/ballere/msdepression/blob/main/make_streamline_volumes_single_subj_pmacs.sh)

*Calculate the volume of the mimosa lesions*

[get_volume_of_mimosa_lesions.sh](https://github.com/ballere/msdepression/blob/main/get_volume_of_mimosa_lesions.sh)

##### Step 5: Generate summary fascicle measures

This specifically makes the fascicle injury ratio measure, calculated by taking the volume of injured fascicle and dividing by the overall volume of the healthy fascicle. 

[roi_ratio_regressions.R](https://github.com/ballere/msdepression/blob/main/roi_ratio_regressions.R)

#### White matter depression network construction

This network was made by [Shan Siddiqi et al., 2021 *Nature Human Behavior*](https://www.nature.com/articles/s41562-021-01161-1). 

I first thresholded the mask (3.09), binarized it and then used it as an ROI and calculated, per fascicle, the volume occupied by the fascicle that intersected with the depression mask using streamline filtering as above.

[calc_vol_fascicles_within_depression_mask_3_09.sh](https://github.com/ballere/msdepression/blob/main/calc_vol_fascicles_within_depression_mask_3_09.sh)

The top 25% (top quartile), i.e. the top 25% of fascicles with the highest volume of network overlap were considered in the depression network. Everything outside of that was considered "non_depression" network. In total, 77 fascicles were evaluated.

#### Disease burden summary measures
  Having computed disease measures at the individual fascicle, I wanted to assess network effects for all future analyses. To do this, I calculated three summary measures per individual. 
    
    1) Total disease : Sum of all 77 volume measures of disease, divided by the total volume of "healthy" fascicles (i.e. taking a sum of all of the full fascicle volumes). This yields a proportion of the overall burden of disease in the brain
    
    2) Depression network: Sum of all 19 volume measures of disease in the fascicles within the depression network, divided by the sum of total full fascicle volumes in the depression network.
    
    3) Nondepression network: Sum of all 58 volume measures of disease in the fascicles outside the depression network, divided by the sum of total full fascicle volumes in the nondepression network.
    
#### Main effect of Network, Diagnosis, and Diagnosis\*Network Analyses

A linear mixed effects model was used to assess main effect of Network, Diagnosis, and Diagnosis\*Network interactions with subject as a repeated measure using [lme4](https://cran.r-project.org/web/packages/lme4/index.html). 

#### Individual Fascicle Analyses 

Given the somewhat arbitrary definition of depression network (25%/75%), we next assessed whether the relationship between diagnosis and network was continuous. 
  
    1) For each fascicle, two values were computed
    
      a) Effect size (r) from the wilcoxon statistic comparing volume of disease in the fascicle between depressed vs nondepressed individuals
    
      b) The volume of the overlap of that fascicle with the depression network
  
    2) A linear model relating the overlap of volume of the fascicle w/the depression network to the effect size from the depressed v nondepressed wilcoxon analysis.

#### Coloring scripts for fascicle visualizations (to be fed into DSI studio)

*Sample script for making RGB scales in the red to yellow range*

[make_red_to_yellow_RGB_color_scheme.R](https://github.com/ballere/msdepression/blob/master/msdepression/scripts/make_red_to_yellow_RGB_color_scheme.R)

*Sample script for making binary color schemes, simple*

[make_binary_colored_depression_net_maps.R](https://github.com/ballere/msdepression/blob/master/msdepression/scripts/make_binary_colored_depression_net_maps.R)

*Sample script for making binary color schemes, coloring by whether fascicle in vs. outside dep network*

[make_binary_colored_depression_net_maps_by_dx.R](https://github.com/ballere/msdepression/blob/master/msdepression/scripts/make_binary_colored_depression_net_maps_by_dx.R)


#### 
[Volume to Surface Wiki](https://github.com/PennBBL/tutorials/wiki/3D-Volume-to-Surface-Projection-(FS))

First, brain volumes were projected to the cortical surface using tools from freesurfer. This was performed on chead, an old cluster that has now been retired. Input for this analysis consists of a csv containing bblid, datexscanid, path to the subject-space CBF or ALFF image to be projected, and path to the subject-specific seq2struct coreg .mat file (as well as the associated reference and target images). It further requires that FreeSurfer have been run on the subjects. Files were drawn from the chead 1601 data freeze. Datafreeze information is now also available on pmacs (see above links for pmacs). 

* input csv: `subjList.csv`
* reference volume (example): `99862_*x3972_referenceVolume.nii.gz`
* target volume (example): `99862_*x3972_targetVolume.nii.gz`

The following code converts the transform matrix (lta_convert), projects the volume to the surface (mri_vol2surf), and resamples the surface to fsaverage5 space (mri_surf2surf).

[vol2surf.sh](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/surface_projection_and_coupling/vol2surf.sh)

Then we transfor the matrix from BBL orientation to freesurfer orientation using the code below.

[transformMatrix.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/surface_projection_and_coupling/transformMatrix.R)  

#### Generating 2D coupling maps 

[Generating 2D Coupling Maps Wiki](https://github.com/PennBBL/tutorials/wiki/Surface-Coupling)

Input for this analysis consists of a csv that lists bblid/scanid.

It also requires that the subjects have been processed using freesurfer. Specifically, these files must be present:
```lh.sphere.reg  lh.sulc  lh.thickness  rh.sphere.reg  rh.sulc  rh.thickness``` The fsaverage5 directory must be present as well.

We use the following command line R program that estimates coupling for a given list of subjects. Flag options for the coupling job are listed at the top of this script. It calls **kth_neighbors_v3.R**. 

[coupling_v2.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/surface_projection_and_coupling/coupling_v2.R)
  
The following code is run by coupling_v2.R and estimates the first k sets of nearest neighbors for each vertex for a particular template.

[kth_neighbors_v3.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/surface_projection_and_coupling/kth_neighbors_v3.R)

* **This code requires FS version 5.3** (it will not run on the updated version 6.0). 
  
### Coupling Regressions

We next wanted to examine whether CBF-ALFF coupling changed across development, differed by sex, and related to executive functioning. 

The following code goes vertex by vertex and does coupling regressions, specifically relating CBF-ALFF coupling to age, sex, and cognition. It does vertex-level FDR correction, thresholds at SNR>=50 and stores both corrected and uncorrected Ts, ps, and effect sizes into vectors and saves them to the output. These files can then be used for visualization in matlab. 

[coupling_accuracy_fx_T_with_effect_sizes.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/coupling/coupling_accuracy_fx_T_with_effect_sizes.R)

In addition to doing vertex-level analysis, we also explored how mean coupling (i.e. 1 value per participant) related to age using the code below. We used the FDR-corrected output from the coupling_accuracy_fx_T_with_effect_sizes.R age analysis as inputs. We also calculated the derivative of the spline to assess where the couplingxage effects were most rapidly changing.

[scatter_plots.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/coupling/scatter_plots.R)

Mean coupling by age

![Mean Coupling by Age](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/Images/Mean_coupling_by_age_rplot_fdr05_visreg_gam_snr50.jpg?raw=true)


### Visualizations on inflated brain

We did our brain surface visualizations in matlab. The following is a sample matlab visualization script. It is called with three parameters, and produces an inflated brain. Variations of this script were used to change colors in the Figures. 

[PBP_vertWiseEffect_Erica_Ts_pos_and_neg_results_outpath.m](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/PBP_graphics/PBP_vertWiseEffect_Erica_Ts_pos_and_neg_results_outpath.m) 

  - For example, a call would be: PBP_vertWiseEffect_Erica_Ts_pos_and_neg_results_outpath('/project/imco/baller/results/CR_revision/couplingxsnr_maps/eaxmask_50_lh.csv','/project/imco/baller/results/CR_revision/couplingxsnr_maps/eaxmask_50_rh.csv','eaxmask_thresh50_values')


#### Sample output: Coupling Executive Accuracy
![Coupling Exec Accuracy](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/Images/eaxmask_thresh50_values.png?raw=true)

### Spin Testing and Visualization

In reviewing our results, we became interested in whether our findings mapped onto Yeo 7 networks. For interpretability and for graphs, we decided to do a variation on the spin test. Overall, the goal was to take the vertices (10242 for each hemisphere), and spin. We would next ask how many vertices would randomly and by chance fall within certain Yeo networks as compared to what we actually saw. A challenge of this spin is that when we spin the vertices, we include medial wall which is guaranteed to be 0. In order to account for this, we calculated the proportion of vertices within each network minus the ones in the medial wall.

The below code makes trinarized yeo masks, 1, 0, -1. In order to run permutation analyses on the Yeo networks, I need to trinarize my fdr corrected maps. If a vertex is corrected, it will get a 1. If not, 0. If it is within the medial wall, it will get a -1. This will allow me to later assess how many vertices within each network met correction (1s), did not meet statistical significance (0s), and should be excluded from the proportion calculation (-1). For the mean CBF-ALFF map, as no statistic was calculated, we retain the T values and spin them directly. 

[make_trinarized_maps_for_spin_test_snr.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/spin_snr/make_trinarized_maps_for_spin_test_snr.R)

The matlab code below makes the spins. We provided 5 parameters
    1. left hemisphere vector with trinarized data
    2. Right hemisphere vector with trinarized data
    3. Number of permutations per hemisphere (we use 1000/hemisphere)
    4. output directory
    5. output filename

[SpinPermuFS.m](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/spin_snr/SpinPermuFS.m)

The following script calculates the proportion of FDR-corrected vertices within each Yeo 7 network for both the real data as well as the 2000 permuted spins. The proportion was calculated by taking the (# of vertices with a 1) divided(/) by the (number of total vertices within network minus number of negative vertices). For the mean coupling results, we evaluated the spun T values with the actual T values per network.

[spin_proportion_calculations_and_plots_snr.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/spin_snr/spin_proportion_calculations_and_plots_snr.R)

Lastly, we use the following code to visualize the spin results. It uses ggplot2 to make violin plots for display, calling functions from imco_functions.R. The violin represents the distribution of proportions from the permutation analysis. The black bar represents the real data. 

[violin_plots.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/spin_snr/violin_plots.R)

#### Sample output: Mean Coupling Spin
![Mean Coupling Violin plot](https://raw.githubusercontent.com/PennLINC/IntermodalCoupling/gh-pages2/Images/spin_mean_coupling_snr_50.png)

### Helper Functions

All helper functions can be found in [imco_functions.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/imco_functions.R)


### Final Figures

#### **Figure 1 - Schematic**
![Schematic](https://raw.githubusercontent.com/PennLINC/IntermodalCoupling/gh-pages2/CR_revision//Full_figures/Fig_1_Schematic.png)

#### **Figure 2 - Mean coupling enriched in frontoparietal network**
![Mean Coupling](https://raw.githubusercontent.com//PennLINC/IntermodalCoupling/gh-pages2/CR_revision/Full_figures/Figure_2-Mean_Coupling.png)

#### **Figure 3 - Age effects enriched in dorsal attention network**
![Age](https://raw.githubusercontent.com/PennLINC/IntermodalCoupling/gh-pages2/CR_revision/Full_figures/Figure_3-Age.png)

#### **Figure 4 - Sex effects enriched in frontoparietal network**
![Sex](https://raw.githubusercontent.com//PennLINC/IntermodalCoupling/gh-pages2/CR_revision/Full_figures/Figure_4-Sex.png)

#### **Figure 5 - Executive accuracy effects enriched in motor network and regions in default mode network**
![Executive Accuracy](https://raw.githubusercontent.com/PennLINC/IntermodalCoupling/gh-pages2/CR_revision/Full_figures/Figure_5-Executive_Function.png)
