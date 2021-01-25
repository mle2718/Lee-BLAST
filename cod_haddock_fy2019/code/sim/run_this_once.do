/*Data setup */
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all

set seed  4160


global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"


/*
global my_wd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_fy2019"
global my_data_dir "$my_wd/source_data"
*/
global codalkey "$source_data/svdbs/cod_al_key.dta"
global haddalkey "$source_data/svdbs/haddock_al_key9max.dta"


global calibration_end 2017

global this_year=year(date("$S_DATE","DMY"))
global this_year=2017

 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial is helper is set up to extract the 2014 FISHING YEAR

 */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$calibration_end


/* age-length data */

/* Age-length key years*/
 global lcalibration_start 2014
 global lcalibration_end 2016

do "$code_dir/presim/extract_length_age_data.do"

 global cod_naa "$source_data/cod agepro/cod_naa_2017update_both.dta"
 global hadd_naa "$source_data/haddock agepro/GOM_HADDOCK_ASAP2017NAA.dta"

global hadd_naa_start "$source_data/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.dta"
global cod_naa_start "$source_data/cod agepro/GOM_COD_2017_UPDATE_BOTH.dta"


global hadd_naa_sort "$working_data/haddock_beginning_sorted2017.dta"
global cod_naa_sort "$working_data/cod_beginning_sorted2017.dta"





/*Fetch the  MRIP data*/
/*global for the cod and haddock catch-at-length distributions (MRIP) */
global cod_historical_sizeclass "$my_data_dir/cod_size_class2017.dta"  
global haddock_historical_sizeclass "$my_data_dir/haddock_size_class2017.dta" 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class "$working_data/cod_catch_class2017.dta" 
global haddock_catch_class "$working_data/haddock_catch_class2017.dta"

/* 
Fetch the  MRIP data
catch class data
cp SOMETHING to $cod_catch_class
cp SOMETHING to $haddock_catch_class

/* size class data */
cp SOMETHING to $cod_historical_sizeclass
cp SOMETHING to $haddock_historical_sizeclass
 */


/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'replicate' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/

/* cod and haddock beginning age structures */
use "${cod_naa_start}", clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save "${cod_naa_sort}", replace



use "${hadd_naa_start}", clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save "${hadd_naa_sort}", replace


/* commercial monhtly catch
do $my_wd/commercial_helper.do */
do $code_dir/presim/commercial_monthly_helper.do
