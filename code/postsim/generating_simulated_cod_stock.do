

/* This will help me investigate the uncertainty of the initial stock structure */

use "cod_numbers_at_age.dta", clear
keep if year>=2007 & year<=2009
collapse (mean) age1-age9

scalar a1=age1
scalar a2=age2
scalar a3=age3
scalar a4=age4
scalar a5=age5
scalar a6=age6
scalar a7=age7
scalar a8=age8
scalar a9=age9

scalar cv=.2
/* make up some data */

clear
set obs 1000
gen cyr1_age1=rnormal(a1, a1*cv)
gen cyr1_age2=rnormal(a2, a2*cv)
gen cyr1_age3=rnormal(a3, a3*cv)
gen cyr1_age4=rnormal(a4, a4*cv)
gen cyr1_age5=rnormal(a5, a5*cv)
gen cyr1_age6=rnormal(a6, a6*cv)
gen cyr1_age7=rnormal(a7, a7*cv)
gen cyr1_age8=rnormal(a8, a8*cv)
gen cyr1_age9=rnormal(a9, a9*cv)

save "cod_simulated_begin.dta", replace
