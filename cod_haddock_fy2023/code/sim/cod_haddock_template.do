/**************************************************************/
/*************************************************************/
/*************************************************************/

/*
This .do file was written by Min-Yang.Lee@noaa.gov 
Version 1.2019
Dec 3, 201

Calibrated to the 3 year average of trips (320,750).  If you want to simulate "opening" one of the partially closed months, you need to adjust the rec_wave matrix
TABLE OF CONTENTS
0.  File description, Meta Data, changegoals, and changelog
1.  Global, scalar, and other setup (parameterization)
2.  Reading in?
3.  Population Dynamics -- including call to economic model
4.  Loop?
*/


/* changes
A. Deal with folders a little more intelligently
	Folders for source data
	

 */

/* BEGIN Section 0: FILE DESCRIPTION */

/* This is a wrapper for my simulation. 
0.  I set up a bunch of parameters in the begining. These have been moved into helper files that just contain "data"
1. Read in cod and haddock stock sizes for a particular year
2. Perform the projection as defined by the nice people in Population Dynamics with the following modifications:
	a.  We have Quota (not F-based) catch.  
	b.  We have 2 fleets -- commercial and recreational.
	c.  Commercial catch is based directly on the sub-ACL.
	d.  Recreational catch is determined endogenously by the recreational sub-model
3.  To do step 2, we need to have 
	a.  the age-0 sub-model in place (recruitment)
	b.  Biological parameters including fully-recruited selectivity (F), natural mortality (M), and selectivity.  
	c.  The ``timing'' of the model must be known.	THE TIMING OF THE MODEL IS SET UP AS
		i.	Recreational fishing occurs first.
		ii.	Commercial and Natural Mortality occur simultanously
		ii.	Recruitment (production of Age-0)
		iii. 	Aging up
		
		
		
4.  This file policy scenarios across `replicates'. Waves nest within replicates.  Every policy scenario with the same replicate BEGINS with the same stock conditions, but does not necessarily have the same recruitment 
or sequence of expected catch. 
*/


/* 	
A NOTE ON TIMING:  
For "normal wave" (anything which is not wave 6), The end of wave NAA are exactly equal to the NAA for the beginning of the next wave.  These are "posted" into the species1 and species2 files.  
	The End of wave NAA are simply the Initial NAA minus natural mortality, commercial mortality, and recreational mortality.

		NAA_a,w = NAA_{a-1,w-1} - natural_mortality_deaths_{a-1,w} -commercial_fishing_deaths_{a-1,w} - recreational_fishing_deaths_{a-1,w} \forall a \in 1,\ldots, 9

For wave 6, we assume that recruitment and ageing up occurs before the end of the wave  
	Therefore, the NAA at the end of wave 6 is "Translated" and "Recruited" Intial NAA minus natural mortality, commercial mortality, recreational mortality.
	
		NAA_a,6 = NAA_{a-1,5} - natural_mortality_deaths_{a-1,6} -commercial_fishing_deaths_{a-1,6} - recreational_fishing_deaths_{a-1,6} \forall a \in 2,\ldots, 9
		NAA_1 = Recruitment

Therefore, we can go into the species 1 and 2 files and look up recruitment by examining the wave 6 age-1 class.

SSB: I can compute SSB 'after the loop' 
"multiply" by the maturity-at-age.  
multiply by weight-at-maturity.

*/


/* HACKS  and To Do
2.  The minimum sizes of cod and haddock must be user specified
3.  The number of age classes for cod and haddock must be known in advance [not a big problem, this is always known from the agepro files]
4.  The age-length key for GOM cod is really sparse.
*/



/**********************END SECTION 0: FILE DESCRIPTION******************/
/*************************************************************/
*************************************************************/

/* Preamble */

clear
mata:mata clear
scalar drop _all
matrix drop _all
pause off


/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2023" 
	global MRIP_dir  "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2022_12_20" 
}



if strmatch("$user","minyangNix"){
	global project_dir "${myroot}/BLAST/READ-SSB-Lee-BLAST/cod_haddock_fy2023"
	global MRIP_dir "${myroot}/BLAST/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2022_12_19" 
}

/* setup directories */
global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"
global mrip_source_data "${source_data}/mrip"

/* setup date/time for file logging */
local date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
local date=subinstr(trim("`date'"), " " , "_", .)
local time: display c(current_time)
local time=subinstr(trim("`time'"),":","_",.)
local hours=substr("`time'",1,2)
local mins=substr("`time'",4,2)

/*
2021calibrate - 4 sets of regs that i'm using to calibrate the 2021 model.
2022SQ is a copy of the 2021calibrate.
*/

global rec_management "2023_size_limits"

local poststub="$rec_management"+"_"+"`date'"+"_"+"`hours'"
cd $project_dir


log using "${output_dir}/cod_and_haddock_`poststub'.smcl", replace
version 12

set more off
set seed 8675309
timer clear
timer on 99

/* specify names of save files */

/*These save files are used by post with the replace option. */
local econ_out "${output_dir}/economic_data_`poststub'"
local rec_out  "${output_dir}/recreational_catches_`poststub'"
local sp1_out  "${output_dir}/cod_end_of_wave_`poststub'"
local sp2_out  "${output_dir}/haddock_end_of_wave_`poststub'"
local cod_catch_class  "${output_dir}/cod_catch_class_dist_`poststub'"
local haddock_catch_class  "${output_dir}/haddock_catch_class_`poststub'"
local cod_land_class  "${output_dir}/cod_land_class_dist_`poststub'"
local haddock_land_class  "${output_dir}/haddock_land_class_`poststub'"
local hla  "${output_dir}/haddock_length_class_`poststub'"
local cla  "${output_dir}/cod_length_class_`poststub'"

/*These save files are used by post with the replace option. 
If they already exist, I can either overwrite (by passing a NULL suffix with <ENTER>) or I can make new files by passing in suffix*/

capture confirm file "`rec_out'.dta"
 if !_rc {
  display "Output files already exist. I need a suffix for the save files.  Press <ENTER> to overwrite"_request(suffix)
}

*di "$suffix"

local econ_out "`econ_out'$suffix.dta"

local rec_out "`rec_out'$suffix.dta"
local sp1_out "`sp1_out'$suffix.dta"
local sp2_out "`sp2_out'$suffix.dta"
local cod_catch_class "`cod_catch_class'$suffix.dta"
local haddock_catch_class "`haddock_catch_class'$suffix.dta"
local cod_land_class "`cod_land_class'$suffix.dta"

local haddock_land_class "`haddock_land_class'$suffix.dta"
local hla "`hla'$suffix.dta"
local cla "`cla'$suffix.dta"

*mac list




/* setup storage for length structures of simulated kept and released */
preserve
clear
save `hla', replace emptyok
save `cla', replace emptyok
restore




/* specify name of file containing regulations */
do "${code_dir}/sim/prep_regs.do"

levelsof scenario, local(scenario_list)

/* Is the model running waves or months? */
global months=12
global waves=6
global periods_per_year=$months

/*how many years, replicates */
global total_reps=2

global total_years_sim=1
local max_months=($months*$total_years_sim) + 4

/*Setup model calibration*/

*global tot_trips 646340
global scale_factor 10
*global numtrips=$tot_trips/$scale_factor

global which_year=2023

global expectation_reps 10

/* read in biological data, economic data, and backround data on catch from the commercial fishery*/
do "${code_dir}/presim/cod_hadd_bio_params.do"

do "${code_dir}/presim/economic_parameters_mod.do"
do "${code_dir}/presim/commercial_quotas.do"








/* These globals contain the locations of the cod age-length key raw data */
/* do these 2 change?"

*/
global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

disp "Are you calibrating or running the model?  Be sure that the Initial stock conditions are properly set at bookmarks 1 and 2."
pause

/* set up the name of the postfiles.  These names are use by the postfile command*/
tempname species1 species2 species1b species2b economic rec_catch

postfile `economic' str32(scenario) scenario_num month choice_occasions total_trips WTP CV_A CV_E replicate cbag hbag cmin hmin cmax hmax codbag_comply cod_sublegal_keep cod_release_mort hadd_release_mort using `econ_out', replace
postfile `rec_catch' str32(scenario) scenario_num month choice_occasions total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_kept_mt cod_released_mt cod_released_dead_mt hadd_kept_mt hadd_released_mt hadd_released_dead_mt replicate  cbag hbag cmin hmin cmax hmax crep hrep codbag_comply cod_sublegal_keep cod_release_mort hadd_release_mort using `rec_out', replace

postfile `species1' str32(scenario) scenario_num  month commercial_catch commercial_discards age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate  cbag hbag cmin hmin cmax hmax cod_release_mort hadd_release_mort using `sp1_out', replace
postfile `species2' str32(scenario) scenario_num month commercial_catch commercial_discards age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate  cbag hbag cmin hmin cmax hmax cod_release_mort hadd_release_mort using `sp2_out', replace

/*
postfile `species1b' wave age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate cbag hbag cmin hmin cmax hmax using "cod_beginning_of_wave.dta", replace
postfile `species2b' wave age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate cbag hbag cmin hmin cmax hmax using "haddock_beginning_of_wave.dta", replace
*/

/* set up the tempfiles to store cod and haddock eoy temporary data*/
tempfile holdingbin_yr3  holdingbin_yr2 holdingbin_yr1 

/* Setup holding file for length structure of cod discards */ 
preserve
clear
set obs 1
gen month=.
gen replicate=.
gen length=.
gen released=.
gen haddockbag=.
gen cod_min=.
gen cod_max=.
gen hadd_min=.
gen hadd_max=.
gen fishing_year=.
save "${working_data}/cod_discard_saver.dta", replace
restore

do "${code_dir}/sim/historical_rec_regulations.do"






/* Compute the distribution of effort by the recreational fishery in each wave or month
Right now this distribution is hard coded -- one day it should be set up to look at the data*/
/* Allocate the commercial cod and haddock mortality to each of the 6 waves.  Allocate the recreational effort to each of the waves*/


mata: 
recreational_effort_waves = (1,0 \ 2,0.0 \ 3,0.28 \ 4,0.60 \ 5, 0.09 \ 6, 0.00)
recreational_effort_months = (1,0.0 \ 2, 0.0 \ 3, 0.00 \ 4, 0.4158 \ 5, 0.1160 \ 6, 0.06353\ 7 ,0.0909 \ 8, 0.1237 \ 9 , 0.1635 \10, .0265 \ 11, 0.0  \ 12,0.00)   

recreational_trips_months = (1,0 \ 2, 0 \ 3, 0 \ 4, 275825  \ 5, 76600 \ 6, 41500 \ 7, 60500 \ 8, 80800 \ 9 , 115900 \10, 18000 \ 11, 0  \ 12, 0) 
st_numscalar("my_num_trips", colsum(recreational_trips_months)[2])  


recreational_effort_waves = J(10,1,recreational_effort_waves)
recreational_effort_monthly = J(10,1,recreational_effort_months) 
recreational_trips_months = J(10,1,recreational_trips_months) 

end

global tot_trips =scalar(my_num_trips)
global numtrips=$tot_trips/$scale_factor

/* END of Global macros */
/**************************************************************/
/**************************************************************/

/* Begin the section of temporary macro adjustment */
/* Use this section to temporarily set macros to smaller values.  
This is useful for troubleshooting and debugging  */


/* Once we go to production, this entire section should be empty*/
/* END:section of temporary macro adjustment */

/*************************************************************/





/* EVERYTHING BEFORE THIS POINT IS SETUP */

/* these parameters are set in "economic_parameters". I'm overwriting them now */
global hadd_relax_main=2
global hadd_relax_mjj=$hadd_relax_main

global haddock_sublegal_low=0.001 
global haddock_sublegal_hi=0.30


/* Cod sub-legals after wave 2 */

global cod_relax_main=2
global cod_sublegal_low=.005
global cod_sublegal_hi=.090+$cod_sublegal_low

/* read in regulations and run the model.*/
qui foreach scenario of local scenario_list{
	global ws=`scenario'
	do "${code_dir}/sim/read_in_regs.do"





/* THIS IS WHERE THE MODEL BEGINS */
/* Eventually, set up loops over initial conditions (BSN replicates, minimum sizes, and bag limits. */

timer on 90
nois _dots 0, title(Loop running: scenario $ws) reps($total_reps)

/*reset the seed for each scenario*/
set seed 2485768


qui forvalues replicate=1/$total_reps{	
	nois _dots `replicate' 0     
/* MODEL SETUP -- CONSTRUCT THE SMOOOTHED AGE-LENGTH KEYS*/
/*The File cod_al_lowess.do:
1.  reads in the Cod age-length key and cleans the age-length key
2.   smooths the data
3.  Computes the age--> length probability matrix */

 do "${code_dir}/sim/cod_al_lowess.do"

/*The File hadd_al_lowess.do:
1.  reads in the haddock age-length key and cleans the age-length key
2.   smooths the data
3.  Computes the age--> length probability matrix*/
 do  "${code_dir}/sim/haddock_al_lowess.do"




/*  
Compute historical recreational selectivity and send to mata
1.  read in the historical (2008-2010) age structures
2.  Convert to lengths, using the age-length key
3.  Aggregate into a single period.
3.  Merge with the recreational catch.
4.  Compute Catch/Available.
5.  Smooth and compute F_rec and smoothed, normalized F_rec.  
 */
 
 *do "historical_normalized_fishing_helper.do"
 do "${code_dir}/sim/monthly_historical_normalized_fishing_helper.do"

/*THIS IS THE ENCOUNTERS-PER-TRIP SECTION*/
*do "setup_encounters_per_trip.do"
 do "${code_dir}/sim/setup_monthly_encounters_per_trip.do"



/* verified to here */


/***************************** ******************************/
/***************************** ******************************/
/* SET UP INITIAL NUMBERS AT LENGTH for each of the two stocks*/

/*********************************/
/*
There are a few "options here"  PAY CLOSE ATTENTION.
These are used to set up the number of fish in the first year of fishing
*/
/****************************/





/* This section of code reads in an observation, performs the age--> length transformation and saves it to an auxilliary dta (haddock_length_count.dta)*/
/* OPTION 2a:  Draw from the 2013 AGEPRO output, but ensure that the initial conditions are constant across replicates*/

use "$hadd_naa_sort", clear
keep if year==$which_year
keep if id==`replicate'
scalar hreplicate=replicate[1]
notes: this contains the numbers at age of haddock for the current replicate
keep  age*
assert _n==1

/*  OPTION 3: Use the median numbers at age from the the AGEPRO output.  This is very useful to calibrate
use "$hadd_naa_start", clear
keep if year==$which_year
collapse (median) age1-age9
scalar hreplicate=1
*/

save "${working_data}/haddock_age_count.dta", replace




putmata haddock_initial_counts=(age*), replace


/***************************** ******************************/
/***************************** ******************************/
/*********************************/
/*
There are a few "options here"  PAY CLOSE ATTENTION.
*/
/****************************/


/* This section of code reads in an observation, "stacks" it, performs the age--> length transformation and saves it to an auxilliary dta (cod_length_count.dta)*/


/* OPTION 2a:  Draw from the 2013 AGEPRO output, but ensure that the initial conditions are constant across replicates*/

use "$cod_naa_sort", clear
keep if year==$which_year
keep if id==`replicate'
scalar creplicate=replicate[1]
assert _n==1
notes: this contains the numbers at age of cod for the current replicate
keep age*

/*  OPTION 3: Use the median numbers at age from the AGEPRO output

use "$cod_naa_start", clear
keep if year==$which_year
collapse (median) age1-age9
scalar creplicate=[1]
keep  age*
*/

save "${working_data}/cod_age_count.dta", replace
 

/* pass the age structure to mata */

putmata cod_initial_counts=(age*), replace
clear


qui forvalues this_month=1/`max_months'{

/*Send/Extract the commercial fishing and recreational effort to scalars
The mata: .... end command doesn't play nicely with a forvalues loop.

Either write each mata commmand individually, or construct a mata function.  
See http://www.stata.com/statalist/archive/2012-07/msg00961.html and 
<http://www.stata.com/statalist/archive/2011-01/msg00393.html>

I've written each mata command individually
*/

	/* what is the fishing year?  */
	global fishing_year=ceil((`this_month'-2)/$periods_per_year)
	/* what is the calendar year */
	global cal_year=ceil(`this_month'/$periods_per_year)

	/* what is the "wave" of the calendar year (1-12, corresponding to MRIP wave)*/

	global current_wave=`this_month'
	global wave_of_cy=`this_month'-($cal_year-1)*$periods_per_year


	mata:  st_numscalar("hm1",mandelman_mortality_large[$wave_of_cy])
	mata:  st_numscalar("hm2",mandelman_mortality_small[$wave_of_cy])

	global hmrelease_large=scalar(hm1)
	global hmrelease_small=scalar(hm2)

	global haddock_mortality_release=scalar(hm1)

	disp "checkpoint5"

	mata:	st_numscalar("haddock_quota",haddock_commercial_catch_monthly[`this_month'])
	mata:	st_numscalar("cod_quota",cod_commercial_catch_monthly[`this_month'])
	*mata:   st_numscalar("rec_effort_fraction",recreational_effort_monthly[`this_month',2])
	mata:   st_numscalar("rec_effort_trips",recreational_trips_months[`this_month',2])

/* Get the correct recreational fishing regulations a little ugly because I'm getting
scalars from mata and then sending them to globals. */

	mata:  st_numscalar("codbags",cod_bag_vec[`this_month'])
	mata:  st_numscalar("codmins",cod_min_vec[`this_month'])
	mata: st_numscalar("codmaxs",cod_max_vec[`this_month'])

	mata: st_numscalar("cod_min_min",min(cod_min_vec))
        if scalar(cod_min_min>=90){
	scalar cod_min_min=min(cod_min_min,21)
}
	mata: st_numscalar("hadbags",haddock_bag_vec[`this_month'])
	mata: st_numscalar("hadmins",haddock_min_vec[`this_month'])
	mata: st_numscalar("hadmaxs",haddock_max_vec[`this_month'])

	mata: st_numscalar("hadd_min_min",min(haddock_min_vec))
      
	if scalar(hadd_min_min>=90){

        scalar hadd_min_min=min(hadd_min_min,17)
}
	global codbag =scalar(codbags)
	global cod_min_keep= scalar(codmins)
	global cod_max_keep= scalar(codmaxs)

	

	disp "checkpoint6"

	global haddockbag=scalar(hadbags)
	global hadd_min_keep= scalar(hadmins)
	global hadd_max_keep= scalar(hadmaxs)

	/* Generally, we'll let a few people keep some fish that is "just under" the possession limit.
	*/
        	global cod_relax=2 
		global hadd_relax=2 
	/* however, this way of doing things doesn't work when we have  zero possession (modeled with a very high minimum size , over 90") When we have a very high minimum size, we'll
	This way of coding things doesn't work if cod_min_min==cod_min_keep (aka cod is always closed).
	*/

		if $cod_min_keep>=90 {
		global cod_relax=$cod_min_keep-scalar(cod_min_min)-1
		}
		
		if $hadd_min_keep>=90 {
		global hadd_relax=$hadd_min_keep-scalar(hadd_min_min)-1
		}
		
	
	
   *global wave_numtrips=floor(scalar(rec_effort_fraction)*$numtrips)
	
	global wave_numtrips=floor(scalar(rec_effort_trips)/$scale_factor)

	
	/* nobody goes fishing if cod and haddock bag limits are zero */
	if $codbag==0 & $haddockbag==0{
		global wave_numtrips=0
	}
	else{
	}
	global current_replicate=`replicate'	
	/* I need to make a global out of the wave in order to pass it to the (Commercial fishing mortality and Rec fishing mortality) do files which are subsequently called */
	/* Compute partial F */
	disp "checkpoint11"


/* This section applies the commercial (sub)-ACL to the fishery using the ``fishing mortality method.'' */
/* Compute mid-wave stock structure*/

	do "$code_dir/sim/haddock_mortality_helper.do"
	do "$code_dir/sim/cod_mortality_helper.do"
		
		/* If there are no recreational trips, then skip the recreational simulation, the "new_bio_out_v4" and go directly to the end of year cleanup.  
			rec_dead gets set to zero
			Might need to set other parameters and outputs to zero as well.
			Rec WTP and Rec Trips also set to zero
			*/
		if $wave_numtrips==0{
	
			scalar tripcount=0
			scalar total_WTP=0

			scalar total_UA=0
			scalar total_UE=0
			scalar ckept=0
			scalar creleased=0
			scalar hkept=0
			scalar hreleased=0
			scalar lbs_cod_kept=0
			scalar lbs_cod_released=0
			scalar lbs_hadd_kept=0
			scalar lbs_hadd_released=0 
			scalar lbs_cod_released_dead=0 
			scalar lbs_hadd_releas_dead=0


			mata: rec_dead_cod=J(1, length(cod_age_selectivity),0)
			mata: rec_dead_haddock=J(1, length(haddock_age_selectivity),0)

		}
		disp "checkpoint12"

	/* If there are recreational trips, then we set up the recreational part of the simulation */
		
		else{

/* We compute "mid-wave" stock numbers, minus natural and commercial fishing mortality */
/* this section takes the age structure contained in Matrix haddock_feb1_counts and cod_feb1_counts and converts it into numbers at length*/
/* Convert haddock Feb stock structure to haddock Feb size structure 
	Could speed this up by doing it entirely in mata, but I'm not sure how much faster that will go.  Probably not really worth the programming time.  It's approx 0.04 per wave, or 0.25 per year
*/

timer on 89
clear
getmata age*=haddock_end_of_period, replace
xpose, clear varname
rename v1 pre_rec_count
gen age=substr(_varname, -1,.)
drop _varname
destring, replace
order age pre_rec_count
sort age


merge m:1 age using "${working_data}/haddock_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*pre_rec_count
}
collapse (sum)length*
gen myi=1
reshape long length, i(myi) j(myj)
rename length count
rename myj length


drop myi
notes drop _all
notes: this contains the numbers at lengths of haddock for the current replicate
timer off 89

save "${working_data}/haddock_length_count.dta", replace



/* Convert cod end-of-commercial-and-natural mortality age structure to size structure */
clear
getmata age*=cod_end_of_cm, replace

xpose, clear varname
rename v1 pre_rec_count
gen age=substr(_varname, -1,.)
destring, replace
drop _varname
order age pre_rec_count
sort age

merge 1:m age using "${working_data}/cod_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*pre_rec_count
}
collapse (sum)length*
gen myi=1
reshape long length, i(myi) j(myj)
rename length count
rename myj length
label var length "length of cod in inches"
drop myi
notes drop _all
notes: this contains the numbers at lengths of cod for the current replicate
save "${working_data}/cod_length_count.dta", replace

/* Recreational Fishing occurs in Feb */
	do "$code_dir/sim/simulation_v42a.do"

quietly do "$code_dir/sim/aux_wtp2.do"
/* post the fishing statistics for wave 1
quietly count if trip_occur==1
scalar tripcount=r(N)
quietly summ WTP if trip_occur==1
scalar total_WTP=r(sum)
 */
 
preserve
gen cod_catch=ckeep+crel
keep prob cod_catch
collapse (sum) prob, by(cod_catch)
	tempfile csave
	local csaver `"`csaver'"`csave'" "'  
	gen scenario_num=$scenario_num
        gen replicate=`replicate'
        gen month=`this_month'

	quietly save `csave'
restore

preserve
keep prob ckeep
collapse (sum) prob, by(ckeep)
	tempfile cland
	local clander `"`clander'"`cland'" "'  
	gen scenario_num=$scenario_num
        gen replicate=`replicate'
        gen month=`this_month'

	quietly save `cland'
restore

preserve
gen haddock_catch=hkeep+hrel
keep prob haddock_catch
collapse (sum) prob, by(haddock_catch)
	tempfile hsave
	local hsaver `"`hsaver'"`hsave'" "'  
	gen scenario_num=$scenario_num
        gen replicate=`replicate'
	gen month=`this_month'

	quietly save `hsave'
restore

preserve
keep prob hkeep
collapse (sum) prob, by(hkeep)
	tempfile hland
	local hlander `"`hlander'"`hland'" "'  
	gen scenario_num=$scenario_num
        gen replicate=`replicate'
        gen month=`this_month'

	quietly save `hland'
restore


/* post the fishing statistics for wave 1 -- add up "prob" and "probability weighted WTP". Scale by the scale_factor*/

tempvar tt wt wtp
egen `tt'=total(prob)
scalar tripcount=floor(`tt'[1])

gen `wt'=prob*WTP
egen `wtp'=total(`wt')

scalar total_WTP=floor(`wtp'[1])
 

tempvar UA UE

egen `UA'=total(utilActual)

scalar total_UA=floor(`UA'[1])

egen `UE'=total(utilExpected)

scalar total_UE=floor(`UE'[1])
 
/* BUILD THE ROLLING LENGTH--> AGE KEYS FOR COD AND HADDOCK */
do "$code_dir/sim/rolling_age_length_key.do"

/* The Bio-out helper file constructes the age structure of Kept and released fish and saves it to the species_ages_out.dta file.*/
do "$code_dir/sim/new_bio_out_v4.do"


/*New bio out leaves behind datsets of length and ages for each species. It will be useful to append these together and save them. */
 preserve
use "$working_data/haddock_length_out", clear
gen month=`this_month'
gen replicate=`replicate'
gen scenario_num=$scenario_num
append using `hla'
save `hla', replace

use "$working_data/cod_length_out", clear
gen month=`this_month'
gen replicate=`replicate'
gen scenario_num=$scenario_num
append using `cla'
save `cla', replace


restore
/* Post the kept and released fish for each (and weights) from mata
(scalar(ckept)) (scalar(creleased)) (scalar(hkept)) (scalar(hreleased)) (scalar(lbs_cod_kept)) (scalar(lbs_cod_released)) (scalar(lbs_hadd_kept)) (scalar(lbs_hadd_released)) 
*/
mata: st_numscalar("ckept", ackeep)
mata: st_numscalar("creleased", acrel)
mata: st_numscalar("hkept", ahkeep)
mata: st_numscalar("hreleased", ahrel)

mata: st_numscalar("lbs_cod_kept", aggregate_cod_kept_pounds)
mata: st_numscalar("lbs_cod_released", aggregate_cod_released_pounds)
mata: st_numscalar("lbs_cod_released_dead", cod_released_dead_pounds)

mata: st_numscalar("lbs_hadd_kept", aggregate_haddock_kept_pounds)
mata: st_numscalar("lbs_hadd_released", aggregate_haddock_rel_pounds)

mata: st_numscalar("lbs_hadd_releas_dead", haddock_rel_dead_pounds)

/* Compute dead by multiply the discards by discard mortality and the using collapse (sum) */
use  "${working_data}/cod_ages_out.dta", clear
keep if status==1 | status==3
collapse (sum) age*
/* send off to mata */
putmata rec_dead_cod=(age1-age9), replace

use  "${working_data}/haddock_ages_out.dta", clear
keep if status==1 | status==3
collapse (sum) age*
putmata rec_dead_haddock=(age1-age9), replace


/* This is the end of the else statement*/
	}
	

/* Compute end of period counts and store them in a vector.  These are equivalent to the initial counts for the beginning of the next period (except for wave 6)*/
	do "$code_dir/sim/haddock_end_of_wave_helper.do"
	do "$code_dir/sim/cod_end_of_wave_helper.do"

		
	/* check that it's the end of the year (wave 6) */
	/* IF it is, then begin population dynamics. */
	/* HERE BEGINS POPULATION DYNAMICS 
		At the end of the year, cod and haddock transition to the next age class
		Age 1's are created by drawing Recruits
		We also check the "Hinge" if necessary.	
		the "end_of_wave_counts" are overwritten*/
		
	if $wave_of_cy==$periods_per_year{
	/* Compute cod SSB, first in individuals, then in lbs (in lbs)
	first compute the cssb_lookup, hssb_lookup globals.  This tells my code which "end_of_wave" to examine when computing SSB.	*/
	global cssb_lookup_floor=($cal_year-1)*$periods_per_year+$cssb_floor
	global cssb_lookup_ceil=($cal_year-1)*$periods_per_year+$cssb_ceil
	global hssb_lookup_floor=($cal_year-1)*$periods_per_year+$hssb_floor
	global hssb_lookup_ceil=($cal_year-1)*$periods_per_year+$hssb_ceil


	mata: haddock_ssb=haddock_maturity:*(haddock_end_of_wave_counts$hssb_lookup_floor + haddock_end_of_wave_counts$hssb_lookup_ceil)/2
	mata: haddock_ssb=$kilo_to_lbs*haddock_ssb*haddock_ssb_weights'
	
	mata: cod_ssb=cod_maturity:*(cod_end_of_wave_counts$cssb_lookup_floor + cod_end_of_wave_counts$cssb_lookup_ceil)/2
	mata: cod_ssb=$kilo_to_lbs*cod_ssb*cod_ssb_weights'
	
	/* check the hinge */
	mata: st_numscalar("cod_hinge_check", cod_ssb/ $cod_SSBHinge)

/*	mata: st_numscalar("haddock_hinge_check", haddock_ssb/ $haddock_SSBHinge) */

	/*Age up the HADDOCK*/
		clear
		getmata (age*)=haddock_end_of_wave_counts$current_wave
		replace age9=age9+age8
		forvalues ac=8(-1)2{
			local tc=`ac'-1
			replace age`ac'=age`tc'
		}
		replace age1=.
	/*Haddock Recruitment */

	/* THIS IS MODEL 14 -- Smoothed EMPIRICAL CDF of Recruitment
	The code is quite ugly, but it seems to work*/
	tempvar recruit_raw index_lb index_ub recruit_lb recruit_ub
	gen double `recruit_raw'=runiform()
	gen `index_lb'=irecode(`recruit_raw',$hglobrecruit_cdf)
	gen `index_ub'=`index_lb'+1

	gen `recruit_lb'=hrecruit_cdf[`index_lb',1]
	gen `recruit_ub'=hrecruit_cdf[`index_ub',1]

	replace age1=z1*(`recruit_ub'-`recruit_lb')*(`recruit_raw'-( (`index_lb'-1)/z1 ) ) + `recruit_lb'
	/* END MODEL 14 -- Smoothed EMPIRICAL CDF of Recruitment*/
	/* Put these back into mata   */
	putmata haddock_end_of_wave_counts$current_wave=(age1-age9), replace

	/*Age up the COD*/
	clear
	getmata (age*)=cod_end_of_wave_counts$current_wave
	replace age9=age9+age8
	forvalues ac=8(-1)2{
		local tc=`ac'-1
		replace age`ac'=age`tc'
	}
	replace age1=.
	/* Recruitment */
		/* Calculate Age-0 Cod in Year 1 */
		/* Model 14 is draws of recruitment from empirical cdf */
		/* Model 21 scales recruitment drawn in Model 14 by the factor of SSB/SSBHinge if the value is less than the Hinge value */

		tempvar recruit_raw index_lb index_ub recruit_lb recruit_ub
		gen double `recruit_raw'=runiform()
		gen `index_lb'=irecode(`recruit_raw',$cglobrecruit_cdf)
		gen `index_ub'=`index_lb'+1

		gen `recruit_lb'=crecruit_cdf[`index_lb',1]
		gen `recruit_ub'=crecruit_cdf[`index_ub',1]

		replace age1=c1*(`recruit_ub'-`recruit_lb')*(`recruit_raw'-( (`index_lb'-1)/c1 ) ) + `recruit_lb'

		/* This fragment starts model 21 */
		if scalar(cod_hinge_check)<=1{
			replace age1=age1*scalar(cod_hinge_check)
		}
		/* This fragment ends model 21 */
	/* Put these back into mata   */
	putmata cod_end_of_wave_counts$current_wave=(age1-age9), replace
	

	/* HERE ENDS POPULATION DYNAMICS of age transitions and recruitment */
	}
	
	disp "checkpoint1"
	mata: cod_initial_counts=cod_end_of_wave_counts$current_wave  /*TAG2*/
	mata: haddock_initial_counts=haddock_end_of_wave_counts$current_wave


	scalar cod_kept_mt=lbs_cod_kept/($mt_to_kilo*$kilo_to_lbs)
	scalar cod_released_mt=lbs_cod_released/($mt_to_kilo*$kilo_to_lbs)
	scalar cod_released_dead_mt=lbs_cod_released_dead/($mt_to_kilo*$kilo_to_lbs)

	scalar hadd_kept_mt=lbs_hadd_kept/($mt_to_kilo*$kilo_to_lbs)
	scalar hadd_released_mt=lbs_hadd_released/($mt_to_kilo*$kilo_to_lbs)
	scalar hadd_released_dead_mt=lbs_hadd_releas_dead/($mt_to_kilo*$kilo_to_lbs)


/* FIX THIS LATER: What do I need to save? */
post `economic'  ("$scenario_name") ($scenario_num) (`this_month')  ($wave_numtrips*$scale_factor)  (scalar(tripcount)) (scalar(total_WTP)) (scalar(total_UA)) (scalar(total_UE))  (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep) ($pcbag_comply)  ($cod_sublegal_hi)  ($mortality_release) ($haddock_mortality_release)
post `rec_catch' ("$scenario_name") ($scenario_num) (`this_month')  ($wave_numtrips*$scale_factor)  (scalar(tripcount)) (scalar(ckept)) (scalar(creleased)) (scalar(hkept)) (scalar(hreleased))  (scalar(cod_kept_mt)) (scalar(cod_released_mt)) (scalar(cod_released_dead_mt)) (scalar(hadd_kept_mt)) (scalar(hadd_released_mt)) (scalar(hadd_released_dead_mt))     (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep) (scalar(creplicate)) (scalar(hreplicate)) ($pcbag_comply)  ($cod_sublegal_hi)  ($mortality_release) ($haddock_mortality_release)
	disp "checkpoint2"
*  haddock_discard_dead_weight cod_discarded_dead_weight

/* These posts are not doing exactly I want them to do yet.
haddock_discard_dead_num
cod_discard_dead_num
*/


/* Post the end of wave counts */
clear
getmata (age*)=cod_end_of_wave_counts$current_wave
post `species1' ("$scenario_name")  ($scenario_num) (`this_month') (scalar(cod_commercial_landings)) (scalar(cod_commercial_discards)) (age1[1]) (age2[1]) (age3[1]) (age4[1]) (age5[1]) (age6[1]) (age7[1]) (age8[1]) (age9[1]) (`replicate')  ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep)  ($mortality_release) ($haddock_mortality_release)
clear
getmata (age*)=haddock_end_of_wave_counts$current_wave
	disp "checkpoint3"

post `species2' ("$scenario_name") ($scenario_num) (`this_month') (scalar(haddock_commercial_landings)) (scalar(haddock_commercial_discards))  (age1[1]) (age2[1]) (age3[1]) (age4[1]) (age5[1]) (age6[1]) (age7[1]) (age8[1]) (age9[1]) (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep)  ($mortality_release) ($haddock_mortality_release)
	disp "checkpoint4. Finished loop `this_month'"  

/*THIS IS the end of code checking */ 
/* This is the end of the "wave loop*/
		}

}
}
dsconcat `hsaver'
rename prob trips
save `haddock_catch_class', replace

clear
dsconcat `csaver'
rename prob trips
save `cod_catch_class', replace

dsconcat `hlander'
rename prob trips
save `haddock_land_class', replace

clear
dsconcat `clander'
rename prob trips
save `cod_land_class', replace



timer off 90
timer off 99
postclose `rec_catch'
postclose `species1'
postclose `species2'
/*
postclose `species1b'
postclose `species2b'
*/
postclose `economic'

/* Set the output datasets to R/Wonly 
shell chmod 660 `rec_out'
shell chmod 660 `sp1_out'
shell chmod 660 `sp2_out'
shell chmod 660 `econ_out'

*/

/* Set the output datasets to read only


shell chmod 440 `rec_out'
shell chmod 440 `sp1_out'
shell chmod 440 `sp2_out'
shell chmod 440 `econ_out'
 */

di "Some Text to Display"
/* This is a good place to dyndoc something. Maybe */
* dyndoc "${code_dir}/postsim/calibration_summaries.txt", saving(${project_dir}/calibration_summaries.html) replace
timer list
log close

