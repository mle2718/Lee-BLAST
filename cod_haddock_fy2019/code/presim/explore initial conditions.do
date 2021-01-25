/* explore the initial stock structures for haddock and cod */
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data"
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/haddock agepro/hadd_agepro_2012/haddock_beginning_dataset.dta", clear
bysort year: summ age*
/* do the 2012 and 2013 projections look reasonable?*/
reshape long age, i(replicate year) j(ageclass)
rename age count
replace count=count/100000
label var count "Fish (000,000s)"

forvalues myy=2011/2014{ 
	graph box count if year==`myy', over(ageclass) nooutside  title("Haddock Age Structure `myy'") yscale(range(0 100)) ylabel(0(25)100) 

	graph save "haddock`myy'age.gph", replace
	graph export "haddock`myy'age.tif", as(tif) replace
}



/* lets merge in the age-length key and compute the length structure */
rename ageclass age
merge m:1 age using "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/haddock_smooth_age_length.dta" 

keep if _merge==3
drop _merge
foreach var of varlist length5-length29{
	gen cl`var'=count*`var'
}

keep replicate year cl*

collapse (sum) cllength*, by(replicate year)
reshape long cllength, i(replicate year) j(sizeclass)
rename cllength count
label var count "Fish (000,000s)"

preserve
gen legal=sizeclass>=21
replace legal=0.5 if sizeclass>=18 & sizeclass<21

collapse (sum) count, by(replicate year legal)
bysort year legal: centile count, centile(25 50 75)
bysort year legal: summ count
restore





forvalues myy=2011/2014{ 
	graph box count if year==`myy', over(sizeclass) nooutside  title("Haddock Length Structure `myy'") yscale(range(0 20)) ylabel(0(5)20) 

	graph save "haddock`myy'length.gph", replace
	graph export "haddock`myy'length.tif", as(tif) replace
}


/* explore the initial stock structures for haddock and cod */
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/cod agepro/GOMCOD_SAW55_3BLOCK_BASE_SHORT_75FMSY_12CAT3767.dta", clear
bysort year: summ age*
/* do the 2012 projections look reasonable?*/



dups age1-age9, drop terse
reshape long age, i(replicate year) j(ageclass)
rename age count
replace count=count/100000
label var count "Fish (000,000s)"

forvalues myy=2012/2014{ 
	graph box count if year==`myy', over(ageclass) nooutside  title("Cod Age Structure `myy'") yscale(range(0 50)) ylabel(0(50)200) 

	graph save "cod`myy'age.gph", replace
	graph export "cod`myy'age.tif", as(tif) replace
}

/* lets merge in the age-length key and compute the length structure */
rename ageclass age
merge m:1 age using "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/cod_smooth_age_length.dta" 

keep if _merge==3
drop _merge
foreach var of varlist length5-length29{
	gen cl`var'=count*`var'
}

keep replicate year cl*

collapse (sum) cllength*, by(replicate year)
reshape long cllength, i(replicate year) j(sizeclass)
rename cllength count
label var count "Fish (000,000s)"


forvalues myy=2012/2014{ 
	graph box count if year==`myy', over(sizeclass) nooutside  title("Cod Length  Structure `myy'") yscale(range(0 30)) ylabel(0(5)30) 

	graph save "cod`myy'length.gph", replace
	graph export "cod`myy'length.tif", as(tif) replace
}



