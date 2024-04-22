/* This helper file computes nFc and nFh for each wave, averaged over "the data."  
In this case, the data is 2009W6-2012W5 for recreational catch and 2009-2012 stock NAA. 

It puts these into the mata matrices 
haddock_selectivity_by_wave and cod_selectivity_by_wave.

Dependencies: codmin, codmax, haddmin, haddmax globals, rec_cal_start $rec_cal_end*/
/* I can append "9" to the file names to use only 2012 data */


/* COD  Historical selectivity  */

use "$cod_historical_sizeclass", clear
rename count count
rename lngcat lngcat
drop if lngcat==.
/* ensure rec counts by waves are "full" */
quietly summ month

local p =r(min)
local q= r(max)
local n=_N+1


if `p'>1 {
	set obs `n'
	replace month=1 if _n==_N
}
local n=_N+1

if `q'<12 {
	set obs `n'
	replace month=12 if _n==_N
}
keep lng month count
reshape wide count, i(lng) j(month)




tsset lngcat
/* ensure that the lngcats are full */
summ lngcat

local minL =r(min)
local maxL= r(max)
local n=_N+1

if `minL'>$codmin{
	set obs `n'
	replace lngcat=$codmin if _n==_N
	local n=_N+1
}
	
if `maxL'<$codmax{
	set obs `n'
	replace lngcat=$codmax if _n==_N
	local n=_N+1
}
	
tsfill, full
foreach var of varlist count*{
	replace `var'=0 if `var'==.
}


/* ensure that the lengths are within the min and max length classes */
replace lngcat=$codmin if lngcat<=$codmin
replace lngcat=$codmax if lngcat>=$codmax
collapse (sum) count*, by(lngcat)

save "${working_data}/cod_length_by_month.dta", replace



/*get the age structure for the corresponding time period.  Convert it to an age structure.  Put it into mata. */
use "$cod_naa", clear
keep if year>=$rec_cal_start & year<=$rec_cal_end

collapse (sum) age1-age9
gen id=1
reshape long age, i(id) j(ageclass)
rename age stock_numbers
rename ageclass age
drop id
merge 1:1 age using "${working_data}/cod_smooth_age_length.dta"
drop _merge
drop if stock_numbers==.
foreach var of varlist length*{
	replace `var'=`var'*stock_numbers
}


collapse (sum) length*
gen id=1
reshape long length, i(id) j(length_inch)
drop id
rename length stocksize

gen lngcat=round(length)

replace lngcat=$codmin if lngcat<=$codmin
replace lngcat=$codmax if lngcat>=$codmax
collapse (sum) stocksize, by(lngcat)


note: This cod by length (inch). Merge this to the cod_hist_catch to produce a selectivity.
sort lngcat

tempfile mytemp
save `mytemp'

use "${working_data}/cod_length_by_month.dta", clear
sort lngcat


merge 1:1 lngcat using `mytemp'
drop _merge
sort lngcat

/*comment this out to skip the smoothing */
/*
forvalues j=1/6 {
	gen F`j'=count`j'/stocksize
	lowess F`j' lngcat, bwidth(.25) adjust gen(smF`j') nograph
	replace smF`j'=0 if smF`j'<=0 | smF`j'==.
	quietly summ smF`j'
	gen nFc`j'=smF`j'/r(max)
	replace nFc`j'=0 if nFc`j'<=0 | nFc`j'==.
}
*/
forvalues j=1/12 {
	gen F`j'=count`j'/stocksize
	quietly summ F`j'
	gen nFc`j'=F`j'/r(max)
	replace nFc`j'=0 if nFc`j'<=0 | nFc`j'==.
}


keep lngcat nFc*

*save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_selectivity_by_month.dta", replace
save  "${working_data}/cod_selectivity_by_month.dta", replace

putmata cod_selectivity_by_month=(lngcat nFc*), replace

/* THIS IS THE END OF COD */




/* THIS IS THE BEGINNING OF HADDOCK*/
/* Haddock Historical selectivity  */
use "$haddock_historical_sizeclass", clear
rename count count
rename lngcat lngcat
drop if lngcat==.

/* ensure rec counts by months are "full" */
quietly summ month

local p =r(min)
local q= r(max)
local n=_N+1


if `p'>1 {
	set obs `n'
	replace month=1 if _n==_N
}
local n=_N+1

if `q'<12 {
	set obs `n'
	replace month=12 if _n==_N
}
keep lng month count
reshape wide count, i(lngcat) j(month)
drop if lngcat==.



tsset lngcat
/* ensure that the lngcats are full */
summ lngcat

local minL =r(min)
local maxL= r(max)
local n=_N+1

if `minL'>$haddmin{
	set obs `n'
	replace lngcat=$haddmin if _n==_N
	local n=_N+1
}
	
if `maxL'<$haddmax{
	set obs `n'
	replace lngcat=$haddmax if _n==_N
	local n=_N+1
}
	



tsfill, full
foreach var of varlist count*{
	replace `var'=0 if `var'==.
}

/* ensure that the lengths are within the min and max length classes */
replace lngcat=$haddmin if lngcat<=$haddmin
replace lngcat=$haddmax if lngcat>=$haddmax
collapse (sum) count*, by(lngcat)




save  "${working_data}/hadd_length_by_month.dta", replace
/*get the age structure for the corresponding time period.  Convert it to an age structure.  Put it into mata. */

use "${hadd_naa}", clear
keep if year>=$rec_cal_start & year<=$rec_cal_end
collapse (sum) age1-age9
gen id=1
reshape long age, i(id) j(ageclass)
rename age stock_numbers
rename ageclass age
drop id

merge 1:1 age using "${working_data}/haddock_smooth_age_length.dta"
drop _merge
drop if stock_numbers==.
foreach var of varlist length*{
	replace `var'=`var'*stock_numbers
}


collapse (sum) length*
gen id=1
reshape long length, i(id) j(length_inch)
drop id
rename length stocksize

gen lngcat=round(length)

replace lngcat=$haddmin if lngcat<=$haddmin
replace lngcat=$haddmax if lngcat>=$haddmax
collapse (sum) stocksize, by(lngcat)


note: This haddock by length (inch). Merge this to the haddock historical catch to produce a selectivity.
sort lngcat

tempfile mytemp2
save `mytemp2'

use "${working_data}/hadd_length_by_month.dta", clear
sort lngcat


merge 1:1 lngcat using `mytemp'
drop _merge

sort lngcat
/*
forvalues j=1/12 {
	gen F`j'=count`j'/stocksize
	lowess F`j' lngcat, bwidth(.25) adjust gen(smF`j') nograph
	replace smF`j'=0 if smF`j'<=0 | smF`j'==.
	/* hand edit the F for lngcat28 in month 2*/
	replace smF`j'=smF`j'[_N-1] if _n==_N & `j'==2
	/* hand edit the F for lngcat28 in month 2*/
	quietly summ smF`j'
	gen nFh`j'=smF`j'/r(max)
	replace nFh`j'=0 if nFh`j'<=0 | nFh`j'==.

}
keep lngcat nFh*
*/

/*uncomment this to skip the smoothing */

forvalues j=1/12 {
	gen F`j'=count`j'/stocksize
	quietly summ F`j'
	gen nFh`j'=F`j'/r(max)
	replace nFh`j'=0 if nFh`j'<=0 | nFh`j'==.
}
keep lngcat nFh*








save  "${working_data}/hadd_selectivity_by_month.dta", replace
putmata hadd_selectivity_by_month=(lngcat nFh*), replace

/* THIS IS THE END OF HADDOCK */



