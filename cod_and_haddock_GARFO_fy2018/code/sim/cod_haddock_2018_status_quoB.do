/**************************************************************/
/*************************************************************/
/*************************************************************/

/*
This .do file was written by Min-Yang.Lee@noaa.gov 
Version 2.2017
December 21, 2017

TABLE OF CONTENTS
0.  File description, Meta Data, changegoals, and changelog
1.  Global, scalar, and other setup (parameterization)
2.  Reading in?
3.  Population Dynamics -- including call to economic model
4.  Loop?
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

Changelog:
		C1.  Computation of fishing selectivity [DONE< BUT NEED TO TEST]
		C1a.  MRIP catch-at-length (A+B1+B2) for 2010-2012
		C1b.  NAA for 2009-2011
		C1c.  Age-Length key for 2009-2011 (DONE)
	C2.  Computation of Numbers-per-trip for 2009-2011.  (Scott has extracted this, but I have not incorporated).  
		C2a.  "by wave" or for all years?

	
	1.5.1: Trips and WTP are computed "probablistically" (See: scalar tripcount, "new_bio_out_v4.do")
	1.5.2: SSB computation fixed (only impacts previous multi-year model runs).  End_of_wave_counts for each species are now being saved to a mata for all waves. 
			Currently not being posted into a dataset, but this shouldn't be too hard.
	
	1.2.1: life history parameters updates from the 2013 agepro runs and starting values.  I HAVE NOT UPDATES THE COD RECRUITMENT  -- this depends on which stock assessment is preferred.
	1.2.3: automated extraction of survey data for age-length key.
	1.2.4: extraction of commerical fishery harvest incorporated.
	1.2.5: Soft code the distribution of recreational effort.
	1.2.6: minor adjustments to lenght-weight equation.
	1.2.7: Iterate over waves -- compute SSB,recruitment, and perform age transition in last wave of calendar year (any wave divisible by 6).
	1.2.8: Incorporate 'variable' regulatory controls for wave 1-2 and 3-8.
	1.2.9: Data update: new age-length key for both species.  new NAA for both species (for both initialization and computation of selectivity).
	1.2.10: incorporated recreational catch-at-length at the wave level.  
	1.2.11: re-wrote the historical selectivity helper files (process_cod, process_haddock, process_cod_selectivity, process_haddock_selectivity are deprecated)
	1.2.12: cod and haddock line-drops are now called encounters.  These are smoothed and dumped to mata. using helper file.
	____
	1.1.7:  Mata for F has been moved into a pair of helper files.  This is because looping over mata: -- end doesn't work, the end closes the looop.
	1.1.6:  a few locals have been changed to globals.
	1.1.5:  Solution method for F under quota based fishing has been written using the Secant method in Mata instead of newtons method in stata.
	1.1.4:  Population Dynamics has been converted from stata's matrices and data to Mata. I'm not sure this is noticably faster, but it is much more elegant..
	1.1.3:  Data has been updated.
	1.1.2:  Results stored in postfiles
	
	1.1.1:  Adjust the Fh iteration segment to a `while' loop.  Marked infeasible quotas and non-convergence.
	1.0.0:  Copy and paste job from the haddock caa model 
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
macro drop _all
scalar drop _all
matrix drop _all
pause off
global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2019"

global project_dir "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_and_haddock_GARFO_fy2018"
global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"


cd $project_dir
local poststub "2018_status_quoB"

log using "${output_dir}/cod_and_haddock_`poststub'.smcl", replace

version 12

set more off
set seed 8675309
timer clear
timer on 99
pause off

/* specify names of save files */
local econ_out "${output_dir}/economic_data`poststub'.dta"
local rec_out  "${output_dir}/recreational_catches`poststub'.dta"
local sp1_out  "${output_dir}/cod_end_of_wave`poststub'.dta"
local sp2_out  "${output_dir}/haddock_end_of_wave`poststub'.dta"
local cod_catch_class  "${output_dir}/cod_catch_class_dist`poststub'.dta"
local haddock_catch_class  "${output_dir}/haddock_catch_class`poststub'.dta"

local cod_land_class  "${output_dir}/cod_land_class_dist`poststub'.dta"
local haddock_land_class  "${output_dir}/haddock_land_class`poststub'.dta"


local hla  "${output_dir}/haddock_length_class`poststub'.dta"
local cla  "${output_dir}/cod_length_class`poststub'.dta"

/* setup storage for length structures of simulated kept and released */
preserve
clear
set obs 1
gen dum=0
save `hla', replace
save `cla', replace
restore

global cod_upper_bound 55
global haddock_upper_bound 55
global cmax_age 9
global hmax_age 9

/* waves=number of periods per year. These are bi-monthly, corresponding to MRIP/MRFSS */

global months=12
global periods_per_year=$months
global total_reps=100
global total_reps=3

global total_years_sim=1


local max_months=($months*$total_years_sim) + 4

global year_junk=2011 /* don't change this.  You are using this to store the older commercial catch and rec regulations */ 
global rec_junk=2015

/* To calibrate the model to 2017 

I need to have 150799 trips*/
global tot_trips 233000
global scale_factor 10
global numtrips=$tot_trips/$scale_factor

global which_year=2018

/*WHAT YEAR DO YOU WANT TO CALIBRATE?*/
/*NOTE, I need to set the calibration year to 2015.  Before I can do that, I need to get the 2015 age structures from AGEPRO. These are actually the BSNs corresponding to the projection models.*/
*global calibration_end 2016

global calibration_end 2017
global this_year=year(date("$S_DATE","DMY"))
global this_year=2017



global comm_month_starter=$periods_per_year*($which_year-$year_junk)+1
global rec_month_starter=$periods_per_year*($which_year-$rec_junk)+1
/* Age-length key years*/
 global lcalibration_start 2014
 global lcalibration_end 2016

 /*historical effort calibration params  -- currently set up for the 2013 calendar year */
 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial is helper is set up to extract the 2016 FISHING YEAR */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$calibration_end

 
/* Here are some parameters */
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787

/* read in biological data, economic data, and backround data on catch from the commercial fishery*/
do "${code_dir}/presim/cod_hadd_bio_params.do"
do "${code_dir}/presim/economic_parameters.do"
do "${code_dir}/presim/commercial_quotas.do"

/* These globals contain the locations of the cod age-length key raw data */
global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

global hadd_naa_sort "$working_data/haddock_beginning_sorted2017.dta"
global cod_naa_sort "$working_data/cod_beginning_sorted2017.dta"




disp "Are you calibrating or running the model?  Be sure that the Initial stock conditions are properly set at bookmarks 1 and 2."
pause

/* set up the name of the postfiles.  These names are use by the postfile command*/
tempname species1 species2 species1b species2b economic rec_catch

postfile `economic' str20(scenario) month total_trips WTP CV_A CV_E replicate cbag hbag cmin hmin cmax hmax codbag_comply cod_sublegal_keep cod_release_mort hadd_release_mort using `econ_out', replace
postfile `rec_catch' str20(scenario)  month total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_kept_mt cod_released_mt cod_released_dead_mt hadd_kept_mt hadd_released_mt hadd_released_dead_mt replicate  cbag hbag cmin hmin cmax hmax crep hrep codbag_comply cod_sublegal_keep cod_release_mort hadd_release_mort using `rec_out', replace

postfile `species1' str20(scenario)  month commercial_catch commercial_discards age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate  cbag hbag cmin hmin cmax hmax cod_release_mort hadd_release_mort using `sp1_out', replace
postfile `species2' str20(scenario)  month commercial_catch commercial_discards age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate  cbag hbag cmin hmin cmax hmax cod_release_mort hadd_release_mort using `sp2_out', replace

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
/*Adjust for MA fishing regs in 2017. */
global cod_relax_mjj=75
mata: cod_bag_vec[5]=1
mata: cod_bag_vec[6]=1
mata: cod_bag_vec[17]=1
mata: cod_bag_vec[18]=1

global cod_sublegal_low=.02
global cod_sublegal_hi=.13+$cod_sublegal_low
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




/* THIS IS WHERE THE MODEL BEGINS */
/* Eventually, set up loops over initial conditions (BSN replicates, minimum sizes, and bag limits. */

/* setup the historical recreational regulations */


local scenario_num `""0B""'

timer on 90
nois _dots 0, title(Loop running) reps($total_reps)

quietly forvalues replicate=1/$total_reps{	
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
/* OPTION 2a:  Draw from the 2013 AGEPRO output, but ensure that the initial conditions are constant across replicates
*/

use "$hadd_naa_sort", clear
keep if year==$which_year
keep if id==`replicate'
scalar hreplicate=replicate[1]
notes: this contains the numbers at age of haddock for the current replicate
keep  age*

/*  OPTION 3: Use the median numbers at age from the the AGEPRO output.  This is very useful to calibrate
use $hadd_naa_start, clear
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



forvalues this_month=1/`max_months'{
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
	mata:   st_numscalar("rec_effort_fraction",recreational_effort_monthly[`this_month',2])

/* Get the correct recreational fishing regulations a little ugly because I'm getting
scalars from mata and then sending them to globals. */

	mata:  st_numscalar("codbags",cod_bag_vec[`this_month'])
	mata:  st_numscalar("codmins",cod_min_vec[`this_month'])
	mata: st_numscalar("codmaxs",cod_max_vec[`this_month'])


	mata: st_numscalar("hadbags",haddock_bag_vec[`this_month'])
	mata: st_numscalar("hadmins",haddock_min_vec[`this_month'])
	mata: st_numscalar("hadmaxs",haddock_max_vec[`this_month'])

	global codbag =scalar(codbags)
	global cod_min_keep= scalar(codmins)
	global cod_max_keep= scalar(codmaxs)

	disp "checkpoint6"

	global haddockbag=scalar(hadbags)
	global hadd_min_keep= scalar(hadmins)
	global hadd_max_keep= scalar(hadmaxs)

	/* YOU need to fix the timing of this stuff here */
	

	if `this_month'>=5 & `this_month'<=6{
		/*This sets no non-compliance in the first 2 waves 
		global cod_relax=0
		global hadd_relax=0
*/	
		/*This allows "non-compliance" in the first 2 waves */
		global cod_relax=$cod_relax_mjj
		global hadd_relax=$hadd_relax_mjj

		
	}	
	else if `this_month'>=17 & `this_month'<=18{
		/*This sets no non-compliance in this time period and is a little different than the calibrator and status_quo models
		global cod_relax=0
		global hadd_relax=0
*/	
		/*This allows non-compliance in this time period */
		global cod_relax=$cod_relax_mjj
		global hadd_relax=$hadd_relax_mjj

		
	}	

	else{
		global cod_relax=$cod_relax_main
		global hadd_relax=$hadd_relax_main
	
	}
	
	global wave_numtrips=floor(scalar(rec_effort_fraction)*$numtrips)
	
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

do "${code_dir}/sim/simulation_v41a.do"
*quietly do "aux_wtp.do"

do "${code_dir}/sim/aux_wtp2.do"
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
	gen str20 scenario="`scenario_num'"
        gen replicate=`replicate'
        gen month=`this_month'

	quietly save `csave'
restore

preserve
keep prob ckeep
collapse (sum) prob, by(ckeep)
	tempfile cland
	local clander `"`clander'"`cland'" "'  
	gen str20 scenario="`scenario_num'"
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
	gen str20 scenario="`scenario_num'"
        gen replicate=`replicate'
	gen month=`this_month'

	quietly save `hsave'
restore

preserve
keep prob hkeep
collapse (sum) prob, by(hkeep)
	tempfile hland
	local hlander `"`hlander'"`hland'" "'  
	gen str20 scenario="`scenario_num'"
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
use "${working_data}/haddock_length_out", clear
gen month=`this_month'
gen replicate=`replicate'
gen str20 scenario="`scenario_num'"
append using `hla'
save `hla', replace

use "${working_data}/cod_length_out", clear
gen month=`this_month'
gen replicate=`replicate'
gen str20 scenario="`scenario_num'"
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
keep if status==2 | status==3
collapse (sum) age*
/* send off to mata */
putmata rec_dead_cod=(age1-age9), replace

use  "${working_data}/haddock_ages_out.dta", clear
keep if status==2 | status==3
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
post `economic' (`scenario_num') (`this_month') (scalar(tripcount)) (scalar(total_WTP)) (scalar(total_UA)) (scalar(total_UE))  (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep) ($pcbag_comply)  ($cod_sublegal_hi)  ($mortality_release) ($haddock_mortality_release)
post `rec_catch' (`scenario_num') (`this_month') (scalar(tripcount)) (scalar(ckept)) (scalar(creleased)) (scalar(hkept)) (scalar(hreleased))  (scalar(cod_kept_mt)) (scalar(cod_released_mt)) (scalar(cod_released_dead_mt)) (scalar(hadd_kept_mt)) (scalar(hadd_released_mt)) (scalar(hadd_released_dead_mt))     (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep) (scalar(creplicate)) (scalar(hreplicate)) ($pcbag_comply)  ($cod_sublegal_hi)  ($mortality_release) ($haddock_mortality_release)
	disp "checkpoint2"
*  haddock_discard_dead_weight cod_discarded_dead_weight

/* These posts are not doing exactly I want them to do yet.
haddock_discard_dead_num
cod_discard_dead_num
*/


/* Post the end of wave counts */
clear
getmata (age*)=cod_end_of_wave_counts$current_wave
post `species1'  (`scenario_num') (`this_month') (scalar(cod_commercial_landings)) (scalar(cod_commercial_discards)) (age1[1]) (age2[1]) (age3[1]) (age4[1]) (age5[1]) (age6[1]) (age7[1]) (age8[1]) (age9[1]) (`replicate')  ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep)  ($mortality_release) ($haddock_mortality_release)
clear
getmata (age*)=haddock_end_of_wave_counts$current_wave
	disp "checkpoint3"

post `species2'  (`scenario_num') (`this_month') (scalar(haddock_commercial_landings)) (scalar(haddock_commercial_discards))  (age1[1]) (age2[1]) (age3[1]) (age4[1]) (age5[1]) (age6[1]) (age7[1]) (age8[1]) (age9[1]) (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep)  ($mortality_release) ($haddock_mortality_release)
	disp "checkpoint4. Finished loop `this_month'"  

/*THIS IS the end of code checking */ 
/* This is the end of the "wave loop*/
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

timer list
log close
