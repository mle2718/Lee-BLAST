# BLAST
Bioeconomic something something something Toolbox

This repository will contain the code used in support of recreational fisheries management for GARFO using the BLAST model. This repository will eventually store all the BLAST model code from 2016 to present.

# Prelude
Look on my code, ye Mighty, and despair!

# Introduction
Every year, I archive the full set of code and data that was used to inform recreational fishing regulations.  Then I work on the next year's model. In addition to simple data updates, there are always small to medium changes that are made along the way to accomodate changes in circumstances. For example, the model initally simulated an entire year at a time. However, managers were interested in regulations that varied within the fishing year, so the model was adapted to run at wave- and then monthly- time steps. 




# Quick start
1. Clone the repository
2. Modify or create your profile.do file that stata automatically runs on startup so that stata always knows where the root BLAST folder is.   See [here](https://github.com/NEFSC/READ-SSB-Lee-BLAST/blob/main/project_logistics/sample_profile.do) for a sample profile.do.  

3. Run a "cod_and_haddock_YYYY*.do file."

# Organization
Each year is organized into it's own subfolder.  Inside each subfolder, there should be folders for source data, working data, and code. 

I should also include code to extract and reprocess the MRIP data, but I haven't done that yet.

# How to simulate different regulations
The size and bag limits are stored in vectors.  There is always this line of code:
```
do "${code_dir}/sim/historical_rec_regulations.do"
```
that reads in the recreational regulations. Right after that, you'll want to overwrite or replace some of those.  The simulation model starts on a calendar years (Jan 1).  

So, if you want to change the haddock bag limit to 3 fish in  May and June and your simulation is running on a monthly time step, you will want to modify the simulation code to read:
```
do "${code_dir}/sim/historical_rec_regulations.do"

mata: haddock_bag_vec[5]=3
mata: haddock_bag_vec[6]=3

```



# Supplementary data
Supplementary data can be found in /home2/mlee/BLAST. They are in zip files.


# making changes
The simulation files are always called cod_haddock_ZZZZ.  Most likely, you will want to 


# FY 2016
This has been uploaded and tested as functional.  Right now, I have only tested:
1. cod_haddock_2015_calibrator_T.do
1. cod_haddock_2016_status_quo.do 

The purpose of the calibrator is to find the *tot_trips* so the model outcomes match to the FY 2015 outcomes. I usually calibrate on trips-per-wave.  The code runs, but we should verify that it matches my previous calibration results.  The *cod_haddock_2016_status_quo.do* should simulate status quo regulations in 2016 (same regs as 2015).

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
This has been uploaded and tested as functional.  Right now, I have only tested:
1. cod_haddock_2017_calibrator.do
1. cod_haddock_2018_status_quo.do
1. cod_haddock_2018_status_quo_mod.do
1. cod_haddock_2018_status_quoB.do
1. cod_haddock_2018_status_quoB_mod.do

## notes about FY 2018

Looks like there are a few different versions of some files
1. simulation_v41a
1. simulation_v41_stop_fishing.do
1. simulation_v41_stop_haddock.do
1. simulation_v41a_always_on

And different recreational effort helpers -- these correspond to FYs or perhaps adjusting waves
new_bio_out_v4.do is a bit different than previous versions.


## Not tested
post-sim files.

# FY 2019
This has been uploaded and tested as functional.  Right now, I have only tested:
1. cod_haddock_2018_calibrator_T.do
1. cod_haddock_2019_alt_cmte.do
1. cod_haddock_2018_recalibrate.do
1. cod_haddock_2019_option1.do

The code runs, but we should verify that it matches my previous calibration results.
THe big change in 2019 was that I started sorting things into directories; this change has been rolled back to previous years.


# FY 2020
This has not been uploaded. There was a big change here is that instead of writing lots of different simulation files with few changes, I wrote the ability to pass in regulatory parameters that are stored in a csv or dta. I also wrote a little code to build those, since it's quite repetitive (one row per month).  Then you just pass in the location of those regulations.  


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
