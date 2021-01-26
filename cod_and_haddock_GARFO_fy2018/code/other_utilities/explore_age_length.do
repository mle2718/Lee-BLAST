/* graph and explore the haddock and cod age-length data */
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock"
use "haddock_al_key9max.dta", clear
destring, replace
scalar cm_to_inch=0.39370787
foreach var of varlist * {
	capture confirm string variable `var'
		if !_rc{
			egen `var'2 = sieve(`var'), keep(n)
			destring `var'2, replace
			drop `var'
			rename `var'2 `var'
		}
	}
		
/* here is a comment */
drop if age==0
replace length=round(length*cm_to_inch) 
replace age=9 if age>=9
 /* THIS STEP CONVERTS THINGS FROM METRIC TO IMPERIAL */

collapse (sum) count, by(age length)
/* this little step fills in any missing age and length classes with missing values */
reshape wide count, i(age) j(length)
tsset age
tsfill, full

reshape long
xtset age length
xtline count
graph save "haddock_xtline.gph", replace

xtline count, overlay
graph save "haddock_overlay.gph", replace


reshape wide count, i(length) j(age)
tsset length
tsfill, full

reshape long



reshape wide count, i(length) j(age)

foreach var of varlist count*{
	replace `var'=0 if `var'==.
	lowess `var' length, adjust bwidth(.3) gen(s`var') nograph
	replace s`var'=0 if s`var'<=0
}

drop count*

forvalues i=1/9{
	rename scount`i' count`i'
}

reshape long count, i(length) j(age)
order age length
sort age length 
xtset age length
xtline count
graph save "haddock_smooth_xt.gph", replace
xtline count, overlay
graph save "haddock_smooth_overlay.gph", replace
















/* graph and explore the haddock and cod age-length data */
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock"
use "cod_al_key.dta", clear
destring, replace
scalar cm_to_inch=0.39370787
foreach var of varlist * {
	capture confirm string variable `var'
		if !_rc{
			egen `var'2 = sieve(`var'), keep(n)
			destring `var'2, replace
			drop `var'
			rename `var'2 `var'
		}
	}
		
/* here is a comment */
drop if age==0
replace length=round(length*cm_to_inch) 
replace age=9 if age>=9
 /* THIS STEP CONVERTS THINGS FROM METRIC TO IMPERIAL */

collapse (sum) count, by(age length)
/* this little step fills in any missing age and length classes with missing values */
reshape wide count, i(age) j(length)
tsset age
tsfill, full

reshape long
xtset age length
xtline count
graph save "cod_xtline.gph", replace

xtline count, overlay
graph save "cod_overlay.gph", replace


reshape wide count, i(length) j(age)
tsset length
tsfill, full

reshape long



reshape wide count, i(length) j(age)

foreach var of varlist count*{
	replace `var'=0 if `var'==.
	lowess `var' length, adjust bwidth(.3) gen(s`var') nograph
	replace s`var'=0 if s`var'<=0
}

drop count*

forvalues i=1/9{
	rename scount`i' count`i'
}

reshape long count, i(length) j(age)
order age length
sort age length 
xtset age length
xtline count
graph save "cod_smooth_xt.gph", replace
xtline count, overlay
graph save "cod_smooth_overlay.gph", replace




replace count=0 if count==.
bysort age: egen t=total(count)
gen f=count/t
gen over22=1 if length>=22
replace over22=0 if over22==.

gen over18=1 if length>=18
replace over18=0 if over18==.

gen over20=1 if length>=20
replace over20=0 if over20==.


gen over24=1 if length>=24
replace over24=0 if over24==.


gen legal18=over18*f
gen legal20=over20*f
gen legal22=over22*f
gen legal24=over24*f


collapse (sum)legal18-legal24, by(age)


foreach var of varlist legal18-legal24{
	replace `var'=`var'*100
}
