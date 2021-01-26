/* 
setup_monthly_encounters_per_trip.do
This helper file computes encounters of fish per trip in each month, averaged over "the data."  
In this case, the data is 2009W6-2012W5 for recreational catch and 2009-2012 stock NAA. 

It puts these into the mata matrices 
cod_catch_class_by_month and haddock_catch_class_by_month.

Dependencies: 

globals: cod_encounters, hadd_encounters, cod_catch_class, haddock_catch_class

*/


/* Cod Encounters  */
use $cod_catch_class, clear
keep num_fish month count 

replace num_fish=$cod_upper_bound if num_fish>=$cod_upper_bound
collapse (sum) count, by(num month)

quietly summ month

local p =r(min)
local q= r(max)
local n=_N+1


if `p'>1 {
	set obs `n'
	replace month=1 if _n==_N
}
local n=_N+1

if `q'<$periods_per_year {
	set obs `n'
	replace month=$periods_per_year if _n==_N
}


reshape wide count, i(num_fish) j(month)
drop if num_fish==.
tsset num_fish 
tsfill, full

/* Skip the smoothing?  Comment out next two for loops

foreach var of varlist count*{
	replace `var'=0 if `var'==.
	lowess `var' num_fish if num_fish>0, nograph mean bwidth(0.3) gen(t`var')
	replace t`var'=`var' if num_fish==0
	replace t`var'=0 if t`var'<=0
	egen double z= total(t`var')
	gen double p`var'=t`var'/z
	drop z	
}
foreach var of varlist pcount*{
	replace `var'=0 if `var'==.
}
*/



foreach var of varlist count*{
	replace `var'=0 if `var'==.
	egen double z=total(`var')
	gen double p`var'=`var'/z
	drop z
}



keep num_fish p* 
putmata cod_catch_class_by_month=(num_fish pcount*), replace

save "${working_data}/cod_catch_class_month_smoothed.dta", replace






/* Haddock Encounters  */
use $haddock_catch_class, clear
keep num_fish month count 

replace num_fish=$haddock_upper_bound if num_fish>=$haddock_upper_bound 
collapse (sum) count, by(num month)

quietly summ month

local p =r(min)
local q= r(max)
local n=_N+1


if `p'>1 {
	set obs `n'
	replace month=1 if _n==_N
}
local n=_N+1

if `q'<$periods_per_year {
	set obs `n'
	replace month=$periods_per_year if _n==_N
}


reshape wide count, i(num_fish) j(month)
drop if num_fish==.
tsset num_fish 
tsfill, full
/*
/* Skip the smoothing?  Comment out next two for loops*/

foreach var of varlist count*{
	replace `var'=0 if `var'==.
	lowess `var' num_fish if num_fish>0, nograph mean bwidth(0.3) gen(t`var')
	replace t`var'=`var' if num_fish==0
	replace t`var'=0 if t`var'<=0
	egen double z= total(t`var')
	gen double p`var'=t`var'/z
	drop z	
}
foreach var of varlist pcount*{
	replace `var'=0 if `var'==.
}

*/
foreach var of varlist count*{
	replace `var'=0 if `var'==.
	egen double z=total(`var')
	gen double p`var'=`var'/z
	drop z
}

keep num_fish p* 
putmata hadd_catch_class_by_month=(num_fish pcount*), replace

save "${working_data}/hadd_catch_class_month_smoothed.dta", replace

/*end setup_monthly_encounters_per_trip.do
*/
