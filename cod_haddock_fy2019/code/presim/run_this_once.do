/*Data setup */
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all

set seed  4160
/*
global my_wd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_fy2019"
global my_data_dir "$my_wd/sourc "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019/e_data"
*/

global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"




global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

/************These come from the preamble to the blast model wrapper. Not all are needed***************************************/

global which_year=2018

global calibration_end 2018
global this_year=year(date("$S_DATE","DMY"))
global this_year=2018
global months=12
global periods_per_year=$months


/* don't change these two lines.  You are storing a bigger matrix of commercial catch and rec regulations. these couple of lines just exclude the 'old' years, prior to the calibration years */ 
global year_junk=2011 
global rec_junk=$calibration_end-1

global comm_month_starter=$periods_per_year*($which_year-$year_junk)+1
global rec_month_starter=$periods_per_year*($which_year-$rec_junk)+1



/* set years for age-length keys */

/* Age-length key years*/
 global lcalibration_start 2014
 global lcalibration_end 2016

/* set years for historical effort calibration params*/
 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial helper is set up to extract the 2016 FISHING YEAR */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$calibration_end


/*******************************************************/
/* age-length data */

/* Age-length key years*/
 global lcalibration_start 2014
 global lcalibration_end 2016

do "${code_dir}/presim/extract_length_age_data.do"

 global cod_naa `""${source_data}/cod agepro/cod_naa_2017update_both.dta""'
 global hadd_naa `""${source_data}/haddock agepro/GOM_HADDOCK_ASAP2017NAA.dta""'

global hadd_naa_start `""${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.dta""'
global cod_naa_start `""${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH.dta""'


global hadd_naa_sort `""${source_data}/haddock agepro/haddock_beginning_sorted2017.dta""'
global cod_naa_sort `""${source_data}/cod agepro/cod_beginning_sorted2017.dta""'





global cod_naa_start_bad  `""${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH_low_recruits.dta""'
global cod_naa_sort_bad  `""${source_data}/cod agepro/cod_beginning_sorted2017_low_recruits.dta""'

global hadd_naa_start_bad `""${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS_low_recruits.dta""'
global hadd_naa_sort_bad `""${source_data}/haddock agepro/haddock_beginning_sorted2017_low_recruits.dta""'










/*Fetch the  MRIP data*/
/*global for the cod and haddock catch-at-length distributions (MRIP) */
global cod_historical_sizeclass `""${source_data}/cod_size_class2017.dta""'  
global haddock_historical_sizeclass `""${source_data}/haddock_size_class2017.dta""' 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class `""${source_data}/cod_catch_class2017.dta""' 
global haddock_catch_class `""${source_data}/haddock_catch_class2017.dta""' 

global MRIP_dir "/home/mlee/Documents/Workspace/MRIP_working/outputs/2017"
/* Don't fetch the MRIP data, push it over using "subset_mrip_2018.do"*/


/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'replicate' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/

/* cod and haddock beginning age structures */
use $cod_naa_start, clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save $cod_naa_sort, replace



use $hadd_naa_start, clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save $hadd_naa_sort, replace







/* cod and haddock beginning age structures */
use $cod_naa_start_bad, clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save $cod_naa_sort_bad, replace



use $hadd_naa_start_bad, clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save $hadd_naa_sort_bad, replace














/* commercial monhtly catch
do "${code_dir}/presim/commercial_helper.do" */
do "${code_dir}/presim/commercial_monthly_helper.do"
