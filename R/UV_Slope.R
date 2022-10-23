slope_uv = function(gloria_rrs) {

  # Detect decreasing Rrs from 350-420 nm
  # Return a logical vector with 1 where slope is more negative than the
  # Threshold, and the actual slope value.

  # threshold = -0.005;

  rrs = gloria_rrs[,-1]
  
  WAVE = c(350:900)
  
  
  #Min and Median spectra functions without NA
  std.na = function(x) {return(sd(x, na.rm = T))}
  mean.na = function(x) { return(mean(x, na.rm = T))}
  
  
  STD.data = apply(rrs, MARGIN = 1, std.na)
  MEAN.data = apply(rrs, MARGIN = 1, mean.na)
  
  rrs.normalized = (rrs-MEAN.data)/STD.data
  
  threshold = -0.005
  
  
  LIMITS = c(350:420)
  select_Rrs = select(rrs.normalized, 
                      paste('Rrs_', 350:420, sep = ''))

  
  SLOPE = data.frame(GLORIA_ID = gloria_rrs$GLORIA_ID,
                     SLOPE = 0,
                     flag = 0)
  
  
  for(i in 1:nrow(SLOPE)) {
    
    
    DF = data.frame(WV = c(350:900), 
                    Rrs = t(rrs.normalized[i,])) %>% na.omit()
    
    
    DF.filter = filter(DF, WV >= min(LIMITS) & WV <= max(LIMITS)) %>% na.omit()
    
    
    if(nrow(DF.filter) != length(LIMITS)) {
      
      SLOPE$flag[i] = NaN
      
      print('Size Different from limits. Not accounting for noisy')
      
    }
    
    
    if(nrow(DF.filter) == length(LIMITS)) {
      
      MODEL = lm(Rrs~WV, data = DF.filter)

      SLOPE$SLOPE[i] = MODEL$coefficients[2]
      
      
      print('Slope Calculated')
      
    }
    
}
    
    SLOPE[SLOPE$SLOPE < threshold, 'flag'] = 1
    
    
    return(SLOPE[,c('GLORIA_ID', 'flag')])
    
    


  
}





noise_red_edge = function(gloria_rrs) {
  
  rrs = gloria_rrs[,-1]
  
  WAVE = c(350:900)
  
  
  #Min and Median spectra functions without NA
  std.na = function(x) {return(sd(x, na.rm = T))}
  mean.na = function(x) { return(mean(x, na.rm = T))}
  
  
  STD.data = apply(rrs, MARGIN = 1, std.na)
  MEAN.data = apply(rrs, MARGIN = 1, mean.na)
  
  rrs.normalized = (rrs-MEAN.data)/STD.data
  
  red_edge_limits = c(750:900)
  
  qc_flag_noisy_rededge = data.frame(GLORIA_ID = gloria_rrs$GLORIA_ID,
                                     RMSE = 0,
                                     flag = 0)
  
  

  #Threshold
  noise_thresh = 0.2
  
  for(i in 1:nrow(qc_flag_noisy_rededge)) {

    
    
    
    DF = data.frame(WV = c(350:900), 
                    Rrs = t(rrs.normalized[i,])) %>% na.omit()
    
    
    DF.filter = filter(DF, WV > 749 & WV < 901) %>% na.omit()
    
    
    if(nrow(DF.filter) != length(red_edge_limits)) {
      
      qc_flag_noisy_rededge$flag[i] = NaN
      
      print('Size Different from limits. Not accounting for noisy')
      
    }
    
    
    if(nrow(DF.filter) == length(red_edge_limits)) {
      
      POLY = polyFit(xy = DF.filter, deg = 4)
      PREDICTION = predict(POLY, newdata = DF.filter$WV)
      
      qc_flag_noisy_rededge$RMSE[i] = rmse(actual = DF.filter$Rrs, 
                  predicted = PREDICTION)
      
    
      print('RMSE Calculated')
      
    }
    
    
    
  }
  
  
  qc_flag_noisy_rededge[qc_flag_noisy_rededge$RMSE > noise_thresh, 'flag'] = 1
  
  
  return(qc_flag_noisy_rededge[,c('GLORIA_ID', 'flag')])
  
  
  }



noise_uv_edge = function(gloria_rrs) {
  
  
  
  rrs = gloria_rrs[,-1]
  
  WAVE = c(350:900)
  
  
  #Min and Median spectra functions without NA
  std.na = function(x) {return(sd(x, na.rm = T))}
  mean.na = function(x) { return(mean(x, na.rm = T))}
  
  
  STD.data = apply(rrs, MARGIN = 1, std.na)
  MEAN.data = apply(rrs, MARGIN = 1, mean.na)
  
  rrs.normalized = (rrs-MEAN.data)/STD.data
  
  uv_limits = c(350:400)
  
  qc_flag_noisy_UV = data.frame(GLORIA_ID = gloria_rrs$GLORIA_ID,
                                     RMSE = 0,
                                     flag = 0)
  
  #Threshold
  noise_thresh = 0.15
  
  for(i in 1:nrow(qc_flag_noisy_UV)) {
    
    
    
    DF = data.frame(WV = c(350:900), 
                    Rrs = t(rrs.normalized[i,])) %>% na.omit()
    
    
    DF.filter = filter(DF, WV >= min(uv_limits) & WV <= max(uv_limits)) %>% na.omit()
    


    LIMITS = rbind(min = filter(DF.filter, WV == 350),
                        max = filter(DF.filter, WV == 400)) %>% dim()
    
    if(LIMITS[1] != 2) {
      
      qc_flag_noisy_UV$flag[i] = NaN
      
      print('Size Different from limits. Not accounting for noisy')
      
    }
    
    
    if(LIMITS[1] == 2) {
      
      POLY = polyFit(xy = DF.filter, deg = 4)
      PREDICTION = predict(POLY, newdata = DF.filter$WV)
      
      qc_flag_noisy_UV$RMSE[i] = rmse(actual = DF.filter$Rrs, 
                                           predicted = PREDICTION)
      
      
      print('RMSE Calculated')
      
    }
    
    
    
  }
  
  
  qc_flag_noisy_UV[qc_flag_noisy_UV$RMSE > noise_thresh, 'flag'] = 1
  
  
  return(qc_flag_noisy_UV[,c('GLORIA_ID', 'flag')])
  
  
}







