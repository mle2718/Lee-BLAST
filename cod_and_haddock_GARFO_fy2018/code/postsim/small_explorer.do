cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/summary_results"

local rec_out "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_status_quoA.dta"
local rec_out2 "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_status_quoB.dta"

local rec_out3 "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_B_alts.dta"
local rec_out4 "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_C_alts.dta"

local rec_out5 "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_C_nohadd.dta"
local rec_out6 "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_B_nohadd.dta"

local rec_out7 " /home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_status_quoAmod.dta"
local rec_out8 " /home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_sc1_alts.dta"

local rec_out9 " /home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_sc2_apr_sept.dta"

local rec_out10 " /home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_sc3_sept.dta"
local rec_out11 " /home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/recreational_catches2018_sc4_apr.dta"


pause off
/* I cast 0A--99 and 0B to 999
use `rec_out2', clear
replace scenario="999" if strmatch(scenario,"0B")
destring scenario, replace

save `rec_out2', replace
*/
use `rec_out', clear

gen source="`rec_out'"

forvalues j=2/11{
append using `rec_out`j''
replace source="`rec_out`j'' "  if source==""
}


split source, parse("/") gen(ss)
scalar rnvars=r(nvars)
local all=r(varlist)
local m="ss"+scalar(rnvars)
local dropper : list all - m

drop source `dropper'
rename ss source




browse
drop if month<=4


gen cod_tot_cat=cod_num_kept+cod_num_released
gen hadd_tot_cat=haddock_num_kept+haddock_num_released
replace month=month-12 if month>=13
drop if month<=3
sort month
order cod_tot_cat hadd_tot_cat, after(month)
format *num* %09.1gc
format *mt %06.1gc
format *tot_cat %09.1gc

gen cod_mort_mt=cod_kept_mt+cod_released_dead_mt
gen hadd_mort_mt=hadd_kept_mt+hadd_released_dead_mt
drop replicate
collapse (mean) cod_tot_cat-hmax cod_mort_mt hadd_mort_mt, by(scenario month source)



collapse (p50) total_trips cod_num_kept cod_num_released cod_mort_mt hadd_mort_mt cod_kept_mt cod_released_mt hadd_kept_mt hadd_released_mt cod_avg_weight (sum) cod_ok hadd_ok (count) N=replicate, by(scenario source)
replace cod_ok=cod_ok/N*100
replace hadd_ok=hadd_ok/N*100

label var total_trips  "Trips"
label var cod_mort_mt  "Cod Mortality (mt)"
label var hadd_mort_mt "Haddock Mortality (mt)"
label var cod_kept_mt "Cod Kept (mt)"
label var cod_released_mt "Cod Released (mt)"
label var hadd_kept_mt "Haddock Kept (mt)"
label var hadd_released_mt "Haddock Released(mt)"
label var cod_ok "% Under Cod subACL"
label var hadd_ok "% Under Haddock subACL"
label var source "Where is this data"
order source, last
drop N
replace total=round(total)
format total %9.0gc


