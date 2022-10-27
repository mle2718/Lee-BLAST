
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all


mata: haddock_maturity=(0.051,  0.324,  0.811,  0.975,  0.997,  1, 1, 1,1  ) 
mata: haddock_jan1_weights=(0.127 , 0.322, 0.552, 0.781, 1.061, 1.33 , 1.537 , 1.737,  2.25)'

mata: cod_maturity=(0.087 , 0.318 , 0.697 , 0.919 , 0.982 , 0.996,  0.999 , 1.000,  1.000  )' /*from 2015 OP UP . No change in 2019 */
mata: cod_jan1_weights=(0.057,  0.365,  0.908 , 1.662 , 2.426 , 3.307 , 4.09 , 5.928 , 10.375 )' /*from 2019 OP UP */



global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2022"

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"
global cod_naa_start "${source_data}/cod agepro/GOM_COD_2019_UPDATE_BOTH.dta"
global cod_naa_sort "$working_data/cod_beginning_sorted2019.dta"

global cod_naa_start "${source_data}/cod agepro/GOM_COD_2019_UPDATE_BOTH.dta"
global cod_naa_sort "$working_data/cod_beginning_sorted2019.dta"


global cod_naa_sort "$working_data/cod_beginning_sorted2019.dta"
global hadd_naa_start "${source_data}/haddock agepro/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS.dta"
global hadd_naa_sort "$working_data/haddock_beginning_sorted2019.dta"



global hadd_naa_fix2 "${source_data}/haddock agepro/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS_fixed.dta"


clear
/* be careful about the number of years */
global years 9
insheet using "${source_data}/haddock agepro/haddock_agepro_2019/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS_fixed.xx1", delimit(" ")

destring, replace
foreach varname of varlist * {
	quietly sum `varname'
	if r(N)==0{
		drop `varname'
	disp "dropped `varname' for too much missing data"
	}
}

global max=_N/$years

seq replicate, from(1) to ($max) block($years)
order replicate

seq year, from(1) to ($years)
order replicate year
summ 
/* 2017 to 2019*/
replace year=year+2018

rename v1 age1
rename v3 age2
rename v5 age3
rename v7 age4
rename v9 age5
rename v11 age6
rename v13 age7
rename v15 age8
rename v17 age9

notes: This contains the Jan 1 Numbers-at-Age for the GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS projection
save "$hadd_naa_fix2", replace







use "$hadd_naa_fix2"
keep if year==2021

tempfile agepro
gen str200 source="$hadd_naa_fix2"
compress
gen scenario_num=9998
gen scenario="AGEPRO_ADJ"
save `agepro', replace















use "$hadd_naa_sort"
keep if year==2021
/* you did some bad shit with the id and replicate. 
ID in the source naa data == replicate in the results data. you are dumb.
*/
drop replicate
rename id replicate
keep if replicate<=100

gen str200 source="$hadd_naa_sort"
compress
gen scenario_num=9999
gen scenario="AGEPRO"

append using `agepro'
save `agepro', replace

cd "$output_dir"

*local stub "cod_end_of_wave"
local stub "haddock_end_of_wave"

local dateread "2020_02_04"


local filelist1: dir "." files "`stub'*`dateread'*.dta"
/*local filelist2: dir "." files "`stub2'*.dta"
local filelist3: dir "." files "`stub3'*.dta"

local combinedfiles `"`filelist1'  `filelist2' `filelist3'"'  
local combinedfiles `"`filelist2' "'

local combinedfiles `"`filelist1'  `filelist2'"'  
*/
local combinedfiles `"`filelist1' "'

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

bysort replicate scenario_num (month): gen cumulative_commercial=sum(commercial_catch)
drop commercial_catch

order replicate scenario_num month
sort rep scenario_num month
keep if month==12
drop month
keep if scenario_num>=1000
keep if rep<=100
append using `agepro'


foreach var of varlist age*{
replace `var'=`var'/1000000
}

/* every replicate is coming up with the exact same cod numbers at age in months 1-12.  They change slightly in month 13 -i think that's because of recruitment all being a little different. 

The haddock numbers are a little different from months 4 and on. 
so????

*/






*graph box age* if year==2021, nooutsides legend(rows(2)) ytitle("000s of fish") title("Cod Numbers at Age 2021") subtitle("M-Ramp M=0.4 projection")

drop commercial_discards cmin hbag cbag hmax cmax cod_release_mort hadd_release_mort source cumulative_commercial year hmin

putmata NAA=(age1-age9)
mata: J1mt=(NAA*haddock_jan1_weights)*1000000 /* now this is in kg */
mata: J1mt=J1mt/1000  /* this is in metric tons */


mata: ssb=NAA:*haddock_maturity
mata: ssb=ssb*haddock_jan1_weights*1000000
mata: ssb=ssb/1000  /* this is in metric tons */

getmata J1mt=J1mt ssb=ssb


reshape long age, i(scenario_num replicate) j(ageclass)
rename age num

sort scenario_num replicate ageclass
graph box num if inlist(scenario_num,1001,2003,9998, 9999) & age>=2, over(scenario, label(angle(45))) over(ageclass)  nooutsides ytitle("Millions of fish") title("Haddock Numbers at Age in 2021") subtitle("retroadjusted M=0.2 projection") asyvars legend(order(1 "AgePro" 2 "AgePro Adjusted" 3 "BioEcon- SQ" 4 "BioEcon - Slot"))

graph export $output_dir/haddock_comparison.png, as(png) replace width(1000)


replace J1mt=J1mt/1000
replace ssb=ssb/1000
label var J1mt "Jan 1 Biomass"
label var ssb "SSB*"
graph box J1mt ssb if inlist(scenario_num,1001,2003,9998, 9999) & age==1, over(scenario, relabel(1 "AGEPRO" 2 "AGEPRO Adjusted" 3 "BioEcon SQ" 4 "BioEcon slot")) nooutsides ytitle("Weight (000s mt)") title("Haddock in 2021") subtitle("retroadjusted M=0.2 projection") 
graph export $output_dir/haddock_biomass.png, as(png) replace width(1000)
