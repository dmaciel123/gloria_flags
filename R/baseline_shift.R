
# This script is called by Run.R to calculate the Baseline_shift flag on GLORIA Rrs spectra
# Refer to README.md for a description of the method.




### Function for calculating negative slopes

negative_slopes = function(gloria_rrs) {

      #Create a new data.frame for including the results based on GLORIA_ID
      results = data.frame(id = gloria_rrs$GLORIA_ID)
      
      
      #Count negative number of spectra
      
      #All wavelengths
      
      results$negative_all =select(gloria_rrs, contains(paste('Rrs_', 400:900, sep = '')))  %>% apply(MARGIN = 1, FUN = function(x){ x = na.omit(x)
      length(x[x<0])})
      
      #NIR (700-900)
      results$negative_nir = select(gloria_rrs, contains(paste('Rrs_', 700:900, sep = ''))) %>% apply(MARGIN = 1, FUN = function(x){ x = na.omit(x)
      length(x[x<0])})
      
      #UV-BLUE (350-450)
      results$negative_blue = select(gloria_rrs, contains(paste('Rrs_', 350:450, sep = ''))) %>% apply(MARGIN = 1, FUN = function(x){ x = na.omit(x)
      length(x[x<0])})
      
      # Number of valid spectra in NIR Region
      results$length_nir = select(gloria_rrs, contains(paste('Rrs_', 700:900, sep = ''))) %>% apply(MARGIN = 1, FUN = function(x){ x = na.omit(x)
      length(na.omit(x))})
      
      #Ratio of negative/total number of valid spectra in NIR region
      results$Percentage_negative = results$negative_nir /results$length_nir *100
      
      
      
      #Slope calculation (765-900 nm)
      
      rrs.slope = select(gloria_rrs, contains(paste('Rrs_', 765:900, sep = '')))
      
      results$slope_nir = NaN
      
      
      print('Calculating Slope')
      
      for(i in 1:nrow(rrs.slope)) {
      
        pt1 = rrs.slope[i,] %>% t() %>% data.frame(WV= 765:900)
        names(pt1) = c('pt', 'WV')
        pt1 = filter(pt1, pt < 1)
      
        N = nrow(pt1)
      
        if(is.na(pt1$pt[2]) == FALSE ) {
      
          results$slope_nir[i] = summary(lm(pt~WV, data  = pt1))$coefficients[2]
        }
      
      }
      
      
      #### Removing data with negative values lower than 20
      
      filtro_neg_20 = filter(results, negative_all > 20)
      
      
      ##Negative slope NIR lower than lower hinge and with N > 50
      
      bx =boxplot(filtro_neg_20$slope_nir, plot = F)
      negative_nir_slope = filter(filtro_neg_20, negative_nir > 50 & slope_nir < bx$stats[2,])
      
      
      
      #Select values when 90% of Rrs in NIR region are negative
      perc_negative_70 = filter(filtro_neg_20, Percentage_negative > 70)
      perc_negative_50 = filter(filtro_neg_20, Percentage_negative > 50 & slope_nir < bx$stats[2,])
      
      
      
      ## Negative for UV-Blue higher than 20
      filtro_blue_neg = filter(filtro_neg_20, negative_blue > 20)
      
      
      ## Merge the results
      results.merge = rbind(negative_nir_slope, filtro_blue_neg,perc_negative_70,perc_negative_50)
      results.merge = results.merge[order(results.merge$id),]
      
      #Remove duplicates
      results2 = results.merge[duplicated(results.merge) == FALSE,]
      
      
      negatives = data.frame(GLORIA_ID = gloria_rrs$GLORIA_ID, negative_slopes = 0)
      negatives[negatives$GLORIA_ID %in% results2$id, 'negative_slopes'] = 1
      
      
      
      return(negatives)

}

## Function for calculating baseline shift

baseline_shift = function(gloria_rrs) {

      #Create a data.frame to store the results
      baseline = data.frame(ID = gloria_rrs$GLORIA_ID)
      
      #Wavelengths used to calculate the baseline
      rrs_counts = paste('Rrs', 400:900, sep = '_')
      
      
      #Min and median spectra functions without NA
      min.na = function(x) {return(min(x, na.rm = T))}
      median.na = function(x) { return(median(x, na.rm = T))}
      
      #Calculate min and median of the spectra
      baseline$min = apply(X = select(gloria_rrs, contains(rrs_counts)), MARGIN = 1, FUN = min.na)
      baseline$median = apply(X = select(gloria_rrs, contains(rrs_counts)), MARGIN = 1, FUN = median.na)
      
      
      #Baseline calculation (min Rrs / median Rrs)  * 100
    
      baseline$BASELINE_by_median = baseline$min/baseline$median*100
      
      #Baseline boxplot calculation
      bx_median = boxplot(baseline$BASELINE_by_median, ylab = '% Difference', plot = FALSE)
      
      #Filter by higher whisker of boxplot
      baseline.filter = filter(baseline, BASELINE_by_median > bx_median$stats[5,])
      
      #Filter by 60%
      baseline.filter_60 = filter(baseline, BASELINE_by_median > 60)
      
      #create the dataframe to store the results 
      baseline.results= data.frame(GLORIA_ID = gloria_rrs$GLORIA_ID, baseline = 0)
      
      #Results
      baseline.results[baseline.results$GLORIA_ID %in% baseline.filter_60$ID, 'baseline'] = 1
      
      return(baseline.results)

}

## Function to merge both results

merge_baseline_negative = function(GLORIA_ID, baseline, negative) {
  
  Baseline_shift = data.frame(GLORIA_ID = GLORIA_ID,
                              negatives = baseline,
                              positives = negative)
  
  Baseline_shift$Baseline_shift = Baseline_shift$negatives+Baseline_shift$positives
  Baseline_shift$Baseline_shift = gsub(x = Baseline_shift$Baseline_shift, pattern = 2, replacement = 1) %>% as.numeric()
  
  Baseline_shift = select(Baseline_shift, c('GLORIA_ID', 'Baseline_shift'))
  
  return(Baseline_shift)
}


