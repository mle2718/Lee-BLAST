
clear
/* be careful about the number of years */
global years 9


/* read in the 2014-2018 age structures from the 2019 M2 and MRAMP models */
/* input the age structure 
input year age1 age2 age3 age4 age5 age6 age7 age8 age9
2014 2702 627 956 439 103 28 8 3 1
2015 1184 2148 443 428 82 11 3 1 0
2016 758 965 1717 328 274 48 6 1 1 
2017 1845 617 767 1241 198 148 25 3 1
2018 2767 1503 491 560 770 111 80 14 2
end
*/
use "${source_data}/cod agepro/codagepro2021/GOM_COD_2019_M02_NAA.dta", replace
append using "${source_data}/cod agepro/codagepro2021/GOM_COD_2019_MRAMP_NAA.dta"
collapse (mean) age1-age9, by(year)
save "${source_data}/cod agepro/codagepro2021/GOM_COD_2019_BOTH_NAA.dta", replace


use "${source_data}/cod agepro/GOM_COD_2021_UPDATE_M02RETROADJUST.dta", replace
gen source=1
append using "${source_data}/cod agepro/GOM_COD_2021_UPDATE_MRAMP_M04_PROJECT_75FMSY222.dta"
replace source=2 if source==.


keep if inlist(year,2019,2020,2021)
collapse (mean) age1-age9, by(year source)
collapse (mean) age1-age9, by(year)

foreach var of varlist age1-age9{
replace `var'=`var'/1000
}

append using "${source_data}/cod agepro/codagepro2021/GOM_COD_2019_BOTH_NAA.dta"
sort year

notes: Constructed with "construct_historical_cod_NAA.do"
save "$cod_naa", replace
