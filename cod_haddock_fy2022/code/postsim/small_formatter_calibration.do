
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all



global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2022"

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"



cd "$output_dir"
*local store_name "RESULTS_SENS.xlsx"
local stub "recreational_catches_2021calibrate"
local stub2 "recreational_catches_2020statusquo"


local filelist1: dir "." files "`stub'*.dta"
local filelist2: dir "." files "`stub2'*.dta"

local combinedfiles `"`filelist1'  `filelist2' "'  
local combinedfiles `"`filelist1' "'  


*local filelist3: dir "." files "`stub'*2020_01_07_14.dta"
*local combinedfiles `"`filelist3' "'  


clear
gen str40 source=""
foreach file of local combinedfiles{
capture append using `file'
replace source="`file'"  if source==""
}



split source, parse("/") gen(ss)
scalar rnvars=r(nvars)
local all=r(varlist)
local m="ss"+scalar(rnvars)
local dropper : list all - m

drop source `dropper'
rename ss source




drop if month<=4


gen cod_tot_cat=cod_num_kept+cod_num_released
gen hadd_tot_cat=haddock_num_kept+haddock_num_released
*replace month=month-12 if month>=13
sort month
order cod_tot_cat hadd_tot_cat, after(month)
format *num* %09.1gc
format *mt %06.1gc
format *tot_cat %09.1gc

gen cod_mort_mt=cod_kept_mt+cod_released_dead_mt
gen hadd_mort_mt=hadd_kept_mt+hadd_released_dead_mt

collapse (mean) cod_tot_cat-hadd_released_dead_mt cod_mort_mt hadd_mort_mt, by(scenario month scenario_num)
collapse (sum) cod_tot_cat-hadd_released_dead_mt cod_mort_mt hadd_mort_mt, by(scenario scenario_num)
drop if scenario_num==2
order total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released 

gen str50 description=""
replace description="calibrated to 2019 total trips, monthly data for cod lengths" if scenario_num==0
replace description="calibrated to 2017-2019 total trips, monthly data for cod lengths" if scenario_num==1
replace description="calibrated to 2019 total trips, Annual data for cod lengths" if scenario_num==11
replace description="calibrated to 2017-2019 total trips, annual data for cod lengths" if scenario_num==12

sort scenario_num
browse


