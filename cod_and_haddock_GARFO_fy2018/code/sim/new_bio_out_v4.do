/* This is an auxillary file which I have used to process the "catch" and "release" data to construct total weight.*/
/* This file replaces bio_out.do */

/* Changelog
August 9, 2013

4.0: Now operates probabilistically...

Major revision. This now operate in mata to be synchronized with the new simulation v39+ files.

 Fixed an error regarding the length offsets
3.0: This file is coded in Imperial
3.1: the weights are now handled in the SIMULATION file in mata.
2.0: Instead of using the 'reshape' command, this file has been speeded up by using the 'stack' command. HOWEVER, it is crucial that the length and status variables are 'next to' each other!
1.1: The outputs of this file are now 2 dta files (one for each species).

*/


clear
timer on 62
getmata (length released weight dmrate)=creleased_matrix
tempfile mctemp1
save `mctemp1'
clear

getmata (length kept weight)=ckept_matrix
merge 1:1 length using  "`mctemp1'"
drop _merge
drop weight
foreach var of varlist kept released{
replace `var'=0 if `var'==.
}

gen released_dead=released*dmrate
gen released_alive=released-released_dead

note: this contains the catch and release of cod, by length in inces
save "${working_data}/cod_length_out.dta", replace


/*Retain numbers kept and released "at age" by using the length at age tables*/
tempfile kept released
replace length=length-$lngcat_offset_cod
sort length
merge 1:1 length using  "${working_data}/cod_rolling_length_to_age_key.dta"
save `released'
save `kept'

use `kept'
keep length kept age*
 

foreach var of varlist age*{
	replace `var'=`var'*kept
}
collapse (sum) age*
gen status=1
save `kept', replace


use `released'
keep length released_alive released_dead age*

drop if released_dead==.
reshape long age, i(length) j(aclass)
replace released_dead=released_dead*age
replace released_alive=released_alive*age
collapse (sum) released_dead released_alive, by(aclass)

rename released_dead released3
rename released_alive released4
reshape long released, i(aclass) j(status)
reshape wide released, i(status) j(aclass)
renvars released*, subst(released age)
save `released', replace
append using `kept'
label define status_label 0 "Released" 1 "Kept" 2 "Initial" 3 "Released dead" 4 "Released Alive"
label values status status_label
notes: this file contains kept and released fish.  It's good to keep track of these separately in order to get discard mortality correct.
sort status
save  "${working_data}/cod_ages_out.dta", replace


/* Compute weight of discarded fish 
use "cod_length_out.dta", clear
keep length released
keep if released>0
gen dead_released=released*$mortality_release
/* apply l-w equation */
gen cod_fish_weight=$kilo_to_lbs*$cod_lwa*((length)/$cm_to_inch)^$cod_lwb
gen cod_dead_weight=dead_released*cod_fish_weight
collapse (sum) cod_dead_weight
scalar cod_discarded_dead_weight=cod_dead_weight[1]
*/




/* HADDOCK OUT */
clear
getmata (length released weight dmrate)=hreleased_matrix
tempfile mhtemp1
save `mhtemp1'
clear

getmata (length kept weight)=hkept_matrix
merge 1:1 length using  "`mhtemp1'"
drop _merge
drop weight
note: this contains the catch and release of haddock , by length in inches
foreach var of varlist kept released{
replace `var'=0 if `var'==.
}

gen released_dead=released*dmrate
gen released_alive=released-released_dead
save  "${working_data}/haddock_length_out.dta", replace



/*Retain numbers kept and released "at age" by using the length at age tables*/
tempfile kept released
replace length=length-$lngcat_offset_haddock

sort length
merge 1:1 length using  "${working_data}/haddock_rolling_length_to_age_key.dta"
save `released'
save `kept'

use `kept'

keep length kept age*

foreach var of varlist age*{
	replace `var'=`var'*kept
}
collapse (sum) age*
gen status=1
save `kept', replace

use `released'
keep length released_alive released_dead age*

drop if released_dead==.
reshape long age, i(length) j(aclass)
replace released_dead=released_dead*age
replace released_alive=released_alive*age
collapse (sum) released_dead released_alive, by(aclass)

rename released_dead released3
rename released_alive released4
reshape long released, i(aclass) j(status)
reshape wide released, i(status) j(aclass)
renvars released*, subst(released age)
save `released', replace
append using `kept'
label define status_label 0 "Released" 1 "Kept" 2 "Initial" 3 "Released dead" 4 "Released Alive"
label values status status_label
notes: this file contains kept and released fish.  It's good to keep track of these separately in order to get discard mortality correct.
sort status
save   "${working_data}/haddock_ages_out.dta", replace


/* Compute weight of discarded fish 
use "haddock_length_out.dta", clear
keep length released
keep if released>0
gen dead_released=released*$haddock_mortality_release
/* apply l-w equation */
gen haddock_fish_weight=$kilo_to_lbs*$had_lwa*((length)/$cm_to_inch)^$had_lwe
gen haddock_dead_weight=dead_released*haddock_fish_weight
collapse (sum) haddock_dead_weight
scalar haddock_discard_dead_weight=haddock_dead_weight[1]
*/
timer off 62

display "new_bio_out.do done."
