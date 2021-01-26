/*Data setup */
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all

set seed  4160

global my_wd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018"
global my_data_dir "$my_wd/source_data"

global codalkey "$my_data_dir/cod_al_key.dta"
global haddalkey "$my_data_dir/haddock_al_key9max.dta"


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

do "$my_wd/extract_length_age_data.do"

 global cod_naa `""$my_data_dir/cod agepro/cod_naa_2017update_both.dta""'
 global hadd_naa `""$my_data_dir/haddock agepro/GOM_HADDOCK_ASAP2017NAA.dta""'

global hadd_naa_start `""$my_data_dir/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.dta""'
global cod_naa_start `""$my_data_dir/cod agepro/GOM_COD_2017_UPDATE_BOTH.dta""'


global hadd_naa_sort `""$my_data_dir/haddock agepro/haddock_beginning_sorted2017.dta""'
global cod_naa_sort `""$my_data_dir/cod agepro/cod_beginning_sorted2017.dta""'


/*Fetch the  MRIP data*/
/*global for the cod and haddock catch-at-length distributions (MRIP) */
global cod_historical_sizeclass "$my_data_dir/cod_size_class2017.dta"  
global haddock_historical_sizeclass "$my_data_dir/haddock_size_class2017.dta" 

/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class `""$my_data_dir/cod_catch_class2017.dta""' 
global haddock_catch_class `""$my_data_dir/haddock_catch_class2017.dta""' 

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


/* commercial monhtly catch
do $my_wd/commercial_helper.do */
do $my_wd/commercial_monthly_helper.do
