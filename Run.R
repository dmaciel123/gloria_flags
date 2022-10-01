#Loading some required packages

require(dplyr)
require(reshape2)
require(data.table)
require(tidyr)
require(googlesheets4)
require(data.table)
require(curl)

#Gloria data from Google Drive

#Loading users function

source('R/baseline_shift.R')
source('R/Oxygen_peak_calculation_updated_Dalin_20220908[69].R')
source('R/UV_Slope.R')

#This ID is the GLORIA_RRS Sheet on Google Drive. If the ID changes, the user
#Should change the string to a new one. 

id <- "17MonrXCgAkIOof-f9xuxxVYC-clu2m4W" # google file ID

gloria_rrs = fread(sprintf("https://docs.google.com/uc?id=%s&export=download", id))

negatives = negative_slopes(gloria_rrs =  gloria_rrs)
baseline = baseline_shift(gloria_rrs =  gloria_rrs)

baseline_shifts = merge_baseline_negative(GLORIA_ID = negatives$GLORIA_ID,
                                        baseline = baseline$baseline, 
                                        negative = negatives$negative_slopes)

oxygen_peak <- data.frame(GLORIA_ID=gloria_rrs$GLORIA_ID, 
                     Oxy_peak_height = apply(select(gloria_rrs, 
                                                    paste("Rrs_",seq(350,900),sep="")),1,
                                                    OAI_Dalin,wave_min=350,
                                                    wave_max=900,wave_int=1)) %>% flag_creation()


NOISE_RED_EDGE = noise_red_edge(gloria_rrs = gloria_rrs)
NOISE_UV_EDGE = noise_uv_edge(gloria_rrs = gloria_rrs)
SLOPE_UV = slope_uv(gloria_rrs = gloria_rrs)



#Comparison with results in GLORIA_qc_flags.csv

filter(baseline_shifts, Baseline_shift == 1) %>% nrow() #Ok
filter(oxygen_peak, flag == 1) %>% nrow() #That's correct? Need to Check with Dalin. It is slightly different from gloria doc.
filter(NOISE_RED_EDGE, flag == 1) %>% nrow() #OK
filter(NOISE_UV_EDGE, flag == 1) %>% nrow() #Ok
filter(SLOPE_UV, flag == 1) %>% nrow() #OK

#Save results

write.csv(file = 'Outputs/baseline_shift.csv', x = baseline_shifts)
write.csv(file = 'Outputs/oxygen_peak.csv', x = oxygen_peak)
write.csv(file = 'Outputs/noise_red_edge.csv', x = NOISE_RED_EDGE)
write.csv(file = 'Outputs/noise_uv_edge.csv', x = NOISE_UV_EDGE)
write.csv(file = 'Outputs/slope_UV.csv', x = SLOPE_UV)
