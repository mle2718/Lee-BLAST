/* This small file takes the age structure xx1 file created by an AGEPRO model run 
saves the final year's numbers at age*/

clear
/* be careful about the number of years */

insheet using "${GOM_COD_A_xx1}.xx1", delimit(" ")

destring, replace
foreach varname of varlist * {
	quietly sum `varname'
	if r(N)==0{
		drop `varname'
	disp "dropped `varname' for too much missing data"
	}
}

global max=_N/$codProjyears

seq replicate, from(1) to ($max) block($codProjyears)
order replicate

seq year, from(1) to ($codProjyears)
order replicate year
summ 
/* 2017 to 2019*/
replace year=year+$cod_start_Proj-1

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

notes: This contains the Jan 1 Numbers-at-Age for the GOM_COD_2019_UPDATE_MRAMP_M04_project  projection starting from year $cod_start_Proj
save "${GOM_COD_A_xx1}.dta", replace


clear
insheet using "${GOM_COD_B_xx1}.xx1", delimit(" ")


destring, replace
foreach varname of varlist * {
	quietly sum `varname'
	if r(N)==0{
		drop `varname'
	disp "dropped `varname' for too much missing data"
	}
}

global max=_N/$codProjyears

seq replicate, from(1) to ($max) block($codProjyears)
order replicate
replace replicate=replicate+`rmax'
seq year, from(1) to ($codProjyears)
order replicate year
summ 
/* 2017 to 2019*/
replace year=year+$cod_start_Proj-1

rename v1 age1
rename v3 age2
rename v5 age3
rename v7 age4
rename v9 age5
rename v11 age6
rename v13 age7
rename v15 age8
rename v17 age9

notes: This contains the Jan 1 Numbers-at-Age for the GOM_COD_2017_UPDATE_M02_PROJECT  projection starting from year  $cod_start_Proj
save "${GOM_COD_B_xx1}.dta", replace

append using "${GOM_COD_A_xx1}.dta" 
save "$cod_naaProj", replace


clear
/* be careful about the number of years */

insheet using "${GOM_Haddock_xx1}.xx1", delimit(" ")



destring, replace
foreach varname of varlist * {
	quietly sum `varname'
	if r(N)==0{
		drop `varname'
	disp "dropped `varname' for too much missing data"
	}
}

global max=_N/$haddProjyears

seq replicate, from(1) to ($max) block($haddProjyears)
order replicate

seq year, from(1) to ($haddProjyears)
order replicate year
summ 
/* finagle the years*/
replace year=year+$hadd_start_Proj-1

rename v1 age1
rename v3 age2
rename v5 age3
rename v7 age4
rename v9 age5
rename v11 age6
rename v13 age7
rename v15 age8
rename v17 age9

notes: This contains the Jan 1 Numbers-at-Age for the GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS projection, starting from year $hadd_start_Proj
save "$hadd_naaProj", replace





