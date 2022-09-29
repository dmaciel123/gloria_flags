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

#This ID is the GLORIA_RRS Sheet on Google Drive. If the ID changes, the user
#Should change the string to a new one. 

id <- "17MonrXCgAkIOof-f9xuxxVYC-clu2m4W" # google file ID

negatives = negative_slopes(gloria_rrs =  fread(sprintf("https://docs.google.com/uc?id=%s&export=download", id)))
baseline = baseline_shift(gloria_rrs =  fread(sprintf("https://docs.google.com/uc?id=%s&export=download", id)))

baseline_shifts = merge_baseline_negative(GLORIA_ID = negatives$GLORIA_ID,
                                        baseline = baseline$baseline, 
                                        negative = negatives$negative_slopes)

oxygen_peak <- data.frame(GLORIA_ID=gloria_rrs$GLORIA_ID, 
                     Oxy_peak_height = apply(select(gloria_rrs, paste("Rrs_",seq(350,900),sep="")),1,
                OAI_Dalin,wave_min=350,wave_max=900,wave_int=1))


write.csv(file = 'Outputs/baseline_shift.csv', x = baseline_shifts)
write.csv(file = 'Outputs/oxygen_peak.csv', x = oxygen_peak)
