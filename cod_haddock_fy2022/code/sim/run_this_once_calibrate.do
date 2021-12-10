/*Data setup */

clear
mata:mata clear
scalar drop _all
matrix drop _all
pause off
set seed  4160


/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2022" 
	global MRIP_dir  "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2021_11_16" 
	quietly do "C:/Users/Min-Yang.Lee/Documents/common/odbc_setup_macros.do"
	global 	oracle_cxn  " $mysole_conn"
}



/* setup directories */
global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"



/* Is the model running waves or months? */
global months=12
global waves=6
global periods_per_year=$months

/*how many years, replicates */
global total_reps=2
global total_years_sim=1
local max_months=($months*$total_years_sim) + 4

/*Setup model calibration*/

/* To calibrate the model to 2017 
I need to have 150799 trips*/
/* To calibrate te model to 2018 
I need to have 125,000 trips*/


global tot_trips 200680
global scale_factor 10
global numtrips=$tot_trips/$scale_factor

global which_year=2019

set seed 911

/* read in biological data, economic data, and backround data on catch from the commercial fishery*/
do "${code_dir}/presim/cod_hadd_bio_params.do"
do "${code_dir}/presim/economic_parameters_mod.do"
do "${code_dir}/presim/commercial_quotas.do"

global codalkey "$working_data/cod_al_key.dta"
global haddalkey "$working_data/haddock_al_key9max.dta"

/* we save the A-L keys here , but I don't think they're ever used */ 



/* age-length data */

/* Age-length key years*/
 global lcalibration_start 2017
 global lcalibration_end 2019

do "$code_dir/presim/extract_length_age_data.do"





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











/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'id' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/

/* cod and haddock beginning age structures */
use "${cod_naa_start}", clear
preserve
tempfile jumble
keep replicate
dups, drop terse
gen u1=runiform()
gen u2=runiform()

sort u2 u1
gen id=_n
keep id replicate
save `jumble'
restore
merge m:1 replicate using `jumble'
assert _merge==3
cap drop _merge

order id replicate
sort id replicate
save "${cod_naa_sort}", replace



use "${hadd_naa_start}", clear

preserve
tempfile jumble2
keep replicate
dups, drop terse
gen u1=runiform()
gen u2=runiform()

sort u2 u1
gen id=_n
keep id replicate
save `jumble2'
restore
merge m:1 replicate using `jumble2'
assert _merge==3
cap drop _merge

order id replicate
sort id replicate


save "${hadd_naa_sort}", replace


do "${code_dir}/presim/recruit_helper.do"
/* commercial monhtly catch
do $my_wd/commercial_helper.do */
do $code_dir/presim/commercial_monthly_helper.do
