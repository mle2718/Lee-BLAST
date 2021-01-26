cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock"
pause on
tempfile tw ldm cod haddock

/*what is the median WTP and trips (annualized) */
use"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/economic_simulation_results.dta", replace
replace total=total/3
replace WTP=WTP/3
format WTP %16.0g
collapse (median) total WTP hadd_release_mort, by(scenario)
replace total=round(total)
replace WTP=round(WTP)
save `tw', replace

/* Copy and paste here */

/*what is the landings discards and mortality in year 1 */
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/rec_simulation_results.dta", replace
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
