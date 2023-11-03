/*Data setup */
clear
mata:mata clear
scalar drop _all
matrix drop _all

set seed  4160

/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2024" 
	global MRIP_dir  "V:/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2023_11_02" 
	global 	oracle_cxn  " $mysole_conn"
}





global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global mrip_source_data "${project_dir}/mrip"

global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"







global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

/************These come from the preamble to the blast model wrapper. Not all are needed***************************************/

global which_year=2023

global calibration_end 2023
global this_year=year(date("$S_DATE","DMY"))
global this_year=2023
global months=12
global periods_per_year=$months


/* don't change these two lines.  You are storing a bigger matrix of commercial catch and rec regulations. these couple of lines just exclude the 'old' years, prior to the calibration years */ 
global year_junk=2011 
global rec_junk=$calibration_end-1

global comm_month_starter=$periods_per_year*($which_year-$year_junk)+1
global rec_month_starter=$periods_per_year*($which_year-$rec_junk)+1



/* set calendar years for age-length keys */

/* Age-length key years*/
 global lcalibration_start 2018
 global lcalibration_end 2023	

/* set years for historical effort calibration params*/
 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial helper is set up to extract the 2016 FISHING YEAR */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$calibration_end


 /* updated to this point in Nov 2, 2023 */
 
 
 /* there are lots of things to keep track of here 
1.  Datasets that contain the historical mean numbers at age in each year. These are used to construct historical recreational selectivities
2.  We need projected NAA to initialize the simulation. These come  from the AGEPRO simulations runs.  
3.  We need to patch in mean projected NAA to the historical mean NAA because we need mean NAA in the bridge - and out- years 
4. We need to setup the NAA for the simulation in a way that is repeatable  
*/ 

/*1.  Datasets that contain the historical mean numbers at age in each year. These are copy/paste jobs from stock assessments. I am using a place holder for haddock, until I get the updated number from Charles Peretti
 */
global historical_cod_naaA "${source_data}/cod agepro/codagepro2021/gomcod_M02_2021MT.dta"
global historical_cod_naaB "${source_data}/cod agepro/codagepro2021/gomcod_MRAMP_2021MT.dta"
global historical_cod_naaBoth "${source_data}/cod agepro/codagepro2021/GOM_COD_2019_BOTH_NAA.dta"

global historical_hadd_naa "${source_data}/haddock agepro/2022_HAD_GM/gomhaddock_BASE_2022MT.dta"



/*2.  projected NAA to initialize the simulation. These come  from the AGEPRO simulations runs.   */
global cod_naaProj "${source_data}/cod agepro/NAA_GOM_COD_2021_UPDATE_BOTH.dta"
global hadd_naaProj "${source_data}/haddock agepro/NAA_GOM_HADDOCK_2022_FMSY.dta"

/* globals for the location of the xx1 AgePro output. Leave off the xx1, because I'm going to recycle this global to construct a .dta*/
global GOM_COD_A_xx1 "${source_data}/cod agepro/codagepro2021/GOM_COD_2021_UPDATE_M02RETROADJUST_PROJECT_75FMSY222/GOM_COD_2021_UPDATE_M02RETROADJUST_PROJECT_75FMSY222"
global GOM_COD_B_xx1 "${source_data}/cod agepro/codagepro2021/GOM_COD_2021_UPDATE_MRAMP_M04_PROJECT_75FMSY222/GOM_COD_2021_UPDATE_MRAMP_M04_PROJECT_75FMSY222"
global GOM_Haddock_xx1 "${source_data}/haddock agepro/2022_HAD_GM/GOM_HADDOCK_2022_GROWTH_PROJECTIONS"

/* number of years in Cod and haddock projections  -- lift this from agepro */
global codProjyears 12 
global haddProjyears 6


/* first year in Cod and haddock projections  -- lift this from agepro */
global cod_start_Proj 2020 
global hadd_start_Proj 2022


do "${code_dir}/presim/process_xx1.do"




/*3.  We need to patch in mean projected NAA to the historical mean NAA.  */


global cod_naaProj_and_Hist "${source_data}/cod agepro/historical_and_mean_projected_Cod_NAA.dta"
global hadd_naaProj_and_Hist "${source_data}/haddock agepro/historical_and_mean_projected_Haddock_NAA.dta"

 
/* Construct historical NAA from a combination of the stock assessments and the projections. */
do "${code_dir}/presim/construct_historical_cod_NAA.do"


/* Construct historical NAA from a combination of the stock assessments and the projections. */
do "${code_dir}/presim/construct_historical_haddock_NAA.do"


/* after this point has been updated */


/* Initial conditions for NAA. Also, a version that is sorted (randomly) in a consistent way */

global hadd_naa_sort "${source_data}/haddock agepro/haddock_beginning_sorted2023.dta"
global cod_naa_sort "${source_data}/cod agepro/cod_beginning_sorted2023.dta"

global cod_naa_start_bad  "${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH_low_recruits.dta"
global cod_naa_sort_bad  "${source_data}/cod agepro/cod_beginning_sorted2017_low_recruits.dta"

global hadd_naa_start_bad "${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS_low_recruits.dta"
global hadd_naa_sort_bad "${source_data}/haddock agepro/haddock_beginning_sorted2017_low_recruits.dta"












/******************MONTHLY  length and catch distributions **********************/
/*global for the cod and haddock catch-at-length distributions (MRIP) */
global cod_historical_sizeclass `""${mrip_source_data}/cod_size_class2023.dta""'  
global haddock_historical_sizeclass `""${mrip_source_data}/haddock_size_class2023.dta""' 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class `""${mrip_source_data}/cod_catch_class2023.dta""' 
global haddock_catch_class `""${mrip_source_data}/haddock_catch_class2023.dta""' 


/* If you want to use ANNUAL data, then uncomment this

/******************ANNUAL length and catch distributions ******************** */
global cod_historical_sizeclass `""${mrip_source_data}/cod_size_class_ANNUAL2021.dta""'  
global haddock_historical_sizeclass `""${mrip_source_data}/haddock_size_class_ANNUAL2021.dta""' 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class `""${mrip_source_data}/cod_catch_class_ANNUAL2021.dta""' 
global haddock_catch_class `""${mrip_source_data}/haddock_catch_class_ANNUAL2021.dta""' 

 */

/*Names for recruit savefiles  */

global haddock_recruitfile "${source_data}/haddock agepro/haddock_recruits_2023base.dta"
global cod_recruitfile "${source_data}/cod agepro/cod_recruits_2023both.dta"



/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'replicate' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/

/* cod and haddock beginning age structures */
use "$cod_naaProj", clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
/* sort the data and generate an id num*/
bysort year (u1 u2): gen id=_n

/* keep only the id from the first year, set all the other ids to missing, and fill in the first year id num */
qui summ year
replace id=. if year>r(min)
sort replicate year id
bysort replicate: replace id=id[1] if id==.
sort id

save "$cod_naa_sort", replace



use "$hadd_naaProj", clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
/* sort the data and generate an id num*/
bysort year (u1 u2): gen id=_n

/* keep only the id from the first year, set all the other ids to missing, and fill in the first year id num */
qui summ year
replace id=. if year>r(min)
sort replicate year id
bysort replicate: replace id=id[1] if id==.
sort id
save "$hadd_naa_sort", replace





/*

/* cod and haddock beginning age structures */
use $cod_naa_start_bad, clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
/* sort the data and generate an id num*/
bysort year (u1 u2): gen id=_n

/* keep only the id from the first year, set all the other ids to missing, and fill in the first year id num */
qui summ year
replace id=. if year>r(min)
sort replicate year id
bysort replicate: replace id=id[1] if id==.
sort id

save $cod_naa_sort_bad, replace



use $hadd_naa_start_bad, clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
/* sort the data and generate an id num*/
bysort year (u1 u2): gen id=_n

/* keep only the id from the first year, set all the other ids to missing, and fill in the first year id num */
qui summ year
replace id=. if year>r(min)
sort replicate year id
bysort replicate: replace id=id[1] if id==.
sort id

save $hadd_naa_sort_bad, replace


*/




/* set up recruits */
do "${code_dir}/presim/recruit_helper.do"


/* the following requires oracle access */

/*******************************************************/
 
/* Get the age-length data from the survey */

do "${code_dir}/presim/extract_length_age_data.do"




/* commercial monthly catch */
do "${code_dir}/presim/commercial_monthly_helper.do"



