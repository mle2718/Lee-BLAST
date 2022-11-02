
clear


/* read in the age  structures 

input year age1 age2 age3 age4 age5 age6 age7 age8 age9
2014 140737 20324 3815 8887 676 150 63 206 502
2015 7962 115142 16426 2982 6673 484 103 41 466
2016 7502 6516 93580 13099 2324 5061 359 75 370
2017 12480 6139 5286 74140 10087 1729 3661 251 313
2018 3246 10213 4984 4198 57351 7558 1262 2592 399 
end

save "${historical_hadd_naa}",  replace
*/

use "${hadd_naaProj}", replace
collapse (mean) age1-age9, by(year)
keep if inlist(year,2019,2020,2021)
foreach var of varlist age1-age9{
replace `var'=`var'/1000
}
append using "${historical_hadd_naa}"
sort year
notes: Constructed with "construct_historical_haddock_NAA.do"

save "$hadd_naaProj_and_Hist", replace
