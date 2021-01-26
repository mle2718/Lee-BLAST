

global my_wd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018"
global my_data_dir "$my_wd/source_data"
cd $my_wd
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/source_data/cod agepro/GOM_COD_2017_UPDATE_BOTH.dta", clear

collapse (median) age*, by(year)
reshape long age, i(year) j(aage)
rename age count
rename a age


merge m:1 age using "$my_wd/cod_smooth_age_length.dta"
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

xtline count, overlay ytitle("number (000,000s)") ttitle("Inches") tmtick(##5)
graph export "cod_length_2018.png", as(png) width(2000) replace
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/source_data/cod agepro/GOM_COD_length_structures.dta", replace




use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/source_data/haddock agepro/GOM_HADDOCK_2017_75FMSY_PROJECTIONS.dta", clear

collapse (median) age*, by(year)
reshape long age, i(year) j(aage)
rename age count
rename a age


merge m:1 age using "$my_wd/haddock_smooth_age_length.dta"
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

xtline count, overlay ytitle("number (000,000s)") ttitle("Inches") tmtick(##5)
graph export "haddock_length_2018.png", as(png) width(2000) replace

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018/source_data/haddock agepro/GOM_haddock_length_structures.dta", replace
