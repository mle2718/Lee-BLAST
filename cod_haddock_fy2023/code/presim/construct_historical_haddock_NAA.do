
clear
/* be careful about the number of years */
global years 9


/* enter in the NAA from 2014-2018 from the stock assessment */

input year age1 age2 age3 age4 age5 age6 age7 age8 age9
2014 140737 20324 3815 8887 676 150 63 206 502
2015 7962 115142 16426 2982 6673 484 103 41 466
2016 7502 6516 93580 13099 2324 5061 359 75 370
2017 12480 6139 5286 74140 10087 1729 3661 251 313
2018 3246 10213 4984 4198 57351 7558 1262 2592 399 
end
 
save "${source_data}/haddock agepro/haddock_agepro_2019/GOM_HADDOCK_2019_NAA.dta", replace


use "${source_data}/haddock agepro/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS.dta", replace
collapse (mean) age1-age9, by(year)
keep if inlist(year,2019,2020,2021)
foreach var of varlist age1-age9{
replace `var'=`var'/1000
}
append using "${source_data}/haddock agepro/haddock_agepro_2019/GOM_HADDOCK_2019_NAA.dta"
sort year
notes: Constructed with "construct_historical_haddock_NAA.do"

save "$hadd_naa", replace
