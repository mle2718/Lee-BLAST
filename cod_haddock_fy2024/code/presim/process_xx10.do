insheet using "/home/mlee/Documents/xpbuntu/PRO_2011_FMSY.xx10", delimiter(" ")

destring, replace
foreach varname of varlist * {
	quietly sum `varname'
	if r(N)==0{
		drop `varname'
	disp "dropped `varname' for too much missing data"
	}
}

seq marker, from(1) to (4)
order marker
summ 
sort marker


label define agepro_xx10codes 1 "fishing mortality" 2 "combined catch biomass" 3 "landings" 4 "discards" 

label values marker agepro_xx10codes
