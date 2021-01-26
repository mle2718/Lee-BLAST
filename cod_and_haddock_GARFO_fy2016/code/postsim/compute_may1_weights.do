cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock"

clear mata 
use cod_end_of_wave2014_tl1.dta, clear
keep if wave==20
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787

/* stock assessment computes SSB as of 1/4 of the way through the calendar year (End of March), using Jan1 weights

I'll compute  May 1 biomass and May 1 "SSB"
May 1 biomass: 

Age1-Age9*cod_midyear_weights'

 May 1 "SSB"

*/
mata:

/* selectivity  -- at least one of these columns must be 1*/
cod_age_selectivity=(0.299597086,0.637836907,0.989933463,1.179274755,1.421232878,1.608176673,1.732811727,1.910751601,2.173898432)

/* cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw), and fraction discarded (cfdis)*/
cod_jan1_weights=(0.12,0.52,1.26,2.19,3.12,3.82,4.77,6.55,12.50)
cod_midyear_weights=(0.31, 1.01, 2.07, 3.07, 3.79, 4.55, 5.79, 7.56, 12.49)
cod_catch_weights= cod_midyear_weights
cod_ssb_weights=cod_jan1_weights
cod_discard_weights=cod_catch_weights
cod_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0)
cod_maturity=(0.08,0.26,0.59,0.84,0.95,0.99,1,1,1)
cod_jan1_weights=$kilo_to_lbs*cod_jan1_weights
cod_catch_weights=$kilo_to_lbs*cod_catch_weights
cod_midyear_weights=$kilo_to_lbs*cod_midyear_weights
cod_ssb_weights=$kilo_to_lbs*cod_ssb_weights
cod_discard_weights=$kilo_to_lbs*cod_discard_weights
end


putmata cod_age_struct=(age1-age9), replace

mata: cod_may_biomass=cod_age_struct*cod_midyear_weights'
mata: cod_may_ssb=cod_age_struct*(cod_midyear_weights':*cod_maturity')

getmata cod_may_biomass cod_may_ssb

replace cod_may_biomass=cod_may_biomass/($mt_to_kilo*$kilo_to_lbs)

replace cod_may_ssb=cod_may_ssb/($mt_to_kilo*$kilo_to_lbs)
format commercial_catch-age9 cod* %16.0gc 

save cod_may_biological.dta, replace




use haddock_end_of_wave2014_tl1.dta, clear
keep if wave==20




mata:
haddock_age_selectivity=(0.009, 0.017, 0.091, 0.297, 0.672, 0.660, 1, 1, 1)
/* Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) all of these weights are taken from AgePro/Pop Dynamics
and are in kilograms*/


/* fraction discarded (hfdis) and maturity hmaturity are UNIT FREE*/
haddock_jan1_weights=(0.100, 0.298, 0.706, 0.984, 1.208, 1.498, 1.650, 1.786, 1.967)
haddock_midyear_weights= (0.178, 0.603, 0.905, 1.075, 1.357, 1.629, 1.699, 1.879, 1.967)
haddock_catch_weights= haddock_midyear_weights
haddock_ssb_weights=haddock_jan1_weights
haddock_discard_weights=haddock_catch_weights
haddock_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0)
haddock_maturity=(0.027, 0.236, 0.773, 0.974, 0.998, 1,1,1,1)


/* this step converts Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) to lbs */
haddock_jan1_weights=$kilo_to_lbs*haddock_jan1_weights
haddock_catch_weights=$kilo_to_lbs*haddock_catch_weights
haddock_midyear_weights=$kilo_to_lbs*haddock_midyear_weights
haddock_ssb_weights=$kilo_to_lbs*haddock_ssb_weights
haddock_discard_weights=$kilo_to_lbs*haddock_discard_weights
end


putmata haddock_age_struct=(age1-age9)

mata: haddock_may_biomass=haddock_age_struct*haddock_midyear_weights'
mata: haddock_may_ssb=haddock_age_struct*(haddock_midyear_weights':*haddock_maturity')

getmata haddock_may_biomass haddock_may_ssb

replace haddock_may_biomass=haddock_may_biomass/($mt_to_kilo*$kilo_to_lbs)

replace haddock_may_ssb=haddock_may_ssb/($mt_to_kilo*$kilo_to_lbs)
format commercial_catch-age9 haddock* %16.0gc 
save haddock_may_biological.dta, replace





use economic_data2014.dta, clear
drop if wave<=2
gen year=1
replace year=2 if wave>=9
replace year=3 if wave>=15
collapse (sum) total_trips WTP (first) cbag hbag cmin hmin, by(scenario replicate year)
format WTP %16.0gc


use recreational_catches2014.dta, clear

drop if wave<=2
gen year=1
replace year=2 if wave>=9
replace year=3 if wave>=15
collapse (sum) cod_num_kept cod_weight_kept cod_weight_discard haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight, by(scenario replicate year)


use cod_end_of_wave2014.dta, clear
keep if wave==20

putmata cod_age_struct=(age1-age9), replace

mata: cod_may_biomass=cod_age_struct*cod_midyear_weights'
mata: cod_may_ssb=cod_age_struct*(cod_midyear_weights':*cod_maturity')

getmata cod_may_biomass cod_may_ssb

replace cod_may_biomass=cod_may_biomass/($mt_to_kilo*$kilo_to_lbs)

replace cod_may_ssb=cod_may_ssb/($mt_to_kilo*$kilo_to_lbs)
format commercial_catch-age9 cod* %16.0gc 




use haddock_end_of_wave2014.dta, clear
keep if wave==20

putmata haddock_age_struct=(age1-age9), replace

mata: haddock_may_biomass=haddock_age_struct*haddock_midyear_weights'
mata: haddock_may_ssb=haddock_age_struct*(haddock_midyear_weights':*haddock_maturity')

getmata haddock_may_biomass haddock_may_ssb

replace haddock_may_biomass=haddock_may_biomass/($mt_to_kilo*$kilo_to_lbs)

replace haddock_may_ssb=haddock_may_ssb/($mt_to_kilo*$kilo_to_lbs)
format commercial_catch-age9 haddock* %16.0gc 





use economic_data2014_scenario1, clear

drop if wave<=2
gen year=1
replace year=2 if wave>=9
replace year=3 if wave>=15
collapse (sum) total_trips WTP (first) cbag hbag cmin hmin, by(scenario replicate year)
format WTP %16.0gc

use recreational_catches2014_scenario1, clear

drop if wave<=2
gen year=1
replace year=2 if wave>=9
replace year=3 if wave>=15
collapse (sum) cod_num_kept cod_weight_kept cod_weight_discard haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight, by(scenario replicate year)

use cod_end_of_wave2014_scenario1.dta, clear
keep if wave==20

putmata cod_age_struct=(age1-age9), replace

mata: cod_may_biomass=cod_age_struct*cod_midyear_weights'
mata: cod_may_ssb=cod_age_struct*(cod_midyear_weights':*cod_maturity')

getmata cod_may_biomass cod_may_ssb

replace cod_may_biomass=cod_may_biomass/($mt_to_kilo*$kilo_to_lbs)

replace cod_may_ssb=cod_may_ssb/($mt_to_kilo*$kilo_to_lbs)
format commercial_catch-age9 cod* %16.0gc 


use haddock_end_of_wave2014_scenario1.dta, clear
keep if wave==20

putmata haddock_age_struct=(age1-age9), replace

mata: haddock_may_biomass=haddock_age_struct*haddock_midyear_weights'
mata: haddock_may_ssb=haddock_age_struct*(haddock_midyear_weights':*haddock_maturity')

getmata haddock_may_biomass haddock_may_ssb

replace haddock_may_biomass=haddock_may_biomass/($mt_to_kilo*$kilo_to_lbs)

replace haddock_may_ssb=haddock_may_ssb/($mt_to_kilo*$kilo_to_lbs)
format commercial_catch-age9 haddock* %16.0gc 


