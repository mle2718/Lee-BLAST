
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all



global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"



cd "$output_dir"
local store_name "RESULTS_SENS.xlsx"
local rec_out  "${output_dir}/recreational_catches2018_recalibrated.dta"




local rec_out4  "${output_dir}/recreational_catches2019_BRR.dta"
local rec_out6  "${output_dir}/recreational_catches2019_option1BRR.dta"
local rec_out7  "${output_dir}/recreational_catches2019_option2BRR.dta"
local rec_out8  "${output_dir}/recreational_catches2019_option3BRR.dta"
local rec_out9  "${output_dir}/recreational_catches2019_option4BRR.dta"

local rec_out5  "${output_dir}/recreational_catches2019_open_2monthsBRR.dta"


local rec_out10  "${output_dir}/recreational_catches2019_open_2moABRR.dta"
local rec_out11  "${output_dir}/recreational_catches2019_open_2moBBRR.dta"
local rec_out15  "${output_dir}/recreational_catches2019_open_2moCBBRR.dta"
local rec_out2  "${output_dir}/recreational_catches2019_open_2moFBRR.dta"
local rec_out22  "${output_dir}/recreational_catches2019_open_2moGBRR.dta"
local rec_out23  "${output_dir}/recreational_catches2019_open_monGBRR.dta"






local rec_out12  "${output_dir}/recreational_catches2019_open_monABRR.dta"
local rec_out13  "${output_dir}/recreational_catches2019_open_monBBRR.dta"
local rec_out16  "${output_dir}/recreational_catches2019_open_monCBRR.dta"
local rec_out20  "${output_dir}/recreational_catches2019_open_monFBRR.dta"

local rec_out14 "${output_dir}/recreational_catches2019_open_monBRR.dta"



local rec_out17  "${output_dir}/recreational_catches2019_open_8910_ABRR.dta"




local rec_out18  "${output_dir}/recreational_catches2019_open_8910_FBRR.dta"
local rec_out21  "${output_dir}/recreational_catches2019_open_8910_GBRR.dta"



local rec_out3  "${output_dir}/recreational_catches2019_open_2mo48aR.dta"
local rec_out24  "${output_dir}/recreational_catches2019_open_2mo48bR.dta"
local rec_out25  "${output_dir}/recreational_catches2019_open_2mo48cR.dta"
local rec_out26  "${output_dir}/recreational_catches2019_open_2mo48dR.dta"


local rec_out27  "${output_dir}/recreational_catches2019_open_monthsBRR.dta"


/*

local rec_out8  "${output_dir}/recreational_catches2019_option4.dta"
local rec_out9  "${output_dir}/recreational_catches2019_option5.dta"
local rec_out2  "${output_dir}/recreational_catches2018_calibratedS.dta"



*/

pause off
/* I cast 0A--99 and 0B to 999
use `rec_out2', clear
replace scenario="999" if strmatch(scenario,"0B")
destring scenario, replace

save `rec_out2', replace
*/
use `rec_out', clear
gen source="`rec_out'"





forvalues j=2/27{
capture append using `rec_out`j''
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
sort month
order cod_tot_cat hadd_tot_cat, after(month)
format *num* %09.1gc
format *mt %06.1gc
format *tot_cat %09.1gc

gen cod_mort_mt=cod_kept_mt+cod_released_dead_mt
gen hadd_mort_mt=hadd_kept_mt+hadd_released_dead_mt

collapse (sum) cod_tot_cat-hadd_released_dead_mt cod_mort_mt hadd_mort_mt, by(scenario replicate source)
gen cod_ok=0
replace cod_ok=1 if cod_mort_mt<=220
gen hadd_ok=0 
replace hadd_ok=1 if hadd_mort_mt<=3300
pause
gen cod_avg_weight=2204*(cod_kept_mt+cod_released_mt)/cod_tot_cat

gen haddock_relptrip=haddock_num_released/total_trips
gen haddock_landptrip=haddock_num_kept/total_trips

gen cod_relptrip=cod_num_released/total_trips
gen cod_landptrip=cod_num_kept/total_trips

collapse (p50) total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_mort_mt hadd_mort_mt cod_kept_mt cod_released_mt hadd_kept_mt hadd_released_mt cod_avg_weight haddock_relptrip haddock_landptrip cod_landptrip cod_relptrip  (sum) cod_ok hadd_ok (count) N=replicate, by(scenario source)
replace cod_ok=cod_ok/N*100
replace hadd_ok=hadd_ok/N*100

label var haddock_relptrip "Haddock released/ trip"
label var haddock_landptrip "Haddock landed/ trip"
label var cod_landptrip "Cod landed/trip"
label var cod_relptrip "Cod released/trip"

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

label var cod_num_kept "Cod kept (#)"

label var cod_num_released "Cod released (#)"
label var haddock_num_kept "Haddock kept (#)"
label var haddock_num_released "Haddock relased (#)"

replace scenario=ltrim(rtrim(itrim(scenario)))
gen strL description=""
replace description=`"2019 Status Quo"' if strmatch(scenario,"00")
replace description=`"2019 Status Quo with bad cod recruitment"' if strmatch(scenario,"0BRR")
replace description=`"2018 Calibration with updated data,effort change, and  bad cod recruitment"' if strmatch(scenario,"C0BRR")
replace description=`"2018 Calibration (final) with updated data and effort change"' if strmatch(scenario,"C0TR")
replace description=`"2018 Calibration (rejected) with updated data"' if strmatch(scenario,"UPR")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"1R")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28"' if strmatch(scenario,"2R")
replace description=`"2019 Simulation: 15" haddock  open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"3R")
replace description=`"2019 Simulation: 15" haddock open from Apr 15 - Feb 28"' if strmatch(scenario,"4R")




replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"1BRR")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28"' if strmatch(scenario,"2BRR")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock  open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"3BRR")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28."' if strmatch(scenario,"4BRR")





replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in June"' if strmatch(scenario,"open_monthR6")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in July "' if strmatch(scenario,"open_monthR7")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in August"' if strmatch(scenario,"open_monthR8")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in September"' if strmatch(scenario,"open_monthR9")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in October"' if strmatch(scenario,"open_monthR10")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in March"' if strmatch(scenario,"open_monthR15")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in April"' if strmatch(scenario,"open_monthR16")


replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in June and July "' if strmatch(scenario,"open_2monthsR6")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in July and August "' if strmatch(scenario,"open_2monthsR7")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in August and September"' if strmatch(scenario,"open_2monthsR8")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in September and October"' if strmatch(scenario,"open_2monthsR9")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in October and Nov"' if strmatch(scenario,"open_2monthsR10")
replace description=`"2019 Sim Revised: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in March and April"' if strmatch(scenario,"open_2monthsR15")





replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June"' if strmatch(scenario,"open_monthBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July "' if strmatch(scenario,"open_monthBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August"' if strmatch(scenario,"open_monthBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September"' if strmatch(scenario,"open_monthBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October"' if strmatch(scenario,"open_monthBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March"' if strmatch(scenario,"open_monthBRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in April"' if strmatch(scenario,"open_monthBRR16")


replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June and July "' if strmatch(scenario,"open_2monthsBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July and August "' if strmatch(scenario,"open_2monthsBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August and September"' if strmatch(scenario,"open_2monthsBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September and October"' if strmatch(scenario,"open_2monthsBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October and Nov"' if strmatch(scenario,"open_2monthsBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March and April"' if strmatch(scenario,"open_2monthsBRR15")





replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June"' if strmatch(scenario,"open_monthCBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July "' if strmatch(scenario,"open_monthCBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August"' if strmatch(scenario,"open_monthCBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September"' if strmatch(scenario,"open_monthCBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October"' if strmatch(scenario,"open_monthCBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March"' if strmatch(scenario,"open_monthCBRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in April"' if strmatch(scenario,"open_monthCBRR16")


replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June and July "' if strmatch(scenario,"open_2moCBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July and August "' if strmatch(scenario,"open_2moCBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August and September"' if strmatch(scenario,"open_2moCBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September and October"' if strmatch(scenario,"open_2moCBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October and Nov"' if strmatch(scenario,"open_2moCBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March and April"' if strmatch(scenario,"open_2moCBRR15")










replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June"' if strmatch(scenario,"open_monABRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July "' if strmatch(scenario,"open_monABRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August"' if strmatch(scenario,"open_monABRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September"' if strmatch(scenario,"open_monABRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October"' if strmatch(scenario,"open_monABRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March"' if strmatch(scenario,"open_monABRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in April"' if strmatch(scenario,"open_monABRR16")


replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June and July "' if strmatch(scenario,"open_2moABRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July and August "' if strmatch(scenario,"open_2moABRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August and September"' if strmatch(scenario,"open_2moABRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September and October"' if strmatch(scenario,"open_2moABRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October and Nov"' if strmatch(scenario,"open_2moABRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March and April"' if strmatch(scenario,"open_2moABRR15")


replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June"' if strmatch(scenario,"open_monBBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July "' if strmatch(scenario,"open_monBBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August"' if strmatch(scenario,"open_monBBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September"' if strmatch(scenario,"open_monBBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October"' if strmatch(scenario,"open_monBBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March"' if strmatch(scenario,"open_monBBRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in April"' if strmatch(scenario,"open_monBBRR16")


replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June and July "' if strmatch(scenario,"open_2moBBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July and August "' if strmatch(scenario,"open_2moBBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August and September"' if strmatch(scenario,"open_2moBBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September and October"' if strmatch(scenario,"open_2moBBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October and Nov"' if strmatch(scenario,"open_2moBBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March and April"' if strmatch(scenario,"open_2moBBRR15")








replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June"' if strmatch(scenario,"open_monCBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July "' if strmatch(scenario,"open_monCBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August"' if strmatch(scenario,"open_monCBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September"' if strmatch(scenario,"open_monCBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October"' if strmatch(scenario,"open_monCBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March"' if strmatch(scenario,"open_monCBRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in April"' if strmatch(scenario,"open_monCBRR16")




replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in June"' if strmatch(scenario,"open_monFBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in July "' if strmatch(scenario,"open_monFBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in August"' if strmatch(scenario,"open_monFBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in September"' if strmatch(scenario,"open_monFBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in October"' if strmatch(scenario,"open_monFBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in March"' if strmatch(scenario,"open_monFBRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in April"' if strmatch(scenario,"open_monFBRR16")

replace description=`"2019 Sim Revised with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in  August, Sept, Oct"' if strmatch(scenario,"open_8910ABRR")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in  August, Sept, Oct"' if strmatch(scenario,"open_8910FBRR")

replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in  August, Sept, Oct"' if strmatch(scenario,"open_8910GBRR")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in June and July "' if strmatch(scenario,"open_2moFBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in July and August "' if strmatch(scenario,"open_2moFBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in August and September"' if strmatch(scenario,"open_2moFBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in September and October"' if strmatch(scenario,"open_2moFBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in October and Nov"' if strmatch(scenario,"open_2moFBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in March and April"' if strmatch(scenario,"open_2moFBRR15")


replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in June"' if strmatch(scenario,"open_monGBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in July "' if strmatch(scenario,"open_monGBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in August"' if strmatch(scenario,"open_monGBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in September"' if strmatch(scenario,"open_monGBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in October"' if strmatch(scenario,"open_monGBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in March"' if strmatch(scenario,"open_monGBRR15")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in April"' if strmatch(scenario,"open_monGBRR16")



replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in June and July "' if strmatch(scenario,"open_2moGBRR6")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in July and August "' if strmatch(scenario,"open_2moGBRR7")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in August and September"' if strmatch(scenario,"open_2moGBRR8")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in September and October"' if strmatch(scenario,"open_2moGBRR9")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in October and Nov"' if strmatch(scenario,"open_2moGBRR10")
replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in March and April"' if strmatch(scenario,"open_2moGBRR15")

replace description=`"2019 Sim Revised with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in  August, Sept, Oct"' if strmatch(scenario,"open_8910GBR")

replace description=`"Option 6a : 15 haddock at 15" open from year round.  1 cod, 19" in April and August"' if strmatch(scenario,"open_2mo48a")
replace description=`"Option 6b : 15 haddock at 15" open from year round.  1 cod, 21" in April and August"' if strmatch(scenario,"open_2mo48b")
replace description=`"Option 6c : March fixed.  15 haddock at 15" open from year round.  1 cod, 19" in April and August"' if strmatch(scenario,"open_2mo48c")
replace description=`"Option 6d : March fixed. 15 haddock at 15" open from year round.  1 cod, 21" in April and August"' if strmatch(scenario,"open_2mo48d")




replace description=`"Option 6a Revised: 15 haddock at 15" open from year round.  1 cod, 19" in April and August"' if strmatch(scenario,"open_2moR48a")
replace description=`"Option 6b Revised: 15 haddock at 15" open from year round.  1 cod, 21" in April and August"' if strmatch(scenario,"open_2moR48b")
replace description=`"Option 6c Revised: March fixed.  15 haddock at 15" open from year round.  1 cod, 19" in April and August"' if strmatch(scenario,"open_2moR48c")
replace description=`"Option 6d Revised: March fixed. 15 haddock at 15" open from year round.  1 cod, 21" in April and August"' if strmatch(scenario,"open_2moR48d")



order description, after(scenario)


order source, last
drop N
replace total=round(total)
format total %9.0gc
export excel scenario description total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_mort_mt hadd_mort_mt cod_ok hadd_ok cod_kept_mt cod_released_mt hadd_kept_mt hadd_released_mt source haddock_relptrip haddock_landptrip cod_landptrip cod_relptrip  using "`store_name'", replace sheet("Summary results") firstrow(varlabels)

putexcel set "`store_name'", modify
putexcel A1:K1 , txtwrap

putexcel C2:O100 , nformat(number_sep)
putexcel close



