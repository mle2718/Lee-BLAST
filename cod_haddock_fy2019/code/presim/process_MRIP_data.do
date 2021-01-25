clear
set scheme s2mono
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/MRIP data"
pause on
local yearlist 2011 2012 2013
/* PROCESS COD */

/*C1.  Process cod catch by wave */

local tlist: dir . files "cod_catch_by_wave*.dta"
dsconcat `tlist'

/* drop empty waves*/
drop if wave==.

/* Add wave 1 for each year if missing*/
sort year wave
order year wave

if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	replace year=2011 if year==.
}
tsset year wave
tsfill, full
/* fill wave 1 in with zeros */

encode area, gen(myarea)
drop area
rename myarea area
	foreach var of varlist wave-a {
		replace `var'=0 if `var'==. 
	}


replace area=1 if area==.

sort year wave
format * %10.0fc
format year %4.0f

rename landing landings
rename releaseb2 b2
rename tot_c total_catch
renvars, lower
notes: these are cod landings by year and wave

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/cod_landings_2011_2013.dta", replace

/*C2.  Process cod numbers per trip, by wave*/
clear
local tlist: dir . files "cod_catch_class_by_wave*.dta"
dsconcat `tlist'

/* drop empty waves*/
drop if wave==.

collapse (sum) count_trips, by(wave num_fish)

sort wave

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/cod_catch_class_2011_2013.dta", replace



/*C3.  Process size class by wave*/
clear
local tlist: dir . files "cod_size_class_by_wave*.dta"
dsconcat `tlist'

/* drop empty waves*/
drop if wave==.

collapse (sum) countnumber, by(wave lngcat)

sort wave lngcat

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/cod_size_class_2011_2013.dta", replace





























/* PROCESS Haddock */
/*H1.  Process haddock catch by wave */
clear
local tlist: dir . files "haddock_catch_by_wave*.dta"
dsconcat `tlist'

/* drop empty waves*/
drop if wave==.

/* Add wave 1 for each year if missing*/
sort year wave
order year wave

if wave[1]==2{
	local myn=_N+1
	set obs `myn'
	replace wave=1 if wave==.
	replace year=2011 if year==.
}
tsset year wave
tsfill, full
/* fill wave 1 in with zeros */

encode area, gen(myarea)
drop area
rename myarea area
	foreach var of varlist wave-a {
		replace `var'=0 if `var'==. 
	}


replace area=1 if area==.

sort year wave
format * %10.0fc
format year %4.0f
rename landing landings
rename releasedb2 b2
rename tot_c total_catch
renvars, lower
notes: these are haddock landings by year and wave

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/haddock_landings_2011_2013.dta", replace

clear


/*H2.  Process haddock numbers per trip, by wave*/
clear
local tlist: dir . files "haddock_catch_class_by_wave*.dta"
dsconcat `tlist'

/* drop empty waves*/
drop if wave==.

collapse (sum) count_trips, by(wave num_fish)

sort wave

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/haddock_catch_class_2011_2013.dta", replace


/*H3.  Process haddock size class by wave*/
clear
local tlist: dir . files "haddock_size_class_by_wave*.dta"
dsconcat `tlist'

/* drop empty waves*/
drop if wave==.

collapse (sum) countnumber, by(wave lngcat)

sort wave lngcat

save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/haddock_size_class_2011_2013.dta", replace










