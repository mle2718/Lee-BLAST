/* This takes the flat file and converts it into the probability matrix for haddock */
/* the column has the 'age' and each entry has the probability of the fish being a particular length */
/*
rename var1 age
rename var2 haddock

V1.0  Dec 26-  this file is coded in metric


*/
use"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/haddock_al_key9max.dta", clear

destring, replace

foreach var of varlist age length count{
	capture confirm string variable `var'
		if !_rc{
			egen `var'2 = sieve(`var'), keep(n)
			destring `var'2, replace
			drop `var'
			rename `var'2 `var'
		}
	}
		
/* here is a comment */

collapse (sum) count, by(age length)
quietly summ length, meanonly
local mymin=r(min)
local mymax=r(max)
reshape wide count, i(age) j(length)

tsset age

tsfill, full

order age count*

gen total=0
 foreach var of varlist count* {
	replace `var'=0 if `var'==.
	replace total=total+`var'
	}
compress



forvalues ii = `mymin'/`mymax' {
	gen hatl`ii'=count`ii'/total
	replace hatl`ii'=0 if hatl`ii'==.
	label var hatl`ii' "mapping ages to lengths"
}

macro drop mymin mymax
drop total

drop count*

sort age
tsset, clear
save"/home/mlee/Documents/Workspace/recreational_simulations/haddock_al_key_final.dta", replace

