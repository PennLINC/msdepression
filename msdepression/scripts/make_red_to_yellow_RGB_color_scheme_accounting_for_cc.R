#### Welcome to make_red_to_yellow_RGB_color_scheme_accounting_for_corpus callosum! ####

### I developed this script because I wanted to make my own RGB color palettes for DSI studio. 
### In short, I want to color each fascicle to be its volume of loss, scaled on the RGB scale
### In order to do this, I needed to figure out how to map my volumes to RGB

### Pre: File of volumes
### Post: Output of RGB values in Red to Yellow Scale for the Volumes
### Uses: Step 0: Figure out how to scale from red to yellow 
###           - Red = 255 0 0, yellow 255 255 0
###           - Means that we need to vary the middle value (255) to get where we need to be
###       Step 1) For red to yellow, calculate the step (i.e. how much each value will be)
###             - because my volumes are out of 1, I wanted each step to be 1/100
###             - Usually I set this value as "max"
###             - But with CC being so big, things scale poorly. So I will set cc to full yellow, and set max to be the next biggest
###             - This is similar to normal thresholding, where everything above a value will be a specific color
###       Step 2) Multiply the volume by 100, so now each count is 1-100, in percents
###       Step 3) Multiply the percent by the step
###       Step 4) Save this value in that fascicle, 255 [new_value] 0
###       Step 5) if you want to change how the max value is scaled, change SLICE to be the # (slice(1) - max value, slice(2) - second value, etc)
###
### Dependencies: Any R will do

###

### gradients
## red-yellow - R always 255, green scaled (0 is red, 255 is yellow), blue always 0
## pink gradient (pg) - Red always 255, green scaled 0 to 255 , blue always 255

homedir="/Users/eballer/BBL/msdepression/"

files = c("volume_of_overlap_w_dep_net_n77")  # "fascicle_mean_volume_overlap_nfasc_77", "fascicle_volume_overlap_with_depression_network_n77", "fascicle_and_effect_size_for_volxdx_analysis_n77")

for (filename in files) {
  #suffix
  suffix = "_ry_scaling_cc" #red-yello gradient

  #  suffix = "_pg"
  #read in file with fascicle name and volume
  fascicle_names_and_vol <- read.csv(paste0(homedir, "/results/", filename, ".csv"), sep = ",", header = F)
  names(fascicle_names_and_vol) <- c("fascicle", "volume")
  
  #Make each value into a volume by dividing the volume by the total volume of all values
  total_volume_of_all_overlapping_fascicles <- sum(fascicle_names_and_vol$volume)
  
  fascicle_names_and_vol$proportion <- fascicle_name_and_vol$volume/total_volume_of_all_overlapping_fascicles
  
  #set scale dynamically
  #highest possible number in scale
  
  #sort by volume, take 2nd highest, extract proportion
  max_value<- fascicle_names_and_vol %>% 
    dplyr::select(proportion) %>%
    arrange(desc(proportion)) %>%
    slice(2) * 100 
  
  #step that each value in our scale will correspond to
  max_value <- as.numeric(max_value)
  step <- 255/max_value
  
  # make a column for red
  
  red <- rep(x=255, times = 77)
  
  fascicle_names_and_vol$red <- red

  #if proportion greater than max, set it to max value, otherwise, scale
  fascicle_names_and_vol$green<-  ifelse(fascicle_names_and_vol$proportion *100 > max_value, 255, round((fascicle_names_and_vol$proportion *100*step),0)) #ry
  
  #make column for blue
  blue <- rep(x=0, times = 77) #ry

 #blue <- rep(x=255, times = 77) #pg
  fascicle_names_and_vol$blue=blue
  

#output color file (77 lines, each represents a color), and color name vector. Not sure how to do 1:1 assignments rather than manually, but I'll see if I can figure that out!
  fascicle_names_and_vol_rgb_only <- fascicle_names_and_vol %>%
    mutate(rgb = paste0(fascicle_names_and_vol$red, " ", fascicle_names_and_vol$green, " ", fascicle_names_and_vol$blue)) %>%
    dplyr::select(fascicle, rgb)
  
  write.table(file = paste0(homedir, "/templates/dti/colors/", filename, suffix, "_fascicle_names.txt"), x = fascicle_names_and_vol_rgb_only$fascicle, row.names = FALSE, col.names = FALSE, quote = FALSE)
  
  write.table(file = paste0(homedir, "/templates/dti/colors/", filename, suffix, ".txt"), x = fascicle_names_and_vol_rgb_only$rgb, row.names = FALSE, col.names = FALSE, quote = FALSE)
}


