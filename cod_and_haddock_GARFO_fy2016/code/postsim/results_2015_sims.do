cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO"
local rec_out "recreational_catches2014_sq5.dta"
use `rec_out', clear
keep if wave>=9

collapse (sum) total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight, by(scenario replicate)

gen cod_mortality=cod_weight_kept+cod_discard_dead_weight

gen haddock_mortality=haddock_weight_kept+haddock_discard_dead_weight

foreach var of varlist cod_mort haddock_mort cod_weight_kept cod_discard_dead_weight haddock_weight_kept haddock_discard_dead_weight{
	replace `var'=`var'/2204
}

/* count if there are any below the minimum */

bysort scenario: count if cod_mort<=121

bysort scenario: count if haddock_mort<=372

collapse (median) total_trips cod_mort haddock_mort cod_weight_kept cod_discard_dead_w haddock_weight_kept haddock_discard_dead_weight, by(scenario)
