#### Welcome to make_red_to_yellow_RGB_color_scheme! ####

### I developed this script because I wanted to make my own RGB color palettes for DSI studio. 
### In short, I want to color each fascicle to be its proportion of loss, scaled on the RGB scale
### In order to do this, I needed to figure out how to map my proportions to RGB

### Pre: File of proportions
### Post: Output of RGB values in Red to Yellow Scale for the Proportions
### Uses: Step 0: Figure out how to scale from red to yellow 
###           - Red = 255 0 0, yellow 255 255 0
###           - Means that we need to vary the middle value (255) to get where we need to be
###       Step 1) For red to yellow, calculate the step (i.e. how much each value will be)
###             - because my proportions are out of 1, I wanted each step to be 1/100
###             - I am setting this value as "max", so it could vary if you have another max #
###       Step 2) Multiply the proportion by 100, so now each count is 1-100, in percents
###       Step 3) Multiply the percent by the step
###       Step 4) Save this value in that fascicle, 255 [new_value] 0
###
### Dependencies: Any R will do

###
homedir="/Users/eballer/BBL/msdepression/"

files = c("fascicle_mean_proportion_overlap_nfasc_77", "fascicle_proportion_overlap_with_depression_network_n77")

for (filename in files) {
  #suffix
  suffix = paste0("_", filename, "_RGB")
  
  #read in file with fascicle name and proportion
  fascicle_name_and_prop <- read.csv(paste0(homedir, "/results/", filename, ".csv"), sep = ",", header = F)
  names(fascicle_name_and_prop) <- c("fascicle", "proportion")
  
  #set scale dynamically
  #highest possible number in scale
  max<-100 * max(fascicle_name_and_prop$proportion)
  
  #step that each value in our scale will correspond to
  step<-255/max 
  
  # make a column for red
  red <- rep(x=255, times = 77)
  
  fascicle_name_and_prop$red <- red
  #multiply proportion column by 100, then by step, and round
  fascicle_name_and_prop$green<- round((fascicle_name_and_prop$proportion *100*step),0)
  
  #make column for blue
  blue <- rep(x=0, times = 77)
  fascicle_name_and_prop$blue=blue
  
  #sort based on proportion to check, it works! Lower values are associated with lower RGB
  #sorted <- fascicle_name_and_prop[order(fascicle_name_and_prop$proportion),]
  
  #make individual file colors for loading
  for (fascicle in 1:dim(fascicle_name_and_prop)[1]) {
    
    fascicle_name = fascicle_name_and_prop$fascicle[fascicle]
    fascicle_rgb = paste0(fascicle_name_and_prop$red[fascicle], " ", fascicle_name_and_prop$green[fascicle], " ", fascicle_name_and_prop$blue[fascicle])
    print(paste0(fascicle_name, " ", fascicle_rgb))
    write.table(file = paste0(homedir, "templates/dti/colors/", fascicle_name, suffix,".txt"), x = fascicle_rgb, quote = FALSE, col.names = FALSE, row.names = FALSE)
    
  }
  
  #output color file (77 lines, each represents a color), and color name vector. Not sure how to do 1:1 assignments rather than manually, but I'll see if I can figure that out!
  fascicle_name_and_prop_rgb_only <- fascicle_name_and_prop %>%
    mutate(rgb = paste0(fascicle_name_and_prop$red, " ", fascicle_name_and_prop$green, " ", fascicle_name_and_prop$blue)) %>%
    dplyr::select(fascicle, rgb)
  
  write.table(file = paste0(homedir, "/templates/dti/colors/", filename, "_fascicle_names.txt"), x = fascicle_name_and_prop_rgb_only$fascicle, row.names = FALSE, col.names = FALSE, quote = FALSE)
  
  write.table(file = paste0(homedir, "/templates/dti/colors/", filename, "_rgb.txt"), x = fascicle_name_and_prop_rgb_only$rgb, row.names = FALSE, col.names = FALSE, quote = FALSE)
}


