# this code is to calculate the Oxygen peak height at around 762 nm for in situ measured remote sensing reflectance(Rrs) spectra
#
# OAI: Oxygen absorption peak index
# equation: OAI=Rrs762-Rrs750-(Rrs780-Rrs750)*(762-750)/(780-750)
#
# the Oxygen peak height is calculated as the following steps: 
# step 1: check if there is a peak/valley at around 762 nm,
#		  if no peak/valley, use the median(Rrs745,Rrs755), median(Rrs755,Rrs770) and median(Rrs775,Rrs785) to calculate OAI;
# step 2: if there are peaks/valleys, then check how many peaks, 
#		  if there is only one peak/valley, then use this peak/valley (Rrs, wavelength) to calculate OAI;
# step 3: if there are more than one peaks/valleys, use the highest peak or lowest valley (Rrs, wavelength) for the OAI calculation;
#
# note: in the case of extremely turbid waters or algae bloom waters, the Rrs at ~780nm will be very high, which will underestimate the OAI, so for those 
#       cases, the Rrs at ~755nm ~762nm and ~769nm were used to calculate OAI. 
#       extremely turbid or algae bloom waters were identified using the Rrs slope between 775 and 799nm.
#
#
# Dalin Jiang, University of Stirling, UK
#
# dalin.jiang@stir.ac.uk
# 
# June 20, 2022
#
#
#
# inputs of the function:
# 1.Rrs_spec: Rrs, array
# 2.wave_min: min wavelength of Rrs, number
# 3.wave_max: max wavelength of Rrs, number
# 4.wave_int: interval of wavelength, number
#
# output of the function:
# Oxygen peak height: (1) >0 indicate it's peak (2) <0 indicate it's valley.
#


# ---------------------------------function---------------------------------------------------
# updated version, standerdized Rrs, dynamic 745-755, max peak 761-767, dynamic 775-785

OAI_Dalin<-function(Rrs_spec,wave_min,wave_max,wave_int){
	Rrs_spec <- as.numeric(Rrs_spec)
	# standardize the spectrum
	Rrs_spec <- (Rrs_spec - mean(Rrs_spec,na.rm=TRUE))/(sd(Rrs_spec,na.rm=TRUE))
	names(Rrs_spec) <- paste("Rrs",seq(wave_min,wave_max,wave_int),sep="")

	pos_750<-paste("Rrs",seq(745,755),sep="")
	pos_765<-paste("Rrs",seq(755,770),sep="")
	pos_780<-paste("Rrs",seq(775,785),sep="")
	
	
	#------ part I, find the max Oxygen peak-------
	x <- Rrs_spec[pos_765]
	x_valid <- x[which(!is.na(x))]
	
	if(length(x_valid) > 3 & all(!is.na(Rrs_spec[pos_780]))){
		dif_sign <- sign(diff(x_valid))
		if(all(dif_sign == 1) | all(dif_sign == -1) | all(dif_sign == 0)){              # case 1, no peaks, then take the median
			pks <- median(x_valid)
			pks_wave <- median(as.numeric(gsub("Rrs","",names(x_valid)))) 
			pks_sign <- 0
			turbid <- 0
		}else{                                # case 2, there are peaks
			sg <- diff(dif_sign)
			pos <- which(abs(sg) > 0)+1       # all peaks position
			if(length(pos) > 1){              # case 2.1, more than one peaks				 
				# find the max peak location
				nir_slope <- lm(Rrs_spec[paste("Rrs",seq(775,799),sep="")]~seq(775,799))$coe[2]
				if( nir_slope < 0.005){       # clear to turbid waters 
					dif_pks <- which.max(abs(x_valid[pos] - (median(Rrs_spec[pos_750],na.rm=TRUE)+median(Rrs_spec[pos_780],na.rm=TRUE))/2))
					pks <- x_valid[pos][dif_pks]				 
					pks_sign <- sg[which(sg != 0)][dif_pks]    # sign of the max peak
					pks_wave <- as.numeric(gsub("Rrs","",names(pks)))	
					turbid <- 0					
				}else{                        # extreme turbid waters or algae bloom waters
					dif_pks <- which.min(abs(as.numeric(gsub("Rrs","",names(x_valid[pos])))-762))  #find the peak closest 762nm	
					pks <- x_valid[pos][dif_pks]      			 
					pks_sign <- sg[which(sg != 0)][dif_pks]                # sign of the max peak
					pks_wave <- as.numeric(gsub("Rrs","",names(pks)))
					turbid <- 1	
				}			
			}else{                             # case 2.2, only one peak
				pks <- x_valid[pos]
				pks_sign <- sg[which(sg != 0)]
				pks_wave<-as.numeric(gsub("Rrs","",names(pks)))
				turbid <- 0				
			}
		}	
	}else if(length(x_valid) > 0){       # when where only 1-2 Rrs available
		pks <- median(x_valid)
		pks_wave <- median(as.numeric(gsub("Rrs","",names(x_valid)))) 
		pks_sign <- 0
		turbid <- 0
	}else{
		pks <- NA
		pks_wave <- NA
		pks_sign <- NA
		turbid <- NA
	}
	#tmp_out<-c(pks,pks_wave,pks_sign)
	#names(tmp_out)<-c("pks","pks_wave","pks_sign")
	
	#--------- part II, calculate Oxygen peak--------------------
	if (is.na(turbid)){
		OAI <- NA
	}else if(turbid == 1){           # extremely turbid water or algae bloom water
		if(pks_sign < 0){  # peak
			med_750 <- min(Rrs_spec[paste("Rrs",seq(750,757),sep="")],na.rm=TRUE)     
			med_780 <- min(Rrs_spec[paste("Rrs",seq(767,775),sep="")],na.rm=TRUE)
			OAI <- pks-med_750-(med_780-med_750)*(pks_wave-755.0)/(769.0-755.0)			
		}else{            # valley
			med_750 <- max(Rrs_spec[paste("Rrs",seq(750,757),sep="")],na.rm=TRUE)     
			med_780 <- max(Rrs_spec[paste("Rrs",seq(767,775),sep="")],na.rm=TRUE)
			OAI <- pks-med_750-(med_780-med_750)*(pks_wave-755.0)/(769.0-755.0)	
		}	
	}else{		                 # clear to turbid waters
		if(pks_sign == 0){             # no peak
			med_750 <- median(Rrs_spec[pos_750],na.rm=TRUE)     # median value between 745 and 755 nm
			med_780 <- median(Rrs_spec[pos_780],na.rm=TRUE) 
			OAI <- pks-med_750-(med_780-med_750)*(pks_wave-750.0)/(780.0-750.0)
		}else if(pks_sign < 0){        # peak
			med_750 <- min(Rrs_spec[pos_750],na.rm=TRUE)     # min value between 745 and 755 nm
			med_780 <- min(Rrs_spec[pos_780],na.rm=TRUE)
			OAI <- pks-med_750-(med_780-med_750)*(pks_wave-750.0)/(780.0-750.0) 
		}else if(pks_sign > 0){         # valley
			med_750 <- max(Rrs_spec[pos_750],na.rm=TRUE)     # max value between 745 and 755 nm
			med_780 <- max(Rrs_spec[pos_780],na.rm=TRUE)
			OAI <- pks-med_750-(med_780-med_750)*(pks_wave-750.0)/(780.0-750.0) 
		}
	}
	names(OAI)<-"Oxy_peak_height"
	#names(turbid)<-"turbid"
	#return(c(tmp_out,turbid,OAI))
	
	
	
	return(OAI)
}


## Added by Daniel Maciel 

flag_creation = function(oxygen_peak) {
  
  OAI = data.frame(oxygen_peak)
  
  OAI$flag = 0
  
  OAI[is.na(OAI$Oxy_peak_height), 'Oxy_peak_height'] = 0
  
  OAI[OAI$Oxy_peak_height > 0.1, 'flag'] = 1
  OAI[OAI$Oxy_peak_height < -0.1, 'flag'] = 1
  
  OAI[OAI$Oxy_peak_height == 0, 'Oxy_peak_height'] = NA
  
  return(OAI[,c('GLORIA_ID','Oxy_peak_height', 'flag')])
  
  
}

#------------------------------------------- processing chain---------------------------------------------

