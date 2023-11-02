
clear

/* read in the age  structures */

use "${historical_cod_naaA}", replace
append using "${historical_cod_naaB}"
collapse (mean) age1-age9, by(year)



destring, replace
save "${historical_cod_naaBoth}", replace
tempfile hist_cod
foreach var of varlist age1-age9{
replace `var'=`var'*1000
}
save `hist_cod', replace





qui summ year
local last=r(max)

use "${GOM_COD_A_xx1}.dta", replace
gen source=1
append using "${GOM_COD_A_xx1}.dta"
replace source=2 if source==.


keep if year>`last'
collapse (mean) age1-age9, by(year source)
collapse (mean) age1-age9, by(year)


append using `hist_cod'
sort year
bysort year: assert _N==1
notes: Constructed with "construct_historical_cod_NAA.do"
notes: individual ish

save "$cod_naaProj_and_Hist", replace
