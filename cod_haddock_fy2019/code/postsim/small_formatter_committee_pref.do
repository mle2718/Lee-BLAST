
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all


local poststub "2019_committeeA"

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



cd "$output_dir"
local store_name "RESULTS_CMTE.xlsx"

local rec_out2  "${output_dir}/recreational_catches2019_committeeB.dta"
local rec_out3  "${output_dir}/recreational_catches2019_committeeAR.dta"
local rec_out4  "${output_dir}/recreational_catches2019_committeeBR.dta"



pause off

use `rec_out', clear
gen source="`rec_out'"





forvalues j=2/4{
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
sort month
order cod_tot_cat hadd_tot_cat, after(month)
format *num* %09.1gc
format *mt %06.1gc
format *tot_cat %09.1gc

gen cod_mort_mt=cod_kept_mt+cod_released_dead_mt
gen hadd_mort_mt=hadd_kept_mt+hadd_released_dead_mt

collapse (sum) cod_tot_cat-hadd_released_dead_mt cod_mort_mt hadd_mort_mt, by(scenario replicate source)


replace scenario=strltrim(strrtrim(stritrim(scenario)))
replace scenario="committee" if inlist(scenario,"committeeA", "committeeB")
replace scenario="committeeR" if inlist(scenario,"committeeAR", "committeeBR")

collapse (mean) cod_tot_cat-hadd_released_dead_mt cod_mort_mt hadd_mort_mt, by(scenario replicate)


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

collapse (p50) total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_mort_mt hadd_mort_mt cod_kept_mt cod_released_mt hadd_kept_mt hadd_released_mt cod_avg_weight haddock_relptrip haddock_landptrip cod_landptrip cod_relptrip  (sum) cod_ok hadd_ok (count) N=replicate, by(scenario)
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

label var cod_num_kept "Cod kept (#)"

label var cod_num_released "Cod released (#)"
label var haddock_num_kept "Haddock kept (#)"
label var haddock_num_released "Haddock relased (#)"

replace scenario=ltrim(rtrim(itrim(scenario)))
gen strL description=""
replace description=`"2019 Status Quo"' if strmatch(scenario,"00")
replace description=`"2019 Status Quo with bad cod recruitment"' if strmatch(scenario,"0BR")
replace description=`"2018 Calibration with updated data,effort change, and  bad cod recruitment"' if strmatch(scenario,"C0BR")
replace description=`"2018 Calibration (final) with updated data and effort change"' if strmatch(scenario,"C0T")
replace description=`"2018 Calibration (rejected) with updated data"' if strmatch(scenario,"UP")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"1")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28"' if strmatch(scenario,"2")
replace description=`"2019 Simulation: 15" haddock  open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"3")
replace description=`"2019 Simulation: 15" haddock open from Apr 15 - Feb 28"' if strmatch(scenario,"4")


replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"1BR")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28"' if strmatch(scenario,"2BR")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock  open from Apr 15 - Sept. 30, Nov 1 - Feb 28"' if strmatch(scenario,"3BR")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28."' if strmatch(scenario,"4BR")


replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in June"' if strmatch(scenario,"open_month6")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in July "' if strmatch(scenario,"open_month7")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in August"' if strmatch(scenario,"open_month8")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in September"' if strmatch(scenario,"open_month9")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in October"' if strmatch(scenario,"open_month10")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in March"' if strmatch(scenario,"open_month15")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in April"' if strmatch(scenario,"open_month16")


replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in June and July "' if strmatch(scenario,"open_2months6")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in July and August "' if strmatch(scenario,"open_2months7")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in August and September"' if strmatch(scenario,"open_2months8")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in September and October"' if strmatch(scenario,"open_2months9")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in October and Nov"' if strmatch(scenario,"open_2months10")
replace description=`"2019 Simulation: 17" haddock open from Apr 15 - Feb 28.  1 cod, 24" in March and April"' if strmatch(scenario,"open_2months15")





replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June"' if strmatch(scenario,"open_monthBR6")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July "' if strmatch(scenario,"open_monthBR7")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August"' if strmatch(scenario,"open_monthBR8")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September"' if strmatch(scenario,"open_monthBR9")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October"' if strmatch(scenario,"open_monthBR10")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March"' if strmatch(scenario,"open_monthBR15")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in April"' if strmatch(scenario,"open_monthBR16")


replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June and July "' if strmatch(scenario,"open_2monthsBR6")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July and August "' if strmatch(scenario,"open_2monthsBR7")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August and September"' if strmatch(scenario,"open_2monthsBR8")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September and October"' if strmatch(scenario,"open_2monthsBR9")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October and Nov"' if strmatch(scenario,"open_2monthsBR10")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March and April"' if strmatch(scenario,"open_2monthsBR15")





replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June"' if strmatch(scenario,"open_monthCBR6")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July "' if strmatch(scenario,"open_monthCBR7")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August"' if strmatch(scenario,"open_monthCBR8")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September"' if strmatch(scenario,"open_monthCBR9")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October"' if strmatch(scenario,"open_monthCBR10")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March"' if strmatch(scenario,"open_monthCBR15")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in April"' if strmatch(scenario,"open_monthCBR16")


replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June and July "' if strmatch(scenario,"open_2moCBR6")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July and August "' if strmatch(scenario,"open_2moCBR7")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August and September"' if strmatch(scenario,"open_2moCBR8")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September and October"' if strmatch(scenario,"open_2moCBR9")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October and Nov"' if strmatch(scenario,"open_2moCBR10")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March and April"' if strmatch(scenario,"open_2moCBR15")










replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June"' if strmatch(scenario,"open_monABR6")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July "' if strmatch(scenario,"open_monABR7")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August"' if strmatch(scenario,"open_monABR8")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September"' if strmatch(scenario,"open_monABR9")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October"' if strmatch(scenario,"open_monABR10")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March"' if strmatch(scenario,"open_monABR15")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in April"' if strmatch(scenario,"open_monABR16")


replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in June and July "' if strmatch(scenario,"open_2moABR6")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in July and August "' if strmatch(scenario,"open_2moABR7")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in August and September"' if strmatch(scenario,"open_2moABR8")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in September and October"' if strmatch(scenario,"open_2moABR9")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in October and Nov"' if strmatch(scenario,"open_2moABR10")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 23" in March and April"' if strmatch(scenario,"open_2moABR15")


replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June"' if strmatch(scenario,"open_monBBR6")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July "' if strmatch(scenario,"open_monBBR7")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August"' if strmatch(scenario,"open_monBBR8")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September"' if strmatch(scenario,"open_monBBR9")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October"' if strmatch(scenario,"open_monBBR10")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March"' if strmatch(scenario,"open_monBBR15")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in April"' if strmatch(scenario,"open_monBBR16")


replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June and July "' if strmatch(scenario,"open_2moBBR6")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July and August "' if strmatch(scenario,"open_2moBBR7")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August and September"' if strmatch(scenario,"open_2moBBR8")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September and October"' if strmatch(scenario,"open_2moBBR9")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October and Nov"' if strmatch(scenario,"open_2moBBR10")
replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March and April"' if strmatch(scenario,"open_2moBBR15")


replace description=`"2019 Simulation with bad cod recruitment: 15" haddock open from Apr 15 - Feb 28.  1 cod, 21" in  August, Sept, Oct"' if strmatch(scenario,"open_8910ABR")






replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in June"' if strmatch(scenario,"open_monCBR6")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in July "' if strmatch(scenario,"open_monCBR7")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in August"' if strmatch(scenario,"open_monCBR8")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in September"' if strmatch(scenario,"open_monCBR9")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in October"' if strmatch(scenario,"open_monCBR10")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in March"' if strmatch(scenario,"open_monCBR15")
replace description=`"2019 Simulation with bad cod recruitment: 17" haddock open from Apr 15 - Feb 28.  1 cod, 21" in April"' if strmatch(scenario,"open_monCBR16")




replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in June"' if strmatch(scenario,"open_monFBR6")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in July "' if strmatch(scenario,"open_monFBR7")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in August"' if strmatch(scenario,"open_monFBR8")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in September"' if strmatch(scenario,"open_monFBR9")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in October"' if strmatch(scenario,"open_monFBR10")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in March"' if strmatch(scenario,"open_monFBR15")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in April"' if strmatch(scenario,"open_monFBR16")


replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15" open from Apr 15 - Feb 28.  1 cod, 19" in  August, Sept, Oct"' if strmatch(scenario,"open_8910FBR")



replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in June and July "' if strmatch(scenario,"open_2moFBR6")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in July and August "' if strmatch(scenario,"open_2moFBR7")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in August and September"' if strmatch(scenario,"open_2moFBR8")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in September and October"' if strmatch(scenario,"open_2moFBR9")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in October and Nov"' if strmatch(scenario,"open_2moFBR10")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 15"  open from Apr 15 - Feb 28.  1 cod, 19" in March and April"' if strmatch(scenario,"open_2moFBR15")


replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in June"' if strmatch(scenario,"open_monGBR6")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in July "' if strmatch(scenario,"open_monGBR7")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in August"' if strmatch(scenario,"open_monGBR8")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in September"' if strmatch(scenario,"open_monGBR9")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in October"' if strmatch(scenario,"open_monGBR10")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in March"' if strmatch(scenario,"open_monGBR15")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in April"' if strmatch(scenario,"open_monGBR16")



replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in June and July "' if strmatch(scenario,"open_2moGBR6")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in July and August "' if strmatch(scenario,"open_2moGBR7")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in August and September"' if strmatch(scenario,"open_2moGBR8")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in September and October"' if strmatch(scenario,"open_2moGBR9")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in October and Nov"' if strmatch(scenario,"open_2moGBR10")
replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17"  open from Apr 15 - Feb 28.  1 cod, 19" in March and April"' if strmatch(scenario,"open_2moGBR15")

replace description=`"2019 Simulation with bad cod recruitment: 15 haddock at 17" open from Apr 15 - Feb 28.  1 cod, 19" in  August, Sept, Oct"' if strmatch(scenario,"open_8910GBR")

replace description=`"Option 6a: 15 haddock at 15" open from year round.  1 cod, 19" in April and August"' if strmatch(scenario,"open_2mo48a")

replace description=`"Option 6b: 15 haddock at 15" open from year round.  1 cod, 21" in April and August"' if strmatch(scenario,"open_2mo48b")

replace description=`"Option 6c: March fixed.  15 haddock at 15" open from year round.  1 cod, 19" in April and August"' if strmatch(scenario,"open_2mo48c")

replace description=`"Option 6d: March fixed. 15 haddock at 15" open from year round.  1 cod, 21" in April and August"' if strmatch(scenario,"open_2mo48d")

replace description=`"Option CMTE: 15 haddock at 17", closed march 1-april 14.  1 cod at 21", open half sept half april"' if strmatch(scenario,"committee")

replace description=`"Option CMTE: Recalibrated 15 haddock at 17", closed march 1-april 14.  1 cod at 21", open half sept half april"' if strmatch(scenario,"committeeR")


order description, after(scenario)


*order source, last
drop N
replace total=round(total)
format total %9.0gc
export excel scenario description total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_mort_mt hadd_mort_mt cod_ok hadd_ok cod_kept_mt cod_released_mt hadd_kept_mt hadd_released_mt haddock_relptrip haddock_landptrip cod_landptrip cod_relptrip  using "`store_name'", replace sheet("Summary results") firstrow(varlabels)

putexcel set "`store_name'", modify
putexcel A1:K1 , txtwrap

putexcel C2:O100 , nformat(number_sep)
putexcel close



