/* open data before this point */
merge m:1 age using "$working_data/cod_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*j1count
}
keep age length*
reshape long length, i(age) j(s)
rename age pp
rename length age
rename s length

reshape wide age, i(length) j(pp)

tempvar tempsum
local mysummer="0"
foreach var of varlist age*{
	local mysummer="`mysummer'+`var'"
}

gen double `tempsum'=`mysummer'

foreach var of varlist age*{
	replace `var'=`var'/`tempsum'
}
keep length age*
save "$working_data/cod_rolling_length_to_age_key.dta", replace


/* this goes ``before'' the kept and released data */
