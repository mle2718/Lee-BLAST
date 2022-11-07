
clear

use "${historical_hadd_naa}", clear
destring, replace
tempfile hist_hadd
save "${historical_hadd_naa}", replace
qui summ year
local last=r(max)

use "${hadd_naaProj}", replace
keep if year>`last'

collapse (mean) age1-age9, by(year)
foreach var of varlist age1-age9{
replace `var'=`var'/1000
}
destring, replace

append using "${historical_hadd_naa}"
sort year
notes: Constructed with "construct_historical_haddock_NAA.do"
bysort year: assert _N==1
save "$hadd_naaProj_and_Hist", replace
