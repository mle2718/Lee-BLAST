
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO"

/* This will help me investigate the uncertainty of the initial stock structure */

use "haddock_numbers_at_age.dta", clear
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
gen age1=rnormal(age1, age1*cv)
