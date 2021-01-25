

set scheme s2mono

global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"

cd "$project_dir"
use "${source_data}/cod agepro/GOM_COD_2017_UPDATE_BOTH.dta", clear

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

xtline count, overlay ytitle("number (000,000s)") ttitle("Inches") tmtick(##5) legend(rows(1))  ylabel(0(2)8)
graph export "cod_length_2018.png", as(png) width(2000) replace
save "${source_data}/cod agepro/GOM_COD_length_structures.dta", replace




use "${source_data}/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.dta", clear

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
graph export "haddock_length_2018.png", as(png) width(2000) replace

save "${source_data}/haddock agepro/GOM_haddock_length_structures.dta", replace
