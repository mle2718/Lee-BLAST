/* This small file takes the age structure xx1 file created by an AGEPRO model run 
saves the final year's numbers at age*/

clear
macro drop _all
/* be careful about the number of years */
global years 12
*global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2020"
global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2022/" 

global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"

/*

insheet using "${source_data}/cod agepro/codagepro2017/GOM_COD_2017_UPDATE_MRAMP_M04_PROJECT.xx1", delimit(" ")
insheet using "${source_data}/cod agepro/codagepro2017/GOM_COD_2017_UPDATE_M02_PROJECT.xx1", delimit(" ")


insheet using "${source_data}/haddock agepro/hadd_agepro_2017/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.xx1", delimit(" ")

*/
insheet using "${source_data}/cod agepro/codagepro2021/GOM_COD_2021_UPDATE_M02RETROADJUST_PROJECT_75FMSY222/GOM_COD_2021_UPDATE_M02RETROADJUST_PROJECT_75FMSY222.xx1", delimit(" ")

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
replace year=year+2019

rename v1 age1
rename v3 age2
rename v5 age3
rename v7 age4
rename v9 age5
rename v11 age6
rename v13 age7
rename v15 age8
rename v17 age9

summ replicate
local rmax=r(max)

notes: This contains the 2019-2026 Jan 1 Numbers-at-Age for the GOM_COD_2019_UPDATE_MRAMP_M04_project  projection
save "${source_data}/cod agepro/GOM_COD_2021_UPDATE_M02RETROADJUST.dta", replace

*save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/cod agepro/cod_beginning.dta", replace


clear
insheet using "${source_data}/cod agepro/codagepro2021/GOM_COD_2021_UPDATE_MRAMP_M04_PROJECT_75FMSY222/GOM_COD_2021_UPDATE_MRAMP_M04_PROJECT_75FMSY222.xx1", delimit(" ")

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
replace replicate=replicate+`rmax'
seq year, from(1) to ($years)
order replicate year
summ 
/* 2017 to 2019*/
replace year=year+2019

rename v1 age1
rename v3 age2
rename v5 age3
rename v7 age4
rename v9 age5
rename v11 age6
rename v13 age7
rename v15 age8
rename v17 age9

notes: This contains the 2018-2019 Jan 1 Numbers-at-Age for the GOM_COD_2017_UPDATE_M02_PROJECT  projection
save "${source_data}/cod agepro/GOM_COD_2021_UPDATE_MRAMP_M04_PROJECT_75FMSY222.dta", replace

append using "${source_data}/cod agepro/GOM_COD_2021_UPDATE_M02RETROADJUST.dta"
save "${source_data}/cod agepro/GOM_COD_2021_UPDATE_BOTH.dta", replace


clear
/* be careful about the number of years */
global years 9
insheet using "${source_data}/haddock agepro/haddock_agepro_2019/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS.xx1", delimit(" ")

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
save "${source_data}/haddock agepro/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS.dta", replace





