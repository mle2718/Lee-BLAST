/*more detailed outputs */
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
gen year=1 if wave<=8
replace year=2 if wave>=9 & wave<=14
replace year=3 if wave>=15 & wave<=20

collapse (sum) total_trips WTP (first) hadd_release_mort, by(scenario replicate year)
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/detail_economics.dta", replace

graph box WTP if year==1, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)
graph box total if year==1, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/rec_simulation_results.dta", replace
graph box cod_removals if year==1, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)
graph box cod_weight_kept  if year==1, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)

graph box haddock_removals_weight if year==1, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)
graph box haddock_weight_kept  if year==1, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)

 









use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/cod_end_age_structure.dta", replace


graph box cod_may_biomass, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/post_sim_utilities/haddock_end_age_structure.dta", replace


graph box haddock_may_biomass, over(scenario)
print @Graph, name(Graph) xsize(5.50) ysize(4.00) tmargin(3.50) lmargin(1.50)













