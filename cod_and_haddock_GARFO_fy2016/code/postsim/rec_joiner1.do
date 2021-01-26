 cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO"
 
 
 /*
local rec_out3 "recreational_catches2014_a3.dta"
local rec_out4 "recreational_catches2014_a4.dta"
local rec_out6 "recreational_catches2014_a6.dta"
*/

local rec_out5 "recreational_catches2014_a5.dta"
local rec_out7 "recreational_catches2014_a7.dta"
local rec_out9 "recreational_catches2014_a9.dta"
local rec_out10 "recreational_catches2014_a10.dta"
local rec_outactual "recreational_catches2014_actual.dta"
local rec_out11 "recreational_catches2014_a11.dta"
local rec_out12 "recreational_catches2014_a12.dta"
local rec_out13 "recreational_catches2014_a13.dta"
local rec_out14 "recreational_catches2014_a14.dta"
local rec_out15 "recreational_catches2014_a15.dta"
local rec_out16 "recreational_catches2014_a16.dta"
local rec_out17 "recreational_catches2014_a17.dta"



dsconcat `rec_out3' `rec_out4'  `rec_out5'  `rec_out6'  `rec_out7' `rec_out9' `rec_out10' `rec_outactual' `rec_out11' `rec_out12' `rec_out13' `rec_out14' `rec_out15' `rec_out16' `rec_out17'
drop if wave<=2

gen cod_mort=cod_weight_kept+cod_discard_dead_weight

gen hadd_mort=haddock_weight_kept+haddock_discard_dead_weight

collapse (sum) cod_mort hadd_mort total, by(scenario replicate)

replace cod_mort=cod_mort/2204
replace hadd_mort=hadd_mort/2204

bysort scenario: centile cod_mort hadd_mort, centile (50 25 75)
/*

keep if scenario==0
keep if wave==3|wave==4
collapse (sum) cod_mort hadd_mort, by(scenario replicate)

replace cod_mort=cod_mort/2204
replace hadd_mort=hadd_mort/2204
centile cod_mort hadd_mort, centile(50 25 75)
*/
/*
collapse (sum) cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight (first) hadd_release_mort, by(scenario replicate year)
*/
