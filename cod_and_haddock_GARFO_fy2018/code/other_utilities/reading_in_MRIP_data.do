/* Reading in scotts data */
clear
set scheme s2mono
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/MRIP data"
/* Cod harvest */
pause on
local yearlist 2011 2012 2013
/* you still have to update the data 1 more time (the catch class distributions are still wrong)*/
local yearlist 2013

foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"
	clear
	import excel `myfilename', sheet("A") cellrange(A1:G10) firstrow
	gen year=`myy'
	renvars, lower
save "cod_catch_by_wave`myy'.dta", replace
}

	
	
/*	
	
	drop if wave==.
	drop area
	rename tot total_catch
	/*
	quietly count if total_catch==.
	assert r(N)>0
	drop if total_catch==. */
	rename landings landings
	rename releaseb2 b2
	renvars, lower
	notes: these are cod landings by wave
 
	order wave a b1 b2 landings total_catch

/* set everything for wave 1=0 */
sort wave
if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	foreach var of varlist *{
		replace `var'=0 if `var'==. 
	}
}
sort wave
format * %10.0fc
save "cod_catch_by_wave`myy'.dta", replace
}


*/





/* haddock harvest */

foreach myy of local yearlist{
local myfilename "MRIP`myy'.xlsx"

clear
import excel `myfilename', sheet("B") cellrange(A1:G10) firstrow
	gen year=`myy'
	renvars, lower

	save "haddock_catch_by_wave`myy'.dta", replace
}

	
	/*
	drop if wave==.
	drop area
	rename tot total_catch
	/*
	quietly count if total_catch==.
	assert r(N)>0
	drop if total_catch==. */
	rename landing landings
	rename releaseb2 b2
	renvars, lower
	notes: these are cod landings by wave
	order wave a b1 b2 landings total_catch

/* set everything for wave 1=0 */
sort wave
if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	foreach var of varlist *{
		replace `var'=0 if `var'==. 
	}
}
sort wave
format * %10.0fc
tsset wave

save "haddock_catch_by_wave`myy'.dta", replace
}
*/


foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"


/* cod catch-class distribution */
clear
import excel `myfilename', sheet("C") cellrange(A1:F300) firstrow
gen year=`myy'
	renvars, lower

save "cod_catch_class_by_wave`myy'.dta", replace
}

/*

destring, replace

drop if wave==.

renvars, lower
xtset wave num
format count stddev %8.0fc
notes: these are cod catch-class distributions by wave


*/

foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"
 /* haddock catch-class distribution */
clear
import excel `myfilename', sheet("D") cellrange(A1:F300) firstrow
gen year=`myy'
	renvars, lower

save "haddock_catch_class_by_wave`myy'.dta", replace
}
/*
destring, replace
drop if wave==.

renvars, lower
xtset wave num
format count stddev %8.0fc
notes: these are haddock catch-class distributions by wave
*/

foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"

/* cod size class  distribution */
clear
import excel `myfilename', sheet("E") cellrange(A1:E300) firstrow
gen year=`myy'
	renvars, lower

save "cod_size_class_by_wave`myy'.dta", replace
}

/*
destring, replace
drop if wave==.
renvars, lower
format count %8.0fc
notes: these are cod catch-at-length distributions by wave, constructed for FY2013 
xtset wave lngcat
*/


foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"


 /* haddock size class  distribution */
clear
import excel `myfilename', sheet("F") cellrange(A1:E350) firstrow
gen year=`myy'
	renvars, lower

save "haddock_size_class_by_wave`myy'.dta", replace
}

/*
destring, replace
drop if wave==.
renvars, lower
format count %8.0fc
notes: these are haddock catch-at-length distributions by wave, constructed for FY2013 
format count %8.0fc
xtset wave lngcat
*/

foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"
 /* harvest or targeted cod   */
clear
import excel `myfilename', sheet("G") cellrange(A1:C10) firstrow
gen year=`myy'
	renvars, lower

save "cod_harvested_or_targeted_by_wave`myy'.dta", replace
}
/*
destring, replace
drop if wave==.
renvars, lower
format count %8.0fc
notes: these are "Cod trips" by wave, constructed for FY2013 
sort wave
if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	foreach var of varlist *{
		replace `var'=0 if `var'==. 
	}
}
sort wave
format trips standard %7.0gc
*/


foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"
 /* harvest or targeted haddock    */
clear
import excel `myfilename', sheet("H") cellrange(A1:C10) firstrow
gen year=`myy'
	renvars, lower

save "haddock_harvested_or_targeted_by_wave`myy'.dta", replace
 }
/*

destring, replace
drop if wave==.
renvars, lower
format count %8.0fc
notes: these are haddock trips by wave, constructed for FY2013 
sort wave
if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	foreach var of varlist *{
		replace `var'=0 if `var'==. 
	}
}
sort wave
format trips standard %7.0gc
*/






 
 foreach myy of local yearlist{
	local myfilename "MRIP`myy'.xlsx"

/* harvest or targeted either    */
clear
import excel `myfilename', sheet("I") cellrange(A1:C10) firstrow
gen year=`myy'
	renvars, lower

save "groundfish_targeted_or_harvested_by_wave`myy'.dta", replace
}

/*
destring, replace
drop if wave==.
renvars, lower
format count %8.0fc
notes: these are Total trips by wave, constructed for FY2013 
sort wave
if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	foreach var of varlist *{
		replace `var'=0 if `var'==. 
	}
}
sort wave
format trips standard %7.0gc

*/

