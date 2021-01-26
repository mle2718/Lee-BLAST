# BLAST
Bioeconomic something something something Toolbox

This repository will contain the code used in support of recreational fisheries management for GARFO using the BLAST model.

# Introduction
Look on my code, ye Mighty, and despair!


# Quick start
1. Clone the repository
2. Go to the 

# Organization
Each year is organized into it's own subfolder.  Inside each subfolder, there should be folders for source data, working data, and code. 

I should also include code to extract and reprocess the MRIP data, but I haven't done that yet.

# Supplementary data
Supplementary data can be found in /home2/mlee/BLAST. They are in zip files.

# FY 2016
This has been uploaded and tested as functional.  Right now, I have only tested *cod_haddock_2015_calibrator_T.do* and *cod_haddock_2016_status_quo.do* file. The purpose of the calibrator is to find the *num_trips* so the model outcomes match to the FY 2015 outcomes. I usually calibrate on trips-per-wave.  The code runs, but we should verify that it matches my previous calibration results.  The *cod_haddock_2016_status_quo.do* should simulate status quo regulations in 2016 (same regs as 2015).

## notes about FY 2016
1.  FY 2016 runs on waves.
1.  Not sure about haddock discard mortality.
1.  Not sure of the final "sublegal" parameters.
1.  There isn't a 'scale factor' here. So this will run slower than other models.

## Not tested
post-sim files.

# FY 2017
Not there yet.  


## notes about FY 2017


## Not tested


# FY 2018
Not there yet.  

## notes about FY 2018


## Not tested
post-sim files.

# FY 2019
This has been uploaded and tested as functional.  Right now, I have only tested the *cod_haddock_2018_calibrator_T.do* file.  The *T* indicates I'm testing it. The purpose of this file is to find the *num_trips* so the model outcomes match to the FY 2015 outcomes. I usually calibrate on trips-per-wave.  The code runs, but we should verify that it matches my previous calibration results.



# NOAA Requirements
“This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.”


1. who worked on this project:  Min-Yang
1. when this project was created: A long time ago, in a galaxy far, far away. But it was uploaded Jan, 2021 
1. what the project does: Bioeconomic model for Recreational Fisheries management 
1. why the project is useful:  Bioeconomic model for Recreational Fisheries management
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue
1. who maintains and contributes to the project. Min-Yang

# License file
See here for the [license file](https://github.com/minyanglee/READ-SSB-Lee-BLAST/blob/main/License.txt)
