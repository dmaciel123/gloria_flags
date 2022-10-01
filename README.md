# GLORIA Flags

This project is inteended to provide the scripts that run the FLAGS for the GLORIA dataset (Moritz et al. 2022). These flags were created to exclude or warning determined spectra. 

For running the scripts, the Run.R files is used. The functions to calculate the flags for each of the QC_Control in GLORIA table is provided. 

Please note that in the main function (Run.R) the data used as input feature is the GLORIA Rrs from the Google Drive shared folder. If the file changes or the link to the file changes, the users should change the Google Drive ID. More information about Google Drive ID could be found here: https://docs.meiro.io/books/meiro-integrations/page/where-can-i-find-the-file-id-on-google-drive

The following methods are implemented in the project:

# Baseline Shift

Spectra which appear to be shifted above or below the zero line: Spectra shifted ‘up’ are those where the minimum of the spectrum is a large percentage (58.66%) of its median (upper whisker of boxplot - higher than distance between 3rd quartile + 1.5*IQR). Spectra shifted ‘down’ are those with at least 20 negative values and either a clear negative linear slope in the interval 765-900 nm (-8.664468 * 10-7) (< 1st quartile) and a moderate percentage of negative values in this spectral region (>50%), a large percentage of negative values at Rrs >765 nm (>70%), or at least 20 negative values at Rrs <450 nm.


# Oxygen Peak Calculation

Local maximum or minimum in Rrs near 762 nm due to absorption of light by oxygen: The spectra were standardized to zero mean and unit standard deviation. A straight line was fitted to the interval between the median values of (745-755 nm) and (775-785 nm). The maximum absolute residual of the standardized spectrum near 762 nm was recorded and is provided as a value in this column. 

Spectra where Oxygen_peak_height > 0.1. This threshold was determined using visual inspection of the distribution of peak heights with respect to spectral shapes.

# Noisy UV-edge

Spectra with high-frequency variability, potentially instrument noise, near the blue end: The spectra were standardized to zero mean and unit standard deviation. A 4th order polynomial was fitted over the interval 350-400 nm. Spectra with a root-mean square error >0.15 were flagged. This threshold was determined using visual inspection of the distribution of RMSEs with respect to spectral shapes.



# Noisy red-edge

Spectra with high-frequency variability, potentially instrument noise, near the red end: The spectra were standardized to zero mean and unit standard deviation. A 4th order polynomial was fitted over the interval 750-900 nm. Spectra with a root-mean square error (RMSE) >0.2 were flagged. This threshold was determined using visual inspection of the distribution of RMSEs with respect to spectral shapes.


# Negative UV Slope

Spectra with negative slopes in the ultraviolet (UV) and blue end: The spectra were standardized to zero mean and unit standard deviation. A straight line was fitted over the interval 350-420 nm and spectra with slopes <-0.005 were flagged. This threshold was determined using visual inspection of the distribution of slope values with respect to spectral shapes.

