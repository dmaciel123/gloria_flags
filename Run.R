# This is the driver script to calculate the quality control flags on the GLORIA Rrs spectra
# Refer to README.md for a description of the method.

#Loading Required Packages

require(dplyr)
require(reshape2)
require(data.table)
require(tidyr)
require(data.table)
require(curl)
require(polyreg)
require(Metrics)
require(openxlsx)

#Loading users function

source('R/baseline_shift.R')
source('R/Oxygen_peak_calculation.R')
source('R/UV_Slope.R')

#Read the Gloria Rrs file in Excel format
# SORRY, DANIEL: PLEASE ADD  CSV FILE READING (leave teh Excel file reading in comment, maybe). 
gloria_rrs = fread('GLORIA_global_remote_sensing_reflectance_radiometry.csv')


#Basline Calculation
negatives = negative_slopes(gloria_rrs =  gloria_rrs)
baseline = baseline_shift(gloria_rrs =  gloria_rrs)

baseline_shifts = merge_baseline_negative(GLORIA_ID = negatives$GLORIA_ID,
                                        baseline = baseline$baseline, 
                                        negative = negatives$negative_slopes)

#Oxygen Peak Calculation
oxygen_peak <- data.frame(GLORIA_ID=gloria_rrs$GLORIA_ID, 
                     Oxy_peak_height = apply(select(gloria_rrs, 
                                                    paste("Rrs_",seq(350,900),sep="")),1,
                                                    OAI_Dalin,wave_min=350,
                                                    wave_max=900,wave_int=1)) %>% flag_creation()

#Noise Red Edge Calculation
NOISE_RED_EDGE = noise_red_edge(gloria_rrs = gloria_rrs)

#Noise UV Edge Calculation
NOISE_UV_EDGE = noise_uv_edge(gloria_rrs = gloria_rrs)
 
#Slope UV calculation
SLOPE_UV = slope_uv(gloria_rrs = gloria_rrs)



#Counting number of flags for each method

filter(baseline_shifts, Baseline_shift == 1) %>% nrow() 
filter(oxygen_peak, flag == 1) %>% nrow() 
filter(NOISE_RED_EDGE, flag == 1) %>% nrow() 
filter(NOISE_UV_EDGE, flag == 1) %>% nrow() 
filter(SLOPE_UV, flag == 1) %>% nrow() 


#Save separated results

write.csv(file = 'Outputs/baseline_shift.csv', x = baseline_shifts, na = 'NaN')
write.csv(file = 'Outputs/oxygen_peak.csv', x = oxygen_peak, na = 'NaN')
write.csv(file = 'Outputs/noise_red_edge.csv', x = NOISE_RED_EDGE, na = 'NaN')
write.csv(file = 'Outputs/noise_uv_edge.csv', x = NOISE_UV_EDGE, na = 'NaN')
write.csv(file = 'Outputs/slope_UV.csv', x = SLOPE_UV, na = 'NaN')


## Merged Results 

final_results = data.frame(GLORIA_ID = baseline_shifts$GLORIA_ID, 
                           Baseline_shift = baseline_shifts$Baseline_shift, 
                           Oxygen_Peak = oxygen_peak$flag, 
                           Noisy_RedEdge = NOISE_RED_EDGE$flag,
                           Noisy_Uv = NOISE_UV_EDGE$flag, 
                           Slope_UV = SLOPE_UV$flag)

# Check Final Results 

filter(final_results, Baseline_shift == 1) %>% nrow() 
filter(final_results, Oxygen_Peak == 1) %>% nrow() 
filter(final_results, Noisy_RedEdge == 1) %>% nrow() 
filter(final_results, Noisy_Uv == 1) %>% nrow() 
filter(final_results, Slope_UV == 1) %>% nrow() 

# Save all results 

write.csv(file = 'Outputs/GLORIA_qc_flags.csv', x = final_results, na = 'NaN')







