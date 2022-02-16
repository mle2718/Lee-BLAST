/**************************************************************/
/*************************************************************/
/*************************************************************/

/*
This .do file was written by Min-Yang.Lee@noaa.gov 
Version 2.6
October 8, 2015

TABLE OF CONTENTS
0.  File description, Meta Data, changegoals, and changelog
1.  Global, scalar, and other setup (parameterization)
2.  Reading in?
3.  Population Dynamics -- including call to economic model
4.  Loop?
*/

/* BEGIN Section 0: FILE DESCRIPTION */

/* This is a wrapper for my simulation. 
0.  I set up a bunch of parameters in the begining. 
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

/*Changegoals:
A. Cod model (which one).  Recruitment, which one? See the helper file in /recreational_simulations_agepro_utilities/process_xx1.do 
C. Data update:
	C1.  Computation of fishing selectivity [DONE< BUT NEED TO TEST]
		C1a.  MRIP catch-at-length (A+B1+B2) for 2010-2012
		C1b.  NAA for 2009-2011
		C1c.  Age-Length key for 2009-2011 (DONE)
	C2.  Computation of Numbers-per-trip for 2009-2011.  (Scott has extracted this, but I have not incorporated).  
		C2a.  "by wave" or for all years?
/*


Changelog:





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
1.  historical_normalized_fishing_helper.do : search for "hand edit the F for lngcat28 in wave 2"
2.  The minimum sizes of cod and haddock must be user specified
3.  The number of age classes for cod and haddock must be known in advance [not a big problem, this is always known from the agepro files]
4.  The age-length key for GOM cod is really sparse.
*/



/**********************END SECTION 0: FILE DESCRIPTION******************/
/*************************************************************/
*************************************************************/

/* Preamble */
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017"
log using "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_and_haddock_mediansims.smcl", replace
version 12
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all
set more off
set seed 8675
timer clear
timer on 99
pause off

/* specify names of save files */
local econ_out "economic_data2015_actual_mediansims.dta"
local rec_out "recreational_catches2015_actual_mediansims.dta"
local sp1_out "cod_end_of_wave2015_actual_mediansims.dta"
local sp2_out "haddock_end_of_wave2015_actual_mediansims.dta"

/*
shell chmod 660 `rec_out'
shell chmod 660 `sp1_out'
shell chmod 660 `sp2_out'
shell chmod 660 `econ_out'
*/

global cod_upper_bound 40
global haddock_upper_bound 35
global cmax_age 9
global hmax_age 9

/* waves=number of periods per year. These are bi-monthly, corresponding to MRIP/MRFSS */

global waves=6
global total_reps=1
global total_years_sim=1
local max_waves=($waves*$total_years_sim) + 2



global year_junk=2011 /* don't change this.  You are using this to store the older commercial catch and rec regulations */ 


/* To calibrate the model to 2013 fishing i need 385000 trips  */

global numtrips 188000
global which_year=2015
global comm_wave_starter=6*($which_year-$year_junk)+1


global FMax 25
global maxfiter 30
global cod_comm_discard_mortality 1
global haddock_comm_discard_mortality 1


/*NOTE, I need to set the calibration year to 2015.  Before I can do that, I need to get the 2015 age structures from AGEPRO. These are actually the BSNs corresponding to the projection models.
global calibration_start 2011*/
global calibration_end 2013

global this_year=year(date("$S_DATE","DMY"))

 
/* Age-length key years*/
 global lcalibration_start 2012
 global lcalibration_end 2014


 /*historical effort calibration params  -- currently set up for the 2013 calendar year */
 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial is helper is set up to extract the 2014 FISHING YEAR

 */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$this_year

 
 /*ALL OF THESE NEED TO BE SET 
 
 these are set to the "old" years right now and will run. You'll need to use the proper wave
 20145-20154  (WAVE 5 of 2014 through WAVE 4 of 2015)
 */
 
 /*global for the cod and haddock catch-at-length distributions 
 global cod_historical_sizeclass cod_size_class_fy$calibration_end.dta  /* this is old */
 global haddock_historical_sizeclass haddock_size_class_fy$calibration_end.dta  /* this is old */
*/
 global cod_historical_sizeclass cod_size_class20145_20154.dta  /* this is old */
 global haddock_historical_sizeclass haddock_size_class20145_20154.dta  /* this is old */



 /*global for the cod and haddock age structures
  global cod_naa cod_naa_2015updatemramp.dta 

 */
 global cod_naa cod_naa_2015updatem2.dta 
 global hadd_naa haddock_naa_2015update.dta


 /*global for the cod and haddock initial NAA

YOU MIGHT NEED TO CHANGE THESE TO 
 global cod_naa_start 2015_COD_GM_MOD_ASAP_MRAMP_MCMC.dta
global cod_naa_start 2015_COD_GM_MOD_ASAP_M02_MCMC.dta

 global hadd_naa_start 2015_HAD_GM_MOD_ASAP_CONSTRAIN_TERMINAL_R_MCMC.dta
 */

global hadd_naa_start 2015_HAD_GM_MOD_ASAP_BASE_MCMC.dta
  global cod_naa_start 2015_COD_BOTH.dta


/*global for the cod and haddock catch-class distributions
global cod_catch_class cod_catch_class_fy$calibration_end.dta /* this is old */
global haddock_catch_class haddock_catch_class_fy$calibration_end.dta /* this is old */
*/


global cod_catch_class cod_catch_class20145_20154.dta /* this is new */
global haddock_catch_class haddock_catch_class20145_20154.dta /* this is new*/

/*END ALL OF THESE NEED TO BE SET */

 
 
/* Mortality rate of the released fish (UNIT FREE) */
global mortality_release=0.3
global haddock_mortality_release=0.50

/* Retention of sub-legal fish */
/* cod_relax: window below the minimum size that anglers might retain sublegal fish */
/* cod_sublegal_keep: probability that an angler will retain a sublegal cod in that size window*/


/* Retention of sub-legal fish */
/* This is coded in 2 parts -- We assume that fish that are "close" to the minimum size have a higher probability of being retained */
/* cod_relax: This defines "small" and "tiny" (along with the minimium size) */
/* cod_sublegal_keep: probability that an angler will retain a sublegal cod that is "small"*/
/* cod_sublegal_keep2: probability that an angler will retain a sublegal cod that is "tiny" */

/* Cod sub-legals in waves 1,2 */
global cod_relax0=0
/* Cod sub-legals after wave 2 */

global cod_relax_main=3
global cod_sublegal_keep=.015
global cod_sublegal_keep2=.015



/* hadd_relax: This defines "small" and "tiny" (along with the minimium size) */
/* haddock_sublegal_keep: probability that an angler will retain a sublegal haddock that is "small"*/
/* haddock_sublegal_keep: probability that an angler will retain a sublegal haddock that is "tiny"*/

/* haddock sub-legals in waves 1,2 */

global hadd_relax0=0
/* haddock sub-legals after wave 2 */
global hadd_relax_main=1

global haddock_sublegal_keep=0.30
global haddock_sublegal_keep2=0.01



/* discard of legal sized fish */
global dl_cod=0
global dl_hadd=0


/* Ignoring the Possession Limit */
/* For GOM Cod, approximately 1.5% of trips which kept cod kept more than the 10 fish possession limit */
/* These 11th and higher fish caught on these trips were responsible for 5.5% of all kept cod (by numbers).*/
/* In order to address this, i'll set 2 globals which are the probability which an angler will `comply with the bag limit'  */

global pcbag_comply=1
global phbag_comply=.65


global pcbag_non=1-$pcbag_comply
global phbag_non=1-$phbag_comply

disp "Are you calibrating or running the model?  Be sure that the Initial stock conditions are properly set at bookmarks 1 and 2."
pause

/* set up the name of the postfiles.  These names are use by the postfile command*/
tempname species1 species2 species1b species2b economic rec_catch



postfile `economic'  scenario wave total_trips WTP replicate cbag hbag cmin hmin cmax hmax codbag_comply cod_sublegal_keep cod_release_mort hadd_release_mort using `econ_out', replace
postfile `rec_catch' scenario wave total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight replicate  cbag hbag cmin hmin cmax hmax crep hrep codbag_comply cod_sublegal_keep cod_release_mort hadd_release_mort using `rec_out', replace

postfile `species1' scenario wave commercial_catch commercial_discards age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate  cbag hbag cmin hmin cmax hmax cod_release_mort hadd_release_mort using `sp1_out', replace
postfile `species2' scenario wave commercial_catch commercial_discards age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate  cbag hbag cmin hmin cmax hmax cod_release_mort hadd_release_mort using `sp2_out', replace

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
gen wave=.
gen replicate=.
gen length=.
gen released=.
gen haddockbag=.
gen cod_min=.
gen cod_max=.
gen hadd_min=.
gen hadd_max=.
gen fishing_year=.
save "cod_discard_saver.dta", replace
restore





/* These globals contain the locations of the cod age-length key raw data */
global codalkey cod_al_key.dta
global haddalkey haddock_al_key9max.dta

/* extract and build age-length key */
do "extract_length_age_data.do"

/* Here are some parameters */
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787




/* l-W is updated to be consistent with PDB 
These are the length-weight relationships for Cod and Haddock
GOM Cod Formula:
Wlive (kg) = 0.000005132·L(fork cm)3.1625 (p < 0.0001, n=4890)

http://www.nefsc.noaa.gov/publications/crd/crd0903/
Haddock Weight length formula 
Annual: Wlive (kg) = 0.000009298·L(fork cm)3.0205 (p < 0.0001, n=4890)
GROUNDFISH ASSESSMENT UPDATES 2012 page 181

Fork length and total length are equivalentfor haddock and haddock*/


global cod_lwa 0.000005132
global cod_lwb 3.1625
global had_lwa 0.000009298
global had_lwe 3.0205
global lngcat_offset_cod 0.5
global lngcat_offset_haddock 0.5

/* min and max sizes of cod and haddock in inches */
global codmin=4
global codmax=47
global haddmin=4
global haddmax=28



/* These are some Economic parameters */
/* We need to change these based on the Holzer and McConnell parameters */
/* This is the Probability Mass Function of shore, boat, party/head, and charter  See section WTP */

scalar shore=0.20
scalar boat=0.20
scalar party=0.20
scalar charter=0.40

/* This is the Probability Mass Function of Trip lengthSee section WTP */
scalar hour4=0.5
scalar hour8= 0.4
scalar hour12=0.1

/* These are scalars for the marginal and total costs of various types trips */
/* TC is total cost per trip, c is "pseudo-"marginal cost of trip length */
scalar c_chart=30
scalar c_party=11
scalar tc_boat=165
scalar tc_shore=105

/* logit coefficients
Model 2 from Holzer and McConnell */
global pi_cod_keep 0.3127457 
global pi_cod_release 0
global pi_hadd_keep 0.3653523 
global pi_hadd_release 0 
global pi_cost "-0.0015785"
global pi_trip_length 0.0911496
global pi_trip_length2 0

/* END of Global macros */
/**************************************************************/
/**************************************************************/

/* Begin the section of temporary macro adjustment */
/* Use this section to temporarily set macros to smaller values.  
This is useful for troubleshooting and debugging  */

/* Once we go to production, this entire section should be empty*/
/* END:section of temporary macro adjustment */

/*************************************************************/



/* Specify commercial quotas --
  */

/*These globals contain the commercial sub-ACLs for appropriat FISHING year*/
/* These need to be changed */


/* Cod  caught, acl, pct
2010    3843 /// ...   // 84.1
2011    4461 /// 4825 //  92.5
2012    2211 /// 3699 //  59.8
2013	740.8 /// 830 //  89.3 
2014    663.2.///830 //  79.9
2015    XXX /// 207 
2016    XXX /// XXXX 

*/

/* haddock caught, acl, pct
2010    377.7 ///      // 45.8
2011    485.6 /// 778  // 62.4
2012    246   /// 653  // 37.7
2013	171.3 /// 187  // 91.6
2014	324.7 /// 436  // 74.5
2015	XXX   /// 958

*/


global cod2011a=4462
global cod2012a=2211
global cod2013a=741
global cod2014a=663
global cod2015a=207*.85
global cod2016a=317*.85

/*global cod2015a=279 
agepro suggests 279 for FY2015 total removals
*/

global cod2016a=$cod2015a /*change me*/ 


global haddock2011a=485.6
global haddock2012a=246
global haddock2013a=171
global haddock2014a=324


global haddock2015a=958*.8
/*global haddock2015a=885 
agepro suggests 885 for FY2015 total removals
*/
global haddock2016a=2504*.8



global haddock_quota1=$haddock2011a*$mt_to_kilo*$kilo_to_lbs
global haddock_quota2=$haddock2012a*$mt_to_kilo*$kilo_to_lbs
global haddock_quota3=$haddock2013a*$mt_to_kilo*$kilo_to_lbs
global haddock_quota4=$haddock2014a*$mt_to_kilo*$kilo_to_lbs
global haddock_quota5=$haddock2015a*$mt_to_kilo*$kilo_to_lbs 
global haddock_quota6=$haddock2016a*$mt_to_kilo*$kilo_to_lbs 


global cod_quota1=$cod2011a*$mt_to_kilo*$kilo_to_lbs
global cod_quota2=$cod2012a*$mt_to_kilo*$kilo_to_lbs
global cod_quota3=$cod2013a*$mt_to_kilo*$kilo_to_lbs
global cod_quota4=$cod2014a*$mt_to_kilo*$kilo_to_lbs
global cod_quota5=$cod2015a*$mt_to_kilo*$kilo_to_lbs
global cod_quota6=$cod2016a*$mt_to_kilo*$kilo_to_lbs




/* Hinge value for Cod recruitment (converted to pounds)*/
global cod_SSBHinge=6300*$mt_to_kilo*$kilo_to_lbs


global replicate =1
/* Maximum iterations and maximum F for the commercial fishery (UNIT FREE)*/
global maxiterations=30
global maxfishingmortality=25









/***************************BEGIN HADDOCK SETUP ******************************/
/*****************************************************************************************/
/* BIOLOGICAL PARAMETERS FOR Natural Mortality, fishing mortality, SELECTIVITY, WEIGHTS (kg) */
/* These are from the 2015 Haddock Assessment Update */
/* Time constant and no uncertainty about them */
/*****************************************************************************************/
/* Pre-spawn natural and fishing mortality 
hMp1 == haddock Mortality part 1.  This is a feature present in AgePro 4, but not in AgePro 3
hFp1 == haddock Fishing mortality part 1.  (UNIT FREE)  */
/* total natural mortality */


global hMp1=0.25 
global hFp1=0.25 

/* This implies that SSB should be computed after 3 months, or the midpoint between the end of wave 1 and wave 2*/
global hssb_floor=floor(($hMp1*12)/2)
global hssb_ceil=ceil(($hMp1*12)/2)


global hMyr=.2
global hM=$hMyr/$waves


/* selectivity  -- at least one of the columns here must be 1*/
mata:
haddock_maturity=(0.042, 0.31, 0.82, 0.98, 1, 1,1,1,1)  
haddock_age_selectivity=(0.005,	0.043,0.166,0.335,0.51,0.702,0.849,1,0.816)
haddock_jan1_weights=(0.152,0.425,0.712,0.979,1.251,1.433,1.643,1.776,2.043)
haddock_midyear_weights= (0.317,0.573,0.858,1.119,1.388,1.528,1.748,1.875,2.043)
haddock_catch_weights= (0.302,0.578,0.877,1.153,1.426,1.561,1.762,1.898,2.049)
haddock_ssb_weights=haddock_jan1_weights
haddock_discard_weights=haddock_catch_weights
haddock_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0)


/* fraction discarded (hfdis) and maturity hmaturity are UNIT FREE*/

/* Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) all of these weights are taken from AgePro/Pop Dynamics
and are in kilograms*/

/* this step converts Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) to lbs */
haddock_jan1_weights=$kilo_to_lbs*haddock_jan1_weights
haddock_catch_weights=$kilo_to_lbs*haddock_catch_weights
haddock_midyear_weights=$kilo_to_lbs*haddock_midyear_weights
haddock_ssb_weights=$kilo_to_lbs*haddock_ssb_weights
haddock_discard_weights=$kilo_to_lbs*haddock_discard_weights
end

use "haddock_recruits_2015base.dta", clear 
/* or use haddock_recruits_2015constrain.dta */

/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/
mkmat recruit cdf, matrix(hrecruit_cdf)
scalar z1=rowsof(hrecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/

levelsof cdf, local(locrecruit_cdf) separate(,)
global hglobrecruit_cdf `locrecruit_cdf'
/***************************END Haddock SETUP ******************************/
/***************************** ******************************/




/* CHANGE ME */

/***************************BEGIN COD SETUP ******************************/
/*****************************************************************************************/
/* BIOLOGICAL PARAMETERS FOR Natural Mortality, fishing mortality, SELECTIVITY, WEIGHTS (kg) */
/* Time constant and no uncertainty about them */
/* THERE are 2 assessment models and three Projections for GOM COD */
/* Model 1 : M=0.2.  This model has a retrospective pattern
   Model 2: MRamp starts the beginning of the time series with M=0.2 and ends at M=0.4  This model has no retrospective pattern
      This model has a different selectivity vector, a different natural mortality, and a different recruitment time series
   
   Projection 1 uses Model 1
   Projection 2 uses Model 2 and assumes M=0.2
   Projection 3 uses Model 2 and assumes M=0.4
   
   The NEFMC's SSC picked an average of all 3 to set the OFL/ABC/ACL for the 2016 fishing year
*/

/*****************************************************************************************/
/* Pre-spawn natural and fishing mortality 
cMp1 == cod Mortality part 1.  This is a feature present in AgePro 4, but not in AgePro 3
cFp1 == cod Fishing mortality part 1.  This will probably not be used.   */
global cMp1=0.25
global cFp1=0.25
/* This implies that SSB should be computed after 3 months, or the midpoint between the end of wave 1 and wave 2*/
global cssb_floor=floor(($cMp1*12)/2)
global cssb_ceil=ceil(($cMp1*12)/2)

/* total natural mortality */
global M4=0.4
global M2=0.2

global cMyr=$M2
global cM=$cMyr/$waves

mata:

/* selectivity  -- at least one of these columns must be 1*/
cod_age_selectivity_base=(0.007 , 0.041,  0.213,  0.628 , 0.913 , 0.985,  0.998,  1.000,  1.000) /*from 2015 OP UP */
cod_age_selectivity_mramp=(0.005 , 0.032,  0.188,  0.615 , 0.917 , 0.987 , 0.998,  1.000,  1.000) /*from 2015 OP UP */

cod_age_selectivity=(cod_age_selectivity_base+cod_age_selectivity_mramp)/2  /* you've set this to the average of the two */

/* cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw), and fraction discarded (cfdis)*/
cod_jan1_weights=(0.104 , 0.522 , 1.079,  1.854,  2.547,  3.392,  4.307,  5.702,  9.866) /*from 2015 OP UP */
cod_midyear_weights=(0.354,  0.814,  1.555,  2.120,  2.765,  3.638,  4.640,  6.280,  9.866) /*from 2015 OP UP */
cod_catch_weights= (0.378 , 1.094 , 1.933,  2.479,  2.993 , 3.754 , 4.742 , 6.281,  9.866) /*from 2015 OP UP */
cod_ssb_weights=cod_jan1_weights /*from 2015 OP UP */
cod_discard_weights=cod_catch_weights /*from 2015 OP UP */
cod_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0) /*from 2015 OP UP */
cod_maturity=(0.084,  0.292,  0.649,  0.893 , 0.974 , 0.994 , 0.999 , 1.000 , 1.000) /*from 2015 OP UP */


/* this step converts Cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw) to lbs */
cod_jan1_weights=$kilo_to_lbs*cod_jan1_weights
cod_catch_weights=$kilo_to_lbs*cod_catch_weights
cod_midyear_weights=$kilo_to_lbs*cod_midyear_weights
cod_ssb_weights=$kilo_to_lbs*cod_ssb_weights
cod_discard_weights=$kilo_to_lbs*cod_discard_weights
end

use cod_recruits_2015average.dta
/* or
use "cod_recruits_2015base.dta", clear 
 
use cod_recruits_2015mramp.dta 
or */

/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/
mkmat recruit cdf, matrix(crecruit_cdf)
scalar c1=rowsof(crecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/

levelsof cdf, local(locrecruit_cdf) separate(,)
global cglobrecruit_cdf `locrecruit_cdf'
/***************************END COD SETUP ******************************/




/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'replicate' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/
/* Set up initial conditions data  */

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/cod agepro/$cod_naa_start", clear
keep if year==2015
gen u1=runiform()
gen u2=runiform()
sort u2 u1
gen id=_n
order id
drop u1 u2
save"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/cod agepro/cod_beginning_sorted2015.dta", replace



use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/haddock agepro/$hadd_naa_start", clear
keep if year==2015
gen u1=runiform()
gen u2=runiform()
sort u2 u1
gen id=_n
order id
drop u1 u2
save "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/haddock agepro/haddock_beginning_sorted2015.dta", replace



/* Break the annual fishing into a proportion by waves 
Compute the POUNDS caught by the commercial fishery in each wave */
clear
do "commercial_helper.do"


/* EVERYTHING BEFORE THIS POINT IS SETUP */

/* THIS IS WHERE THE MODEL BEGINS */
/* Eventually, set up loops over initial conditions (BSN replicates, minimum sizes, and bag limits. */



/* I have collected the 2012-2015 fishing regulations into three vectors. These are based on calendar years.

The only thing you need to do now is to assemble them into a vector of the appropriate length */
mata:
hbag_cy12=J(1,6,35)
hbag_cy13=J(1,6,35)
hbag_cy14=(35,35,3,3,3,3)
hbag_cy15=(3,3,3,3,3,3)
hbag_cy16=(3,3,3,3,3,3)
hbag_cy17=(3,3,3,3,3,3)


cbag_cy12=(10,10,9,9,9,9)
cbag_cy13=J(1,6,9)
cbag_cy14=(9,9,9,9,9,9)
cbag_cy15=(9,9,9,9,9,9)
cbag_cy16=(9,9,9,9,9,9)
cbag_cy17=(9,9,9,9,9,9)

hmin_cy12=J(1,6,18)
hmin_cy13=(18,18,21,21,21,21)
hmin_cy14=(21,21,21,21,21,21)
hmin_cy15=(21,21,21,21,21,21)
hmin_cy16=(21,21,21,21,21,21)
hmin_cy17=(21,21,21,21,21,21)

cmin_cy12=(24,24,19,19,19,19)
cmin_cy13=(19,19,19,19,19,19)
cmin_cy14=(19,19,21,21,21,21)
cmin_cy15=(21,21,21,21,21,21)
cmin_cy16=(21,21,21,21,21,21)
cmin_cy17=(21,21,21,21,21,21)

/* here is method 2 */
cmin_cy14[5]=99
cmin_cy14[6]=99

cmin_cy15=J(1,6,99)
cmin_cy16=J(1,6,99)
cmin_cy17=J(1,6,99)




end




local scenario_num=0

local had_bag 3
local had_min 17

mata: hbag_cy15=J(1,6,`had_bag')
mata: hbag_cy16=J(1,6,`had_bag')
mata: hbag_cy17=J(1,6,`had_bag')



mata: hmin_cy15=(21,21,J(1,4,`had_min'))
mata: hmin_cy16=J(1,6,`had_min')
mata: hmin_cy17=J(1,6,`had_min')



mata:  hmin_cy15[5]=99
mata:  hmin_cy15[2]=99

mata:  hmin_cy16[5]=99
mata:  hmin_cy16[2]=99

mata:  hmin_cy17[5]=99
mata:  hmin_cy17[2]=99




/*This assembles the bag and size limits*/
mata:haddock_bag_vec=(hbag_cy15,hbag_cy16, hbag_cy17)

mata:cod_bag_vec=(cbag_cy15,cbag_cy16,cbag_cy17)
mata: haddock_min_vec=(hmin_cy15,hmin_cy16,hmin_cy17)

mata: haddock_max_vec=J(1,length(haddock_min_vec),100)

mata: cod_min_vec=(cmin_cy15,cmin_cy16, cmin_cy17)
mata: cod_max_vec=J(1,length(cod_min_vec),100)






timer on 90
quietly forvalues replicate=1/$total_reps{	


/* MODEL SETUP -- CONSTRUCT THE SMOOOTHED AGE-LENGTH KEYS*/
/*The File cod_al_lowess.do:
1.  reads in the Cod age-length key and cleans the age-length key
2.   smooths the data
3.  Computes the age--> length probability matrix */

quietly do "cod_al_lowess.do"

/*The File hadd_al_lowess.do:
1.  reads in the haddock age-length key and cleans the age-length key
2.   smooths the data
3.  Computes the age--> length probability matrix*/
quietly do "haddock_al_lowess.do"

/*  
Compute historical recreational selectivity and send to mata
1.  read in the historical (2008-2010) age structures
2.  Convert to lengths, using the age-length key
3.  Aggregate into a single period.
3.  Merge with the recreational catch.
4.  Compute Catch/Available.
5.  Smooth and compute F_rec and smoothed, normalized F_rec.  
 */
 
 do "historical_normalized_fishing_helper.do"

/*THIS IS THE ENCOUNTERS-PER-TRIP SECTION*/
do "setup_encounters_per_trip.do"



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

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/haddock agepro/haddock_beginning_sorted2015.dta", replace
keep if id==`replicate'
scalar hreplicate=replicate[1]
notes: this contains the numbers at age of haddock for the current replicate
keep  age*

save "haddock_age_count.dta", replace
*/


/*  OPTION 3: Use the median numbers at age from the the AGEPRO output.  This is very useful to calibrate*/




use"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/haddock agepro/$hadd_naa_start", clear
keep if year==2015
collapse (median) age1-age9
scalar hreplicate=1

save "haddock_age_count.dta", replace



/*  OPTION 3A: Use the numbers at age from the the 2013 Assessment/Assessment Update This is very useful to calibrate 

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/haddock agepro/$hadd_naa", replace
keep if year==2013
scalar hreplicate=1
notes: this contains the numbers at age of haddock for the current replicate
keep  age*
foreach var of varlist age*{
	replace `var'=`var'*1000
}*/

save "haddock_age_count.dta", replace





putmata haddock_initial_counts=(age*), replace


/***************************** ******************************/
/***************************** ******************************/
/*********************************/
/*
There are a few "options here"  PAY CLOSE ATTENTION.
*/
/****************************/


/* This section of code reads in an observation, "stacks" it, performs the age--> length transformation and saves it to an auxilliary dta (cod_length_count.dta)*/


/* OPTION 2a:  Draw from the 2013 AGEPRO output, but ensure that the initial conditions are constant across replicates

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/cod agepro/cod_beginning_sorted2015.dta", clear
keep if id==`replicate'
scalar creplicate=replicate[1]
notes: this contains the numbers at age of cod for the current replicate
save "cod_age_count.dta", replace
keep age*
*/

/*  OPTION 3: Use the median numbers at age from the AGEPRO output*/

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/source_data/cod agepro/$cod_naa_start", clear
keep if year==2015
collapse (median) age1-age9
scalar creplicate=[1]


/*  OPTION 3A: Use the numbers at age from the the 2013 Assessment/Assessment Update This is very useful to calibrate 

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/source_data/cod agepro/$cod_naa", replace
keep if year==2013
scalar creplicate=1
notes: this contains the numbers at age of cod for the current replicate
foreach var of varlist age*{
	replace `var'=`var'*1000
}
keep  age*
*/

save "cod_age_count.dta", replace
 

/* pass the age structure to mata */

putmata cod_initial_counts=(age*), replace


/* SO THIS IS WHERE THE COMMERCIAL FISHING AND NATURAL MORTALITY MUST GO */
/*The Initial stock sizes for cod and haddock have been read into stata(Jan 1 NAA) */

/* THIS IS THE POPULATION BIOLOGY SECTION 
	a.  Compute commercial removals.
	b.  Compute natural mortality. */



/* Compute the distribution of effort by the recreational fishery in each wave 
Right now this distribution is hard coded -- one day it should be set up to look at the data*/
/* Allocate the commercial cod and haddock mortality to each of the 6 waves.  Allocate the recreational effort to each of the waves*/
clear
do "updated_recreational_effort_helper15.do"
/* these three lines are a little sloppy because they have 5 years of time hard-coded */
/* You'll have to go back and fix them */
/*FIX THIS UP, it works but very inelegant */


/* I have concatenated catch from 2011 through 2016 (quota1 to quota6) for cod and haddock.  To get things synched up, I've padded the vectors with two zeros corresponding to the first 2 waves of 2011.  
The commercial catch vectors start on Jan 1, 2011 and end on April 30, 2017 (end of FY2016)*/


mata: cod_commercial_catch=(0 \ 0 \ $cod_quota1*cod_commercial_waves[.,2] \ $cod_quota2*cod_commercial_waves[.,2] \ $cod_quota3*cod_commercial_waves[.,2]\ $cod_quota4*cod_commercial_waves[.,2]\ $cod_quota5*cod_commercial_waves[.,2] \ $cod_quota6*cod_commercial_waves[.,2])
mata: haddock_commercial_catch=(0 \ 0 \  $haddock_quota1*haddock_commercial_waves[.,2] \ $haddock_quota2*haddock_commercial_waves[.,2] \ $haddock_quota3*haddock_commercial_waves[.,2]\ $haddock_quota4*haddock_commercial_waves[.,2]\ $haddock_quota5*haddock_commercial_waves[.,2] \ $haddock_quota6*haddock_commercial_waves[.,2])

mata: cod_commercial_catch=cod_commercial_catch[|$comm_wave_starter \.|] 
mata: haddock_commercial_catch=haddock_commercial_catch[|$comm_wave_starter \.|]



/* You'll have to go back and fix them */
/*FIX THIS UP, it works but very inelegant */


mata: recreational_effort_waves = (recreational_effort_waves \ recreational_effort_waves\ recreational_effort_waves \ recreational_effort_waves \ recreational_effort_waves\recreational_effort_waves)
pause
/* Extract the proportion of commercial fishing mortality and recreational fishing effort for the appropriate wave */




forvalues this_wave=1/`max_waves'{
/*Send/Extract the commercial fishing and recreational effort to scalars
The mata: .... end command doesn't play nicely with a forvalues loop.

Either write each mata commmand individually, or construct a mata function.  
See http://www.stata.com/statalist/archive/2012-07/msg00961.html and 
<http://www.stata.com/statalist/archive/2011-01/msg00393.html>

I've written each mata command individually
*/
	disp "checkpoint5"

	mata:	st_numscalar("haddock_quota",haddock_commercial_catch[`this_wave'])
	mata:	st_numscalar("cod_quota",cod_commercial_catch[`this_wave'])
	mata:   st_numscalar("rec_effort_fraction",recreational_effort_waves[`this_wave',2])

/* Get the correct recreational fishing regulations a little ugly because I'm getting
scalars from mata and then sending them to globals. */

	mata:  st_numscalar("codbags",cod_bag_vec[`this_wave'])
	mata:  st_numscalar("codmins",cod_min_vec[`this_wave'])
	mata: st_numscalar("codmaxs",cod_max_vec[`this_wave'])


	mata: st_numscalar("hadbags",haddock_bag_vec[`this_wave'])
	mata: st_numscalar("hadmins",haddock_min_vec[`this_wave'])
	mata: st_numscalar("hadmaxs",haddock_max_vec[`this_wave'])

	global codbag =scalar(codbags)
	global cod_min_keep= scalar(codmins)
	global cod_max_keep= scalar(codmaxs)

		disp "checkpoint6"

	global haddockbag=scalar(hadbags)
	global hadd_min_keep= scalar(hadmins)
	global hadd_max_keep= scalar(hadmaxs)

	
	
	/* what is the fishing year?  */
	global fishing_year=ceil((`this_wave'-2)/6)
	/* what is the calendar year */
	global cal_year=ceil(`this_wave'/6)

	/* what is the "wave" of the calendar year (1-6, corresponding to MRIP wave)*/

	global current_wave=`this_wave'
	global wave_of_cy=`this_wave'-($cal_year-1)*6

	if `this_wave'<=2{
		/*This sets no non-compliance in the first 2 waves 
		global cod_relax=0
		global hadd_relax=0
*/	
		/*This allows non-compliance in the first 2 waves */
		global cod_relax=$cod_relax_main
		global hadd_relax=$hadd_relax_main

		
	}	
	if `this_wave'>=3{
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

	do "haddock_mortality_helper.do"
	do "cod_mortality_helper.do"
		
		/* If there are no recreational trips, then skip the recreational simulation, the "new_bio_out_v4" and go directly to the end of year cleanup.  
			rec_dead gets set to zero
			Might need to set other parameters and outputs to zero as well.
			Rec WTP and Rec Trips also set to zero
			*/
		if $wave_numtrips==0{
	
			scalar tripcount=0
			scalar total_WTP=0
			scalar ckept=0
			scalar creleased=0
			scalar hkept=0
			scalar hreleased=0
			scalar lbs_cod_kept=0
			scalar lbs_cod_released=0
			scalar lbs_hadd_kept=0
			scalar lbs_hadd_released=0 
			scalar cod_discarded_dead_weight=0 
			scalar haddock_discard_dead_weight=0


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


merge m:1 age using "haddock_smooth_age_length.dta"
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

save "haddock_length_count.dta", replace



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

merge 1:m age using "cod_smooth_age_length.dta"
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
save "cod_length_count.dta", replace

/* Recreational Fishing occurs in Feb */
do "simulation_v41a.do"

/* post the fishing statistics for wave 1
quietly count if trip_occur==1
scalar tripcount=r(N)
quietly summ WTP if trip_occur==1
scalar total_WTP=r(sum)
 */
 
/* post the fishing statistics for wave 1 -- add up "prob" and "probability weighted WTP"*/

tempvar tt wt wtp
egen `tt'=total(prob)
scalar tripcount=floor(`tt'[1])

gen `wt'=prob*WTP
egen `wtp'=total(`wt')
scalar total_WTP=floor(`wtp'[1])
 
/* BUILD THE ROLLING LENGTH--> AGE KEYS FOR COD AND HADDOCK */
do "rolling_age_length_key.do"

/* The Bio-out helper file constructes the age structure of Kept and released fish and saves it to the species_ages_out.dta file.*/
do "new_bio_out_v4.do"


/* Post the kept and released fish for each (and weights) from mata
(scalar(ckept)) (scalar(creleased)) (scalar(hkept)) (scalar(hreleased)) (scalar(lbs_cod_kept)) (scalar(lbs_cod_released)) (scalar(lbs_hadd_kept)) (scalar(lbs_hadd_released)) 
*/
mata: st_numscalar("ckept", ackeep)
mata: st_numscalar("creleased", acrel)
mata: st_numscalar("hkept", ahkeep)
mata: st_numscalar("hreleased", ahrel)

mata: st_numscalar("lbs_cod_kept", aggregate_cod_kept_pounds)
mata: st_numscalar("lbs_cod_released", aggregate_cod_released_pounds)

mata: st_numscalar("lbs_hadd_kept", aggregate_haddock_kept_pounds)
mata: st_numscalar("lbs_hadd_released", aggregate_haddock_rel_pounds)


/* Compute dead by multiply the discards by discard mortality and the using collapse (sum) */
use  "cod_ages_out.dta", clear
foreach var of varlist age*{
	replace `var'= `var'*$mortality_release if status==0
}
collapse (sum) age*
/* send off to mata */
putmata rec_dead_cod=(age1-age9), replace

use  "haddock_ages_out.dta", clear
foreach var of varlist age*{
	replace `var'= `var'*$haddock_mortality_release if status==0
}
collapse (sum) age*
putmata rec_dead_haddock=(age1-age9), replace


/* This is the end of the else statement*/
	}
	

/* Compute end of period counts and store them in a vector.  These are equivalent to the initial counts for the beginning of the next period (except for wave 6)*/
	do "haddock_end_of_wave_helper.do"
	do "cod_end_of_wave_helper.do"

		
	/* check that it's the end of the year (wave 6) */
	/* IF it is, then begin population dynamics. */
	/* HERE BEGINS POPULATION DYNAMICS 
		At the end of the year, cod and haddock transition to the next age class
		Age 1's are created by drawing Recruits
		We also check the "Hinge" if necessary.	
		the "end_of_wave_counts" are overwritten*/
		
	if $wave_of_cy==6{
	/* Compute cod SSB, first in individuals, then in lbs (in lbs)
	first compute the cssb_lookup, hssb_lookup globals.  This tells my code which "end_of_wave" to examine when computing SSB.	*/
	global cssb_lookup_floor=($cal_year-1)*6+$cssb_floor
	global cssb_lookup_ceil=($cal_year-1)*6+$cssb_ceil
	global hssb_lookup_floor=($cal_year-1)*6+$hssb_floor
	global hssb_lookup_ceil=($cal_year-1)*6+$hssb_ceil


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

/* FIX THIS LATER: What do I need to save? */
post `economic' (`scenario_num') (`this_wave') (scalar(tripcount)) (scalar(total_WTP)) (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep) ($pcbag_comply)  ($cod_sublegal_keep)  ($mortality_release) ($haddock_mortality_release)
post `rec_catch' (`scenario_num') (`this_wave') (scalar(tripcount)) (scalar(ckept)) (scalar(creleased)) (scalar(hkept)) (scalar(hreleased)) (scalar(lbs_cod_kept)) (scalar(lbs_cod_released)) (scalar(cod_discarded_dead_weight)) (scalar(lbs_hadd_kept)) (scalar(lbs_hadd_released)) (scalar(haddock_discard_dead_weight)) (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep) (scalar(creplicate)) (scalar(hreplicate)) ($pcbag_comply)  ($cod_sublegal_keep)  ($mortality_release) ($haddock_mortality_release)
	disp "checkpoint2"


/* These posts are not doing exactly I want them to do yet.
*/


/* Post the end of wave counts */
clear
getmata (age*)=cod_end_of_wave_counts$current_wave
post `species1'  (`scenario_num') (`this_wave') (scalar(cod_commercial_landings)) (scalar(cod_commercial_discards)) (age1[1]) (age2[1]) (age3[1]) (age4[1]) (age5[1]) (age6[1]) (age7[1]) (age8[1]) (age9[1]) (`replicate')  ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep)  ($mortality_release) ($haddock_mortality_release)
clear
getmata (age*)=haddock_end_of_wave_counts$current_wave
	disp "checkpoint3"

post `species2'  (`scenario_num') (`this_wave') (scalar(haddock_commercial_landings)) (scalar(haddock_commercial_discards))  (age1[1]) (age2[1]) (age3[1]) (age4[1]) (age5[1]) (age6[1]) (age7[1]) (age8[1]) (age9[1]) (`replicate') ($codbag) ($haddockbag) ($cod_min_keep) ($hadd_min_keep) ($cod_max_keep) ($hadd_max_keep)  ($mortality_release) ($haddock_mortality_release)
	disp "checkpoint4"

/*THIS IS the end of code checking */ 
/* This is the end of the "wave loop*/
		}

}

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

/* convert weights to mts 
use "recreational_catches2014_DU.dta", clear
foreach var of varlist cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight{
	replace `var'=`var'/($mt_to_kilo*$kilo_to_lbs)
}

save "recreational_catches2014_DU.dta", replace*/

timer list
log close
