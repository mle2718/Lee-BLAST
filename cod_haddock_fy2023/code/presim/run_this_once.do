/*Data setup */
clear
mata:mata clear
scalar drop _all
matrix drop _all

set seed  4160

/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2023" 
	global MRIP_dir  "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2022_10_27" 
	quietly do "C:/Users/Min-Yang.Lee/Documents/common/odbc_setup_macros.do"
	global 	oracle_cxn  " $mysole_conn"
}





global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"







global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

/************These come from the preamble to the blast model wrapper. Not all are needed***************************************/

global which_year=2022

global calibration_end 2022
global this_year=year(date("$S_DATE","DMY"))
global this_year=2022
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
 global lcalibration_end 2021	

/* set years for historical effort calibration params*/
 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial helper is set up to extract the 2016 FISHING YEAR */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$calibration_end


 /* updated to this point in October 27, 2022 */
 

/*historical numbers at age. I can never remember where I get this from -- It might be a copy/paste job.  Probably is.  For haddock, I can pull in the 2019 ones, and then./
You have a pair of do files in the 2020 data that create these.  */
global cod_naa "${source_data}/cod agepro/NAA_GOM_COD_2021_UPDATE_BOTH.dta"
global hadd_naa "${source_data}/haddock agepro/NAA_GOM_HADDOCK_2019_FMSY.dta"




/* Initial conditions for NAA. Also, a version that is sorted (randomly) in a consistent way */

global hadd_naa_start "${source_data}/haddock agepro/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS.dta"
global cod_naa_start "${source_data}/cod agepro/GOM_COD_2021_UPDATE_BOTH.dta"

global hadd_naa_sort "${source_data}/haddock agepro/haddock_beginning_sorted2022.dta"
global cod_naa_sort "${source_data}/cod agepro/cod_beginning_sorted2022.dta"





global cod_naa_start_bad  "${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH_low_recruits.dta"
global cod_naa_sort_bad  "${source_data}/cod agepro/cod_beginning_sorted2017_low_recruits.dta"

global hadd_naa_start_bad "${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS_low_recruits.dta"
global hadd_naa_sort_bad "${source_data}/haddock agepro/haddock_beginning_sorted2017_low_recruits.dta"





 
/* Construct historical NAA from a combination of the stock assessments and the projections. */
do "${code_dir}/presim/construct_historical_cod_NAA.do"

/* Construct historical NAA from a combination of the stock assessments and the projections. */
do "${code_dir}/presim/construct_historical_haddock_NAA.do"




/******************MONTHLY  length and catch distributions **********************/
/*global for the cod and haddock catch-at-length distributions (MRIP) */
global cod_historical_sizeclass `""${source_data}/cod_size_class2021.dta""'  
global haddock_historical_sizeclass `""${source_data}/haddock_size_class2021.dta""' 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class `""${source_data}/cod_catch_class2021.dta""' 
global haddock_catch_class `""${source_data}/haddock_catch_class2021.dta""' 


/* If you want to use ANNUAL data, then uncomment this

/******************ANNUAL length and catch distributions ******************** */
global cod_historical_sizeclass `""${source_data}/cod_size_class_ANNUAL2021.dta""'  
global haddock_historical_sizeclass `""${source_data}/haddock_size_class_ANNUAL2021.dta""' 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class `""${source_data}/cod_catch_class_ANNUAL2021.dta""' 
global haddock_catch_class `""${source_data}/haddock_catch_class_ANNUAL2021.dta""' 

 */




/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'replicate' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/

/* cod and haddock beginning age structures */
use "$cod_naa_start", clear
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



use "$hadd_naa_start", clear
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




/* commercial monthly catch
do "${code_dir}/presim/commercial_helper.do" */
do "${code_dir}/presim/commercial_monthly_helper.do"



