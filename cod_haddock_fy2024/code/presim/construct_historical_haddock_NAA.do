
clear

use "${historical_hadd_naa}", clear
destring, replace
tempfile hist_hadd
foreach var of varlist age1-age9{
replace `var'=`var'*1000
}
save `hist_hadd', replace
qui summ year
local last=r(max)

use "${hadd_naaProj}", replace
keep if year>`last'

collapse (mean) age1-age9, by(year)
destring, replace

append using  `hist_hadd'
sort year
notes: Constructed with "construct_historical_haddock_NAA.do"
notes: units are individual fish
bysort year: assert _N==1
save "$hadd_naaProj_and_Hist", replace
