#### Welcome to make_binary_colored_depression_net_maps! ####

### I developed this script because I wanted to make my own RGB color palettes for DSI studio. 
### In short, I want to color each fascicle according to whether or not it is in the depression map. I want to make a separate map for depressed and nondepressed patients, but put them on the same scale

### Pre: File with 4 rows, 3 columns, diagnosis (1 no dep, 2 dep), network (1 dep, 2 nondep) and mean of the proportion of overlap (calculated by summing volumes in individual subjects, dividing by network size)

### Post: Two output of RGB files that can be fed to dsi studio
### Uses: Opens up file, determines max saturation of pink to be max in dep net, and max blue to be non-dep net
###       - Makes two color files, depression file where pink/blue triplets are weighted based on previous calculation
###       - same for nondepressed patients
###       - hope is that by doing the colors this way, you can see the contrast between groups, where there is a bigger spread of color in depressed, vs nondep, sorts by overlap to get a name of a vector in top quartile
### Dependencies: Any R will do, need the names of the fibers in the depression network, and a file with proportions


homedir="/Users/eballer/BBL/msdepression/"

dep_network_names_top_quartile_no_cranial_nerves_by_vol <- read.csv(file = paste0(homedir, "/results/dep_network_names_top_quartile_no_cranial_nerves_by_vol.txt"), header = F)

files = c("fascicle_proportion_overlap_with_depression_network_n77")

fascicle_name_and_prop <- read.csv(paste0(homedir, "/results/", filename, ".csv"), sep = ",", header = F)
names(fascicle_name_and_prop) <- c("fascicle", "prop")


df_means_volume_scaled_by_network_size<- read.csv(file = paste0(homedir, "/results/df_means_of_volumes_scaled_by_network_size_dx_net_for_color.csv"), header = T)

df_means_volume_scaled_by_network_size$mean <- df_means_volume_scaled_by_network_size$mean * 100 #easier to scale colors this way

#255 0 255 gives you the max pink color, vary the green to get lighter pink
color_depressed_net_red = 255
color_depressed_net_blue = 255

#0 255 255 gives you that maximum light blue, vary the red to get gradations
color_nondepressed_net_green = 255 
color_nondepressed_net_blue = 255


#max value within the depression network
max_dep_net <- max(df_means_volume_scaled_by_network_size$mean[df_means_volume_scaled_by_network_size$network == 1])

dep_net_step <- 255/max_dep_net

dep_dx_dep_net_green = round((255 - df_means_volume_scaled_by_network_size$mean[df_means_volume_scaled_by_network_size$diagnosis == 2 & df_means_volume_scaled_by_network_size$network == 1]*dep_net_step),0)
nondep_dx_dep_net_green = round((255 - df_means_volume_scaled_by_network_size$mean[df_means_volume_scaled_by_network_size$diagnosis == 1 & df_means_volume_scaled_by_network_size$network == 1]*dep_net_step),0)

  
dep_dx_dep_net_triplet = c(color_depressed_net_red, dep_dx_dep_net_green, color_depressed_net_blue)

nondep_dx_dep_net_triplet = c(color_depressed_net_red, nondep_dx_dep_net_green, color_depressed_net_blue)

#min value within the non-depressed network
min_nondep_net <- min(df_means_volume_scaled_by_network_size$mean[df_means_volume_scaled_by_network_size$network == 2])

#take an inverse of the proportion to get the step, because now we want the lowest to be the highest saturation
min_nondep_net_inverted = 100-min_nondep_net

nondep_net_step <- 255/min_nondep_net_inverted

dep_dx_nondep_net_red = round((255 - (100 - df_means_volume_scaled_by_network_size$mean[df_means_volume_scaled_by_network_size$diagnosis == 2 & df_means_volume_scaled_by_network_size$network == 2])*nondep_net_step),0)
nondep_dx_nondep_net_red = round((255 - (100 - df_means_volume_scaled_by_network_size$mean[df_means_volume_scaled_by_network_size$diagnosis == 1 & df_means_volume_scaled_by_network_size$network == 2])*nondep_net_step),0)


#dep net
dep_dx_dep_net_triplet = paste(color_depressed_net_red, dep_dx_dep_net_green, color_depressed_net_blue)

nondep_dx_dep_net_triplet = paste(color_depressed_net_red, nondep_dx_dep_net_green, color_depressed_net_blue)


#nondep network
dep_dx_nondep_net_triplet = paste(dep_dx_nondep_net_red, color_nondepressed_net_green, color_nondepressed_net_blue)

nondep_dx_nondep_net_triplet = paste(nondep_dx_nondep_net_red, color_nondepressed_net_green, color_nondepressed_net_blue)


# depressed file
fascicle_name_and_prop_rgb_only_depressed_dx <- fascicle_name_and_prop %>%
  mutate(rgb = ifelse((fascicle %in% dep_network_names_top_quartile_no_cranial_nerves_by_vol$V1), dep_dx_dep_net_triplet, dep_dx_nondep_net_triplet)) %>%
           dplyr::select(fascicle, rgb)

fascicle_name_and_prop_rgb_only_nondepressed_dx <- fascicle_name_and_prop %>%
  mutate(rgb = ifelse((fascicle %in% dep_network_names_top_quartile_no_cranial_nerves_by_vol$V1), nondep_dx_dep_net_triplet, nondep_dx_nondep_net_triplet)) %>%
  dplyr::select(fascicle, rgb)

  

write.table(file = paste0(homedir, "/templates/dti/colors/n77_depressed_colors_rgb.txt"), x = fascicle_name_and_prop_rgb_only_depressed_dx$rgb, row.names = FALSE, col.names = FALSE, quote = FALSE)

write.table(file = paste0(homedir, "/templates/dti/colors/n77_nondepressed_colors_rgb.txt"), x = fascicle_name_and_prop_rgb_only_nondepressed_dx$rgb, row.names = FALSE, col.names = FALSE, quote = FALSE)

