set scheme s2mono

global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2020"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"

cd "$project_dir"


global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

global cm_to_inch=0.39370787

/* average length of a cod, by age */
use $codalkey, clear

gen length_inch=$cm_to_inch*length

gen tl=count*length_inch
collapse (sum) tl count, by(age)
gen length_inch=tl/count
order age length_inch
list age length_inch


/* 

     | age   length~s |
     |----------------|
  1. |   0   4.330787 |
  2. |   1   8.945409 |
  3. |   2    15.9349 |
  4. |   3    20.8868 |
  5. |   4   23.48388 |
     |----------------|
  6. |   5    27.2328 |
  7. |   6   29.33525 |
  8. |   7   32.50902 |
  9. |   8   28.74067 |  <- this is odd
*/

clear
use $haddalkey, clear

gen length_inch=$cm_to_inch*length

gen tl=count*length_inch
collapse (sum) tl count, by(age)
gen length_inch=tl/count

order age length_inch
list age length_inch

/*
     | age   length~h |
     |----------------|
  1. |   0   5.731191 |
  2. |   1   9.099852 |
  3. |   2   12.75204 |
  4. |   3   15.49764 |
  5. |   4   16.90616 |
     |----------------|
  6. |   5   19.31345 |
  7. |   6   20.33935 |
  8. |   7    20.6148 |
  9. |   8   21.65393 |
 10. |   9   23.33084 |
*/


use "${source_data}/cod agepro/GOM_COD_2019_UPDATE_BOTH.dta", clear
keep if inlist(year, 2019, 2020)
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
local myplotopts " overlay plot1opts(lwidth(thin) lpattern(dash)) plot2opts(lwidth(thick) lpattern(solid)) legend(rows(1)) ttitle("Inches") tmtick(##5) "
local addopts "tline(8.9 15.9 20.9 23.5 27.2 29.3 32.5, lwidth(vthin) lpattern(dash) lcolor(gs10))"
xtline count,   ytitle("number (000,000s)")  ylabel(0(2)8)  title("Cod Lengths")  `myplotopts' `addopts'
graph export "cod_length_2019_2020.png", as(png) width(2000) replace
save "${source_data}/cod agepro/GOM_COD_length_structures1920.dta", replace



use "${source_data}/haddock agepro/GOM_HADDOCK_2019_FMSY_RETROADJUSTED_PROJECTIONS.dta", clear
keep if inlist(year, 2019, 2020)

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
local addopts "tline(9.1 12.8 15.5 16.9 19.3 20.34 20.6 21.7 23.3, lwidth(vthin) lpattern(dash) lcolor(gs10))"

xtline count,   ytitle("number (000,000s)")  title("Haddock Lengths")   `myplotopts' `addopts'
graph export "haddock_length_2019_2020.png", as(png) width(2000) replace

save "${source_data}/haddock agepro/GOM_haddock_length_structures1920.dta", replace


xtline count,   ytitle("number (000,000s)")  title("Haddock Lengths")   `myplotopts'
graph export "haddock_length_2019_2020_nolines.png", as(png) width(2000) replace

