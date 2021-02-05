/**************************************************************/
/*************************************************************/
/*************************************************************/

/*
This .do file was written by Min-Yang.Lee@noaa.gov 
Version 1.1
April25, 2012

TABLE OF CONTENTS
0.  File description, Meta Data, changegoals, and changelog
1.  Global, scalar, and other setup (parameterization)
2.  Reading in?
3.  Population Dynamics -- including call to economic model
4.  Loop?
*/

/* BEGIN Section 0: FILE DESCRIPTION */

/* This model holds the biological model for cod and haddock.  
It will "nest" outside the economic model.  In other words, the economic model will be nested inside this model.*/



/*The purpose of these files is to:

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
 */

/*Changegoals:

/*
Changelog:
	1.1.3:  Data has been updated.
	1.1.2:  Results stored in postfiles
	
	1.1.1:  Adjust the Fh iteration segment to a `while' loop.  Marked infeasible quotas and non-convergence.
	1.0.0:  Copy and paste job from the haddock caa model 
	
	
*/


/* 	
OTHER NOTES:
A note on recruitment models which do not depend on SSB: 
The simulated recruitment can be drawn at once for all model years.  I still implement recruitment year-by-year, to preserve a little bit of flexibility. */

/*  The stock assessment produces the number of fish at the end of the terminal year (year 0).  This code projects forward the population for years 1-'number of years'.*/ 
/* HACKS  and To Do
   
1.  Initial stock structure of haddock is a hack./*****************IMPORTANT ******************************/
 
 Two files must be updated for haddock:
	1.  haddock_numbers_at_age.dta must be changed
		I've used the numbers at age from GARM III (up to 2007) AND the most recent AGEPRO (2008-2010)
	2.  haddock_begin.dta:  I've used the numbers from the 2008 bsn file.  These must be updated to the new assessment numbers
 THESE MUST BE REPLACED IN FEB WHEN THE NEW STOCK ASSESSMENT IS DONE 

2.  The minimum sizes of cod and haddock must be user specified
3.  The number of age classes for cod and haddock must be known in advance


Changes were made to the ROlling AGE length key section via commenting out and repalcing hyr1 and cyr1.  Make sure to reverse this
changes were made to the 'starting numbers at age in the via commenting out.  make sure to reverse this .  These two steps were done to calibrate the model to 2007 catches.
*/






/**********************END SECTION 0: FILE DESCRIPTION******************/
/*************************************************************/
*************************************************************/

/* Preamble */
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO"
log using cod_and_haddock_C24.smcl, replace
clear
macro drop _all
scalar drop _all
matrix drop _all
set more off
set seed 8675
timer clear
timer on 99
pause off

disp "Are you calibrating or running the model?  Be sure that the Initial stock conditions are properly set at bookmarks 1 and 2."
pause

/* set up the name of the postfiles.  These names are use by the postfile command*/
tempname species1 species2 species3 economic rec_catch

postfile `species1' age0 age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate year pseudoFh converged cbag hbag cmin hmin cmax hmax using "haddock_biology.dta", replace
postfile `species2' age0 age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate year pseudoFc converged cbag hbag cmin hmin cmax hmax using "cod_biology.dta", replace
postfile `economic' total_trips WTP replicate year cbag hbag cmin hmin cmax hmax codbag_comply cod_sublegal_keep using "economic_data.dta", replace
postfile `rec_catch' total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_weight_kept cod_weight_discard haddock_weight_kept haddock_weight_discard replicate year cbag hbag cmin hmin cmax hmax crep hrep codbag_comply cod_sublegal_keep using "recreational_catches.dta", replace

/* set up the tempfiles to store cod and haddock eoy temporary data*/
tempfile cod_eoy1 cod_eoy2 cod_eoy3 hadd_eoy1 hadd_eoy2 hadd_eoy3

tempfile holdingbin_yr2 holdingbin_yr1

global total_reps=2


/* These globals contain the locations of the cod age-length key raw data */
global codalkey cod_al_key.dta
global haddalkey haddock_al_key9max.dta


/* Here are some parameters */
scalar mt_to_kilo=1000
scalar kilo_to_lbs=2.20462262
scalar cm_to_inch=0.39370787


global numtrips 500 
global codbag 10
global haddockbag 35
global cod_min_keep 24
global cod_max_keep 100
global hadd_min_keep 18
global hadd_max_keep 100



/* NOTE cTAC and hTAC should be in lbs */
global cTAC= 2824*mt_to_kilo*kilo_to_lbs
global hTAC= 1000*mt_to_kilo*kilo_to_lbs

global cod_lwa -11.7231
global cod_lwb 3.0521
global had_lwa 0.00000987
global had_lwe 3.0987


/* min and max sizes of cod and haddock in inches */
global codmin=3
global codmax=47
global haddmin=4
global haddmax=28


/* Retention of sub-legal fish */
/* cod_relax: window below the minimum size that anglers might retain sublegal fish */
/* cslkeep: probability that an angler will retain a sublegal cod in that size window*/

global cod_relax=2
global cslkeep=.2

/* hadd_relax: window below the minimum size that anglers might retain sublegal fish */
/* hslkeep: probability that an angler will retain a sublegal haddock in that size window*/

global hadd_relax=1
global hslkeep=0


/* discard of legal sized fish */
global dl_cod=0
global dl_hadd=0


/* Ignoring the Possession Limit */
/* For GOM Cod, approximately 1.5% of trips which kept cod kept more than the 10 fish possession limit */
/* These 11th and higher fish caught on these trips were responsible for 5.5% of all kept cod (by numbers).*/
/* In order to address this, i'll set 2 globals which are the probability which an angler will `comply with the bag limit'  */

global pcbag_comply=1
global phbag_comply=1


/* These are some Economic parameters */
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

/* logit coefficients */
global pi_cod_keep 0.3243 
global pi_cod_release 0.0942
global pi_hadd_keep 0.3195 
global pi_hadd_release 0.1063 
global pi_cost "-0.005392"
global pi_trip_length 0.0743 
global pi_trip_length2 "-0.003240"

/* cutoff probability for Logit trip occurrence=1 */
global cutoff_prob 0.50

/*
These are the length-weight relationships for Cod and Haddock
GOM Cod Formula:
ln Weight (kg, live) = -11.7231 + 3.0521 ln Length (cm)
http://www.nefsc.noaa.gov/publications/crd/crd0903/
Haddock Weight length formula 
Autumn: Wlive (kg) = 0.00000987·L(fork cm)3.0987 (p < 0.0001, n=4890)
http://nefsc.noaa.gov/publications/crd/crd0815/pdfs/garm3r.pdf
Fork length and total length are the same for haddock.
Most haddock are caught in the fall (Sept.-Oct) and it just doesn't look like there's a significant difference between the formulas anyway*/


/* END of Global macros */
/**************************************************************/
/**************************************************************/

/* Begin the section of temporary macro adjustment */
/* Use this section to temporarily set macros to smaller values.  
This is useful for troubleshooting and debugging  */

/* Once we go to production, this entire section should be empty*/
global cTAC= 2824*mt_to_kilo*kilo_to_lbs*10000
global hTAC= 1000*mt_to_kilo*kilo_to_lbs*10000
/* END:section of temporary macro adjustment */

/*************************************************************/

/* Specify commerical quota1  */
/* IN LBS */
/*These are set to actual landings (NERO) for the 2010 fishing year*/
global haddock_quota1=(367.8+6.9)*mt_to_kilo*kilo_to_lbs
global cod_quota1=(3537.1+195.2)*mt_to_kilo*kilo_to_lbs

global haddock_quota2=$haddock_quota1
global haddock_quota3=$haddock_quota1

global cod_quota2=$cod_quota1
global cod_quota3=$cod_quota1


/* Hinge value for Cod recruitment (KG)*/
global cod_SSBHinge=7300*mt_to_kilo*kilo_to_lbs

/* Mortality rate of the released fish (UNIT FREE) */
scalar mortality_release=1

/*****************************************************************************************/
/* how many years does the model run */
/*****************************************************************************************/
global replicate =1
/* Maximum iterations and maximum F for the commercial fishery (UNIT FREE)*/
global maxiterations=30
global maxfishingmortality=25





/***************************BEGIN HADDOCK SETUP ******************************/
/*****************************************************************************************/
/* BIOLOGICAL PARAMETERS FOR Natural Mortality, fishing mortality, SELECTIVITY, WEIGHTS (kg) */
/* These are from Paul N.  From the 2012 Haddock Assessment Update */
/* Time constant and no uncertainty about them */
/*****************************************************************************************/
/* Pre-spawn natural and fishing mortality 
hMp1 == haddock Mortality part 1.  This is a feature present in AgePro 4, but not in AgePro 3
hFp1 == haddock Fishing mortality part 1.  (UNIT FREE)  */
local hMp1=0.25
local hFp1=0.25
/* total natural mortality */

local hM=.2

/* selectivity  -- at least one of the columns here must be 1*/
mat hsel=[0.009, 0.017, 0.091, 0.297, 0.672, 0.660, 1, 1, 1]
/* Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) all of these weights are taken from AgePro/Pop Dynamics
and are in kilograms*/


/* fraction discarded (hfdis) and maturity hmaturity are UNIT FREE*/
mat hj1w=[0.100, 0.298, 0.706, 0.984,1.208,1.498,1.650,1.786, 1.967]
mat hmyw=[0.178, 0.603, 0.905, 1.075, 1.357, 1.629, 1.699, 1.879, 1.967]

mat hcw= hmyw
mat hssbw=hj1w
mat hdw=hcw
mat hfdis=[0, 0, 0, 0, 0, 0, 0, 0, 0]
mat hmaturity=[0.027,0.236,0.773,0.974,0.998,1, 1,  1,  1]


/* this step converts Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) to lbs */
mat hj1w=scalar(kilo_to_lbs)*hj1w
mat hcw=scalar(kilo_to_lbs)*hcw
mat hmyw=scalar(kilo_to_lbs)*hmyw
mat hssbw=scalar(kilo_to_lbs)*hssbw
mat hdw=scalar(kilo_to_lbs)*hdw




/* name the matrix columns -- this isn't really necessary, but it's quick */
/* selectivity*/

local p=colsof(hsel)
global hageclasses=colsof(hsel)
local names=""
forvalues v=1/`p'{
	local names=" `names'  age`v'"
}

mat rownames hsel=S
mat colnames hsel= `names'


/* j1weights*/

local p=colsof(hj1w)
local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`v'"
}

mat rownames hj1w=kg
mat colnames hj1w=  `names'


/* cweights*/
local p=colsof(hcw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames hcw=kg
mat colnames hcw=  `names'

/* ssbweights*/
local p=colsof(hssbw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames hssbw=kg
mat colnames hssbw=  `names'

/* dweights*/
local p=colsof(hdw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames hdw=kg
mat colnames hdw=  `names'


/* mid year weights*/
local p=colsof(hmyw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames hmyw=kg
mat colnames hmyw=  `names'

/* discard_frac*/
local p=colsof(hfdis)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames hfdis=ratio
mat colnames hfdis=  `names'

use "haddock_recruit.dta", clear
/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/
mkmat recruit cdf, matrix(hrecruit_cdf)
scalar z1=rowsof(hrecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/
levelsof cdf, local(locrecruit_cdf) separate(,)
/* notes this levelsof command looks at the value of the cdf, so the fact that there are repeated obs of a particular value of recruits is not a big deal*/
global hglobrecruit_cdf `locrecruit_cdf'
/***************************END Haddock SETUP ******************************/
/***************************** ******************************/



/***************************BEGIN COD SETUP ******************************/
/*****************************************************************************************/
/* BIOLOGICAL PARAMETERS FOR Natural Mortality, fishing mortality, SELECTIVITY, WEIGHTS (kg) */
/* Time constant and no uncertainty about them */
/*****************************************************************************************/
/* Pre-spawn natural and fishing mortality 
cMp1 == cod Mortality part 1.  This is a feature present in AgePro 4, but not in AgePro 3
cFp1 == cod Fishing mortality part 1.  This will probably not be used.   */
local cMp1=0.25
local cFp1=0.25
/* total natural mortality */

local cM=.2

/* selectivity  -- at least one of these columns must be 1*/
mat csel=[0.02, 0.109, 0.395, 0.844, 1, 1, 0.896, 0.880, 0.673]
/* cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw), and fraction discarded (cfdis)*/
mat cj1w=[0.156, 0.496, 1.159, 2.109, 2.925, 3.567, 4.855, 6.933, 12.342]
mat cmyw=[0.293, 0.914, 1.708, 2.677, 3.28, 3.855, 5.773, 8.120, 12.343]
mat ccw= cmyw
mat cssbw=cj1w
mat cdw=ccw
mat cfdis=[0, 0, 0, 0, 0, 0, 0, 0, 0]
mat cmaturity=[0.094, 0.287, 0.610, 0.859, 0.959, 0.989, 0.997, 0.999, 1]


/* this step converts Cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw) to lbs */
mat cj1w=scalar(kilo_to_lbs)*cj1w
mat ccw=scalar(kilo_to_lbs)*ccw
mat cmyw=scalar(kilo_to_lbs)*cmyw
mat cssbw=scalar(kilo_to_lbs)*cssbw
mat cdw=scalar(kilo_to_lbs)*cdw

/* name the matrix columns -- this isn't really necessary, but it's quick */

local p=colsof(csel)
global cageclasses=colsof(csel)
local names=""
forvalues v=1/`p'{
	local names=" `names'  age`v'"
}

mat rownames csel=S
mat colnames csel= `names'


/* j1weights*/

local p=colsof(cj1w)
local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`v'"
}

mat rownames cj1w=kg
mat colnames cj1w=  `names'


/* cweights*/
local p=colsof(ccw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames ccw=kg
mat colnames ccw=  `names'

/* ssbweights*/
local p=colsof(cssbw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}

mat rownames cssbw=kg
mat colnames cssbw=  `names'

/* dweights*/
local p=colsof(cdw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}

mat rownames cdw=kg
mat colnames cdw=  `names'


/* mid year weights*/
local p=colsof(cmyw)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}



mat rownames cmyw=kg
mat colnames cmyw=  `names'

/* discard_frac*/
local p=colsof(cfdis)

local names=""
forvalues v=1/`p'{
	local vv=`v'
	local names=" `names'  age`vv'"
}

mat rownames cfdis=ratio
mat colnames cfdis=  `names'



use "cod_recruit.dta", clear
/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/
mkmat recruit cdf, matrix(crecruit_cdf)
scalar c1=rowsof(crecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/

levelsof cdf, local(locrecruit_cdf) separate(,)
global cglobrecruit_cdf `locrecruit_cdf'
/***************************END COD SETUP ******************************/
/***************************** ******************************/


/* EVERYTHING BEFORE THIS POINT IS SETUP */
/* THIS IS WHERE THE MODEL BEGINS */


/* i'm looping over the cod-minimum here */



/* This is the appropriate point to begin looping through the BSN file using */
forvalues replicate =1/$total_reps{
	


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
Process_cod_selectivity 
1.  read in the historical (2008-2010) age structures
2.  Convert to lengths, using the age-length key
3.  Aggregate into a single period.
3.  Merge with the recreational catch.
4.  Compute Catch/Available.
5.  Smooth and compute F_rec and smoothed, normalized F_rec.  
 */

quietly do "process_cod_selectivity.do"
/*  
Process_haddock_selectivity does the same thing for haddock
 */
quietly do "process_haddock_selectivity.do"





/*  OPTION 3: Use the median numbers at age from the the 2013 AGEPRO output*/
use"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/haddock agepro/hadd_agepro_2012/haddock_beginning_dataset.dta", clear
keep if year==2013
drop repl year
foreach var of varlist age1-age9{
	rename `var' hyr1_`var'
}
collapse (median) hyr1_age1-hyr1_age9
notes: this contains the median numbers at age of haddock for the current replicate
save "haddock_age_count.dta", replace
keep hyr1_age*

xpose, clear varname
rename v1 j1count
gen age=substr(_varname, -1,.)
drop _varname
destring, replace
order age j1count
sort age
/* this section takes the age structure and converts it into numbers at length*/
merge m:1 age using "haddock_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*j1count
}
collapse (sum)length*
gen myi=1
reshape long length, i(myi) j(myj)
rename length count
rename myj length
label var length "length of haddock in inches"
drop myi
notes drop _all
notes: this contains the numbers at lengths of haddock for the current replicate
save "haddock_length_count.dta", replace






/*  OPTION 3: Use the median numbers at age from the 2012 or 2013 AGEPRO output */

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/source_data/cod agepro/cod_beginning.dta", clear
foreach var of varlist age1-age9{
	rename `var' cyr1_`var'
}
collapse (median) cyr1_age1-cyr1_age9

notes: this contains the median numbers at age of cod
save "cod_age_count.dta", replace
keep cyr1_age*

xpose, clear varname
rename v1 j1count
gen age=substr(_varname, -1,.)
destring, replace
drop _varname
order age j1count
sort age

/* this section takes the age structure and converts it into numbers at length*/

merge 1:m age using "cod_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*j1count
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

do "simulation_v37.do"




rename v1 j1count
gen age=substr(_varname, -1,.)
destring, replace
drop _varname
order age j1count
sort age
merge m:1 age using "haddock_smooth_age_length.dta"
foreach var of varlist length*{
	replace `var'=`var'*j1count
}
collapse (sum)length*
gen myi=1
reshape long length, i(myi) j(myj)
rename length count
rename myj length
label var length "length of haddock in inches"
drop myi
notes drop _all
notes: this contains the numbers at lengths of haddock for the current replicate
save "haddock_length_count.dta", replace



} /* The close loop bracket is basically the last thing before the `log close' statement */

/*
gen ctot=crel+ckee
gen htot=hkee+hrel
by trip_occur, sort: summ ctot ckeep crel htot hkee hrel
summ ctot ckeep crel htot hkee hrel crand hrand
*/

postclose `species1'
postclose `species2'
postclose `economic'
postclose `rec_catch'

log close

