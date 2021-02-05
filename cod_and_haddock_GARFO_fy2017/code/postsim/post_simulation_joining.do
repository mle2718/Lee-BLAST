/* specify names of save files */
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock"

/* Actual measures */
local econ_out "economic_data2014_scenario1.dta"
local rec_out "recreational_catches2014_scenario1.dta"
local sp1_out "cod_end_of_wave2014_scenario1.dta"
local sp2_out "haddock_end_of_wave2014_scenario1.dta"


local econ_out2 "economic_data2014_loop2.dta"
local rec_out2 "recreational_catches2014_loop2.dta"
local sp1_out2 "cod_end_of_wave2014_loop2.dta"
local sp2_out2 "haddock_end_of_wave2014_loop2.dta"

local econ_out3 "economic_data2014_loop1.dta"
local rec_out3 "recreational_catches2014_loop1.dta"
local sp1_out3 "cod_end_of_wave2014_loop1.dta"
local sp2_out3 "haddock_end_of_wave2014_loop1.dta"

/*Calibration results */
local econ_out0 "economic_data2013calibrate.dta"
local rec_out0 "recreational_catches2013calibrate.dta"
local sp1_out0 "cod_end_of_wave2013calibrate.dta"
local sp2_out0 "haddock_end_of_wave2013calibrate.dta"


local econ_out4 "economic_data2014_SQ_loop2.dta"
local rec_out4 "recreational_catches2014_SQ_loop2.dta"
local sp1_out4 "cod_end_of_wave2014_SQ_loop2.dta"
local sp2_out4 "haddock_end_of_wave2014_SQ_loop2.dta"

local econ_out5 "economic_data2014_scenario1_dm0_A.dta"
local rec_out5 "recreational_catches2014_scenario1_dm0_A.dta"
local sp1_out5 "cod_end_of_wave2014_scenario1_dm0_A.dta"
local sp2_out5 "haddock_end_of_wave2014_scenario1_dm0_A.dta"


local econ_out6 "economic_data2014_scenario1dm.dta"
local rec_out6 "recreational_catches2014_scenario1dm.dta"
local sp1_out6 "cod_end_of_wave2014_scenario1dm.dta"
local sp2_out6 "haddock_end_of_wave2014_scenario1dm.dta"


local econ_out7 "economic_data2014_scenario1dm50A.dta"
local rec_out7 "recreational_catches2014_scenario1dm50A.dta"
local sp1_out7 "cod_end_of_wave2014_scenario1dm50A.dta"
local sp2_out7 "haddock_end_of_wave2014_scenario1dm50A.dta"


local econ_out8 "economic_data2014_SQ_loop3.dta"
local rec_out8 "recreational_catches2014_SQ_loop3.dta"
local sp1_out8 "cod_end_of_wave2014_SQ_loop3.dta"
local sp2_out8 "haddock_end_of_wave2014_SQ_loop3.dta"

local econ_out9 "economic_data2014_SQ_loop4.dta"
local rec_out9 "recreational_catches2014_SQ_loop4.dta"
local sp1_out9 "cod_end_of_wave2014_SQ_loop4.dta"
local sp2_out9 "haddock_end_of_wave2014_SQ_loop4.dta"

local econ_out10 "economic_data2014_SQ_loop5.dta"
local rec_out10 "recreational_catches2014_SQ_loop5.dta"
local sp1_out10 "cod_end_of_wave2014_SQ_loop5.dta"
local sp2_out10 "haddock_end_of_wave2014_SQ_loop5.dta"





dsconcat `econ_out' `econ_out2' `econ_out3' `econ_out4' `econ_out5' `econ_out6' `econ_out7' `econ_out8' `econ_out9' `econ_out10'


/*aggregate trips, WTP by scenario and replicate over 3 years */
drop if wave<=2
collapse (sum) total_trips WTP (first) hadd_release_mort, by(scenario replicate)
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/economic_simulation_results.dta", replace


/*regulations */
dsconcat `rec_out' `rec_out2' `rec_out3' `rec_out4'  `rec_out5'  `rec_out6'  `rec_out7' `rec_out8' `rec_out9' `rec_out10'
drop if wave<=2
keep if replicate==1
keep scenario wave cbag hbag cmin hmin

keep if wave==3 | wave==5 | wave==8
replace wave=2 if wave==8
reshape wide cbag hbag cmin hmin, i(scenario) j(wave)
order cbag3 hbag3 cmin3 hmin3 
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/scenario_regs.dta", replace




dsconcat `rec_out' `rec_out2' `rec_out3' `rec_out4'  `rec_out5'  `rec_out6'  `rec_out7' `rec_out8' `rec_out9' `rec_out10'
drop if wave<=2

/*aggregate kept and released, dead discards by year*/
gen year=1 if wave<=8
replace year=2 if wave>=9 & wave<=14
replace year=3 if wave>=15 & wave<=20




collapse (sum) cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight (first) hadd_release_mort, by(scenario replicate year)

/* how much cod is killed yearly */
gen cod_removals_weight=cod_weight_kept+cod_discard_dead_weight
gen haddock_removals_weight=haddock_weight_kept + haddock_discard_dead_weight

foreach var of varlist cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight cod_removals_weight haddock_removals_weight{
replace `var'=`var'/1000000
}
label var cod_removals_weight "Recreational Cod Mortality, Millions of lbs"
graph box cod_removals_weight if year==1, over(scenario)

label var haddock_removals_weight "Recreational Haddock Mortality, Millions of lbs"
graph box haddock_removals_weight if year==1, over(scenario)




save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/rec_simulation_results.dta", replace


/* get the end of year stock structure */
dsconcat `sp1_out' `sp1_out2' `sp1_out3' `sp1_out4' `sp1_out5' `sp1_out6' `sp1_out7' `sp1_out8' `sp1_out9' `sp1_out10'

clear mata 
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787

keep if wave==20
keep scenario age* replicate hadd_release_mort
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/cod_end_age_structure.dta", replace
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

replace cod_may_biomass=cod_may_biomass/1000000
replace cod_may_ssb=cod_may_ssb/1000000

notes: biomass in millions of pounds

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/cod_end_age_structure.dta", replace







dsconcat `sp2_out' `sp2_out2' `sp2_out3' `sp2_out4' `sp2_out5' `sp2_out6' `sp2_out7' `sp2_out8' `sp2_out9' `sp2_out10'
keep if wave==20
keep scenario age* replicate hadd_release_mort
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/haddock_end_age_structure.dta", replace


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

replace haddock_may_biomass=haddock_may_biomass/1000000

replace haddock_may_ssb=haddock_may_ssb/1000000
notes: biomass in millions of pounds
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/haddock_end_age_structure.dta", replace




