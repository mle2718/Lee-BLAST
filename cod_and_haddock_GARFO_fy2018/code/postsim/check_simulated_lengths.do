/* examine length distributions */
pause on
local poststub "2017_tester"

local poststub "2018_status_quo"

global my_wd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2018"
global my_data_dir "$my_wd/source_data"
cd $my_wd

local hla "$my_wd/haddock_length_class`poststub'.dta"
local cla "$my_wd/cod_length_class`poststub'.dta"



global cod_lwa 0.000005132
global cod_lwb 3.1625
global had_lwa 0.000009298
global had_lwe 3.0205
global lngcat_offset_cod 0.5
global lngcat_offset_haddock 0.5

global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787





/* cod */
use `cla', clear
drop if dum==0

foreach var of varlist kept released released_dead released_alive{
replace `var'=0 if `var'==.
}

/*compute weights 

	gen cod_fish_weight=$kilo_to_lbs*$cod_lwa*((l_in_bin)/$cm_to_inch)^$cod_lwb
	gen haddock_fish_weight=$kilo_to_lbs*$had_lwa*((l_in_bin)/$cm_to_inch)^$had_lwe

*/

	gen cod_fish_weight=$kilo_to_lbs*$cod_lwa*((length)/$cm_to_inch)^$cod_lwb
	gen kl=kept*length
	gen kw=kept*cod_fish_weight
	
	gen rl=released*length
	gen rw=released*cod_fish_weight

	gen tl=rl+kl
	gen tw=rw+kw
	
	collapse (sum) kl kw rl rw tl tw  kept released , by(month replicate scenario)
	
	gen klength=kl/kept
	gen kweight=kw/kept
	gen rlength=rl/released
	gen rweight=rw/released
	
	gen tlength=tl/(kept+released)
	gen tweight=tw/(kept+released)

	
	drop kl kw rw tl tw rl
	order scenario replicate month kweight klength kept rweight rlength released 
	drop if month==4
	replace month=month-12 if month>=13
	collapse (median) kweight-tweight, by(scenario month)
	sort scenario rep month

	browse
	
	pause
	

/* haddock */
use `hla', clear
drop if dum==0

foreach var of varlist kept released released_dead released_alive{
replace `var'=0 if `var'==.
}

/*compute weights 

	gen cod_fish_weight=$kilo_to_lbs*$cod_lwa*((l_in_bin)/$cm_to_inch)^$cod_lwb
	gen haddock_fish_weight=$kilo_to_lbs*$had_lwa*((l_in_bin)/$cm_to_inch)^$had_lwe

*/

	gen haddock_fish_weight=$kilo_to_lbs*$had_lwa*((length)/$cm_to_inch)^$had_lwe
	gen kl=kept*length
	gen kw=kept*haddock_fish_weight
	
	gen rl=released*length
	gen rw=released*haddock_fish_weight

	gen tl=rl+kl
	gen tw=rw+kw
	
	collapse (sum) kl kw rl rw tl tw  kept released , by(month replicate scenario)
	
	gen klength=kl/kept
	gen kweight=kw/kept
	gen rlength=rl/released
	gen rweight=rw/released
	
	gen tlength=tl/(kept+released)
	gen tweight=tw/(kept+released)

	
	drop kl kw rw tl tw rl

	order scenario replicate month kweight klength kept rweight rlength released 
	drop if month==4
	replace month=month-12 if month>=13
	sort scenario rep month
	browse
	pause
	

	
	
	 
