/* This helper file computes encounters of fish per trip in each wave, averaged over "the data."  
In this case, the data is 2009W6-2012W5 for recreational catch and 2009-2012 stock NAA. 

It puts these into the mata matrices 
cod_catch_class_by_wave and haddock_catch_class_by_wave.

Dependencies: 

globals: cod_encounters, hadd_encounters, cod_catch_class, haddock_catch_class

*/


/* Cod Encounters  */
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/$cod_catch_class", clear
BREAK
keep num_fish wave count_trips 

replace num_fish=$cod_upper_bound if num_fish>=$cod_upper_bound
collapse (sum) count_trips, by(num wave)

quietly summ wave

local p =r(min)
local q= r(max)
local n=_N+1


if `p'>1 {
	set obs `n'
	replace wave=1 if _n==_N
}
local n=_N+1

if `q'<6 {
	set obs `n'
	replace wave=6 if _n==_N
}


reshape wide count_trips, i(num_fish) j(wave)
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
putmata cod_catch_class_by_wave=(num_fish pcount*), replace

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_catch_class_wave_smoothed.dta", replace






/* Haddock Encounters  */
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/$haddock_catch_class", clear
keep num_fish wave count_trips 

replace num_fish=$haddock_upper_bound if num_fish>=$haddock_upper_bound 
collapse (sum) count_trips, by(num wave)

quietly summ wave

local p =r(min)
local q= r(max)
local n=_N+1


if `p'>1 {
	set obs `n'
	replace wave=1 if _n==_N
}
local n=_N+1

if `q'<6 {
	set obs `n'
	replace wave=6 if _n==_N
}


reshape wide count_trips, i(num_fish) j(wave)
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
putmata hadd_catch_class_by_wave=(num_fish pcount*), replace

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/hadd_catch_class_wave_smoothed.dta", replace



/*
use haddock_line_drops.dta, clear
sort hlinedrops
putmata mata_hadd_line_drops=(hlinedrops hpdf), replace
global haddock_upper_bound=hlinedrops[_N]

use cod_line_drops.dta, clear
sort clinedrops
putmata mata_cod_line_drops=(clinedrops cpdf), replace
global cod_upper_bound=clinedrops[_N]


*/
