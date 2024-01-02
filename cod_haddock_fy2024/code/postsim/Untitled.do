

if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2024" 
	global MRIP_root  "V:/READ-SSB-Lee-MRIP-BLAST/"
}

global mrip_vintage "2023_12_18"

/* setup directories */
global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"
global MRIP_dir  "${MRIP_root}/data_folder/main/MRIP_${mrip_vintage}"
global MRIP_raw  "${MRIP_root}/data_folder/raw"



 
/* Here are some parameters */
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787


/* l-W is updated to be consistent with PDB 
These are the length-weight relationships for Cod and Haddock
GOM Cod Formula:
Wlive (kg) = 0.000005132·L(fork cm)3.1625 (p < 0.0001, n=4890)

http://www.nefsc.noaa.gov/publications/crd/crd0903/
Haddock Weight length formula 
Annual: Wlive (kg) = 0.000009298·L(fork cm)3.0205 (p < 0.0001, n=4890)
GROUNDFISH ASSESSMENT UPDATES 2012 page 181

Fork length and total length are equivalentfor haddock and haddock*/


global cod_lwa 0.000005132
global cod_lwb 3.1625
global had_lwa 0.000009298
global had_lwe 3.0205
global lngcat_offset_cod 0.5
global lngcat_offset_haddock 0.5




/****************************/
/****************************/
/* Haddock and Cod rec ACLs in mt*/
/****************************/
/****************************/
global haddock_mort2022=666


global cod_recACL2022=192
global hadd_recACL2022=3634

global cod_recACL2023=192
global hadd_recACL2023=610


global mrip_vintage "2023_12_18"

global hadd_recACL2024=759
global cod_recACL2024=192

global cod_calibration_adj= 27
global hadd_calibration_adj= 26.3


global adj_cod_recACL2024=$cod_recACL2024-$cod_calibration_adj
global adj_hadd_recACL2024=$hadd_recACL2024-$hadd_calibration_adj





/* Read in all the Econ model runs that match `stub' */
local ccal "cod_length_class_2023_calibrate_"

local efilelist1: dir "${output_dir}" files "`ccal'*.dta"

local ecombinedfiles `" `efilelist1' `efilelist2'  `efilelist3' "'




/****************************/
/****************************/
/* Read in results and parse the source  */
/****************************/
/****************************/
clear
gen str40 source=""
foreach file of local ecombinedfiles{
capture append using ${output_dir}/`file'
replace source="`file'"  if source==""
}
keep scenario_num month replicate length kept released

/* average over the two april scenarios from the calibration */
gen str60 description=""
replace description="calibrated to 2023 total trips. For Hire Regs for Haddock. Cod closed in April" if scenario_num==3
replace description="calibrated to 2023 total trips. Private Regs for Haddock. Cod Closed in April " if scenario_num==4
replace description="calibrated to 2023 total trips. For Hire Regs for Haddock. Cod Opened in April" if scenario_num==5
replace description="calibrated to 2023 total trips. Private Regs for Haddock. Cod Opened in April" if scenario_num==6


replace description="calibrated to 2023 total trips. Blended regs for haddock. " if scenario_num==0

gen mode="Private" if inlist(scenario_num,4,6)
replace mode="ForHire" if inlist(scenario_num,3,5)


/* average scenarios 4+6 and 3+5 using replace , collapse*/

replace scenario_num= 1 if inlist(scenario_num,3,5)
replace scenario_num= 2 if inlist(scenario_num,4,6)

replace description="calibrated to 2023 total trips. For Hire Regs for Haddock. Cod partially open in April" if scenario_num==1
replace description="calibrated to 2023 total trips. Private Regs for Haddock. Cod partially open April " if scenario_num==2

collapse (mean) kept released, by(month scenario_num description replicate length)

gen mode="ForHire" if inlist(scenario_num,1)
replace mode="Private" if inlist(scenario_num,2)


foreach var of varlist kept released{
	rename `var' sim_`var'
}

/* sum up the kept and released from each fleet */

collapse (sum) sim*, by(month length)
gen scenario_num=0






tempfile length_data
save `length_data', replace


gen weight_lbs_per_fish=$cod_lwa*(length/$cm_to_inch)^${cod_lwb}
replace weight_lbs_per_fish=weight_lbs_per_fish*$kilo_to_lbs
gen sim_kept_weight=weight_lbs*sim_kept
gen sim_released_weight=weight_lbs*sim_released

bysort month scenario_num: egen total_sim_kept=total(sim_kept_weight)
bysort month scenario_num: egen total_sim_released=total(sim_released_weight)


bysort month scenario_num: egen total_sim_kept_num=total(sim_kept)
bysort month scenario_num: egen total_sim_released_num=total(sim_released)


gen avg_kept_weight=total_sim_kept/total_sim_kept_num
gen avg_released_weight=total_sim_released/total_sim_released_num







use "${MRIP_dir}\monthly\atlanticcod_ab1_counts_2023.dta" 
replace l_in_bin=l_in_bin-0.5
replace ab1_count=0 if ab1_count==.
drop if l_in_bin==.


gen weight_lbs_per_fish=$cod_lwa*(l_in_bin/$cm_to_inch)^${cod_lwb}
replace weight_lbs_per_fish=weight_lbs_per_fish*$kilo_to_lbs
gen kept_weight=weight_lbs*ab1_count

bysort month : egen total_kept_weight=total(kept_weight)
bysort month : egen total_kept_num=total(ab1_count)

gen avg_kept_weight=total_kept_weight/total_kept_num






use "${MRIP_dir}\monthly\cod_weights_2023.dta" 





