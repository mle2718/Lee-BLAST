
set scheme s2mono

global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"

cd "$project_dir"
use "${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH.dta", clear

/* compute the average 
age1's in 2018 and 2019.  
median recruits in ramp model is
8508000
25th percentil is 4768000


median recruits in the m2 model is
4390000



25th percentil is 3082000

*/
local rampmed=8508000
local m02med=4390000

local ramp25=4768000
local m02_25=3082000

/* median recruitment */
/*
gen thresh=`rampmed' if strmatch(source,"*MRAMP*")
replace thresh=`m02med' if strmatch(source,"*M02*")
*/

/* 25th percentile recruitment */
gen thresh=`ramp25' if strmatch(source,"*MRAMP*")
replace thresh=`m02_25' if strmatch(source,"*M02*")





/*
preserve
keep year source age1
keep if year>=2018
collapse (p25) age1, by(source)
rename age1 threshold
tempfile thresh
save `thresh'

restore
merge m:1 source using `thresh', nogenerate
*/



/* tag the years in 2018 and beyond that had low recruitment */

gen low= (age1<=thresh & year>=2018)

bysort source replicate: egen tlow=total(low)
keep if tlow==2
drop low tlow 
save "${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH_low_recruits.dta", replace





collapse (median) age*, by(year)
reshape long age, i(year) j(aage)
rename age count
rename a age

/* can't find this file, change directory*/
merge m:1 age using "${working_data}/cod_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*count
}
collapse (sum)length*, by(year)
reshape long length, i(year) j(myj)
rename length count
rename myj length

xtset year length
notes drop _all
notes: this contains the numbers at lengths of cod for the current replicate
timer off 89
replace count=count/100000

xtline count, overlay ytitle("number (000,000s)") ttitle("Inches") tmtick(##5) legend(rows(1)) ylabel(0(2)8)
graph export "cod_length_bad_recruit_2018.png", as(png) width(2000) replace
save "${source_data}/cod agepro/GOM_COD_length_structures_bad_recruit.dta", replace




/*median recruits are 1581000
 25th percentils i 481000
 
 */
local haddock_med=1581000
local haddock_25=481000
use "${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.dta", clear

/*
preserve
keep year age1
keep if year>=2018
collapse (mean) age1
local thresh=age1[1]

restore

gen thresh=`thresh'
*/

/*50th percentile recruitment */
/*
gen thresh=`haddock_med'
*/
/*25th percentile recruitment */
gen thresh=`haddock_25'



/* tag the years in 2018 and beyond that had low recruitment */
gen low= (age1<=thresh & year>=2018)

bysort replicate: egen tlow=total(low)
keep if tlow==2
drop low tlow 
save "${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS_low_recruits.dta", replace



collapse (median) age*, by(year)
reshape long age, i(year) j(aage)
rename age count
rename a age


merge m:1 age using "${working_data}/haddock_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*count
}
collapse (sum)length*, by(year)
reshape long length, i(year) j(myj)
rename length count
rename myj length

xtset year length
notes drop _all
notes: this contains the numbers at lengths of haddock for the current replicate
timer off 89
replace count=count/100000

xtline count, overlay ytitle("number (000,000s)") ttitle("Inches") tmtick(##5) legend(rows(1))
graph export "haddock_length_bad_recruit_2018.png", as(png) width(2000) replace

save "${source_data}/haddock agepro/GOM_haddock_length_structures_bad_recruit.dta", replace
