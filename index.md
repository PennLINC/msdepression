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
Erica B. Baller, M.D., M.S., Elizabeth M. Sweeney, Ph.D., Amit Bar-Or, M.D., Matthew C. Cieslak, Ph.D., Sydney C. Covitz, B.A., John A. Detre, M.D., Ameena Elahi, Abigail R. Manning, B.A., Clyde E. Markowitz, Melissa Martin, B.A., Christopher M. Perrone, M.D., Victoria Rautman, Timothy Robert-Fitzgerald, B.A., Matthew K. Schindler, M.D., Ph.D., Shan Siddiqi, M.D., Sunil Thomas, Michael D. Fox, M.D., Ph.D., Russell T. Shinohara, Ph.D.*, Theodore D. Satterthwaite, M.D., M.A.*
^shared last author

### Project Start Date:
My version - 1/2021

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

All clinical data was drawn from the electronic medical record via the Data Acquisition Center (DAC).
All images were obtained from the PACS system from the Department of Radiology

> /project/imco/homedir/couplingSurfaceMaps/alffCbf/{lh,rh}/stat/ : directories with individual coupling maps (these were generated on chead)

> /project/imco//baller/subjectLists/n831_alff_cbf_finalSample_imageOrder.csv : sample and demographics

> /project/imco//pnc/clinical/n1601_goassess_itemwise_bifactor_scores_20161219.csv : psychiatric data 

> /project/imco/pnc/cnb/n1601_cnb_factor_scores_tymoore_20151006.csv : cognitive data    



<br>
<br>
# CODE DOCUMENTATION

**The analytic workflow implemented in this project is described in detail in the following sections. Analysis steps are described in the order they were implemented; the script(s) used for each step are identified and links to the code on github are provided.** 
<br>


### Sample Construction

We first constructed our sample from n=890 individuals who were diagnosed with multiple sclerosis by a Multiple Sclerosis provider and received their clinical scans at the University of Pennsylvania. 

The following code takes the n=890 sample, and goes through a variety of exclusions to get the final n. Specifically, after excluding participants with poor image quality (n = 107), 783 were eligible for depression classification.  Inclusion in the depression group (MS+Depression) required 1) an ICD-10 depression diagnosis (F32-F34.\*), 2) a prescription for antidepressant medication, or screening positive via Patient Health Questionairre-2(PHQ2) or -9(PHQ9). The age- and sex-matched nondepressed comparators (MS-Depression) included persons with 1) no prior depression diagnosis, 2) no psychiatric medications, and 3) were asymptomatic on PHQ2/9. 

[n831_alff_cbf_makeSample.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/coupling/n831_alff_cbf_makeSample.R)
  
### Automated white matter lesion segmentation

After we obtained our sample, we used the Method for Intermodal Segmentation Analysis (MIMoSA) to extract white matter lesions for each subject. MIMoSA has been previously described: 

Valcarcel AM, Linn KA, Vandekar SN, Satterthwaite TD, Muschelli J, Calabresi PA, Pham DL, Martin ML, Shinohara RT. MIMoSA: An Automated Method for Intermodal Segmentation Analysis of Multiple Sclerosis Brain Lesions. J Neuroimaging. 2018 Jul;28(4):389-398. [doi: 10.1111/jon.12506](https://pubmed.ncbi.nlm.nih.gov/29516669/). Epub 2018 Mar 8. PMID: 29516669; PMCID: PMC6030441.

#### Volume to surface projection

[Volume to Surface Wiki](https://github.com/PennBBL/tutorials/wiki/3D-Volume-to-Surface-Projection-(FS))

First, brain volumes were projected to the cortical surface using tools from freesurfer. This was performed on chead, an old cluster that has now been retired. Input for this analysis consists of a csv containing bblid, datexscanid, path to the subject-space CBF or ALFF image to be projected, and path to the subject-specific seq2struct coreg .mat file (as well as the associated reference and target images). It further requires that FreeSurfer have been run on the subjects. Files were drawn from the chead 1601 data freeze. Datafreeze information is now also available on pmacs (see above links for pmacs). 

* input csv: `subjList.csv`
* reference volume (example): `99862_*x3972_referenceVolume.nii.gz`
* target volume (example): `99862_*x3972_targetVolume.nii.gz`

The following code converts the transform matrix (lta_convert), projects the volume to the surface (mri_vol2surf), and resamples the surface to fsaverage5 space (mri_surf2surf).

[vol2surf.sh](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/surface_projection_and_coupling/vol2surf.sh)

Then we transfor the matrix from BBL orientation to freesurfer orientation using the code below.

transformMatrix.R](https://github.com/PennLINC/IntermodalCoupling/blob/gh-pages2/CR_revision/surface_projection_and_coupling/transformMatrix.R)  

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
