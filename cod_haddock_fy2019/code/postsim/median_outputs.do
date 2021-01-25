clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all


local poststub "2018_status_quoA"

global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"




local econ_out "${output_dir}/economic_data`poststub'.dta"
local rec_out  "${output_dir}/recreational_catches`poststub'.dta"
local sp1_out  "${output_dir}/cod_end_of_wave`poststub'.dta"
local sp2_out  "${output_dir}/haddock_end_of_wave`poststub'.dta"
local cod_catch_class  "${output_dir}/cod_catch_class_dist`poststub'.dta"
local haddock_catch_class  "${output_dir}/haddock_catch_class`poststub'.dta"

local cod_land_class  "${output_dir}/cod_land_class_dist`poststub'.dta"
local haddock_land_class  "${output_dir}/haddock_land_class`poststub'.dta"


local hla  "${output_dir}/haddock_length_class`poststub'.dta"
local cla  "${output_dir}/cod_length_class`poststub'.dta"


cd "$project_dir"

/*what is the median WTP and trips (annualized) */
use `econ_out', replace
replace total=total/3
replace WTP=WTP/3
format WTP %16.0g
collapse (median) total WTP hadd_release_mort, by(scenario)
replace total=round(total)
replace WTP=round(WTP)
save `tw', replace

/* Copy and paste here */

/*what is the landings discards and mortality in year 1 */
use `rec_out', replace
keep if year==1
collapse (median) cod_weight_kept cod_weight_discard haddock_weight_kept haddock_weight_discard cod_removals_weight haddock_removals_weight, by(scenario)
save `ldm', replace


/*what is the COD SSB and biomass in wave 20*/
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/cod_end_age_structure.dta", replace
collapse (median) cod_may_biomass cod_may_ssb, by(scenario)
save `cod', replace


/*what is the HADDOCK SSB and biomass in wave 20*/

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/haddock_end_age_structure.dta", replace
collapse (median) haddock_may_biomass haddock_may_ssb, by(scenario)
save `haddock', replace


use `tw'
merge 1:1 scenario using `ldm', nogenerate
merge 1:1 scenario using `cod', nogenerate
merge  1:1 scenario using `haddock', nogenerate
