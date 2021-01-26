/* checking out haddock and cod initial stocks */
/* this computes the "SSB" if mortality hasn't occurred */

cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock"

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


global total_reps=3
global numtrips 465000
global codbag 10
global haddockbag 35
global cod_min_keep 24
global cod_max_keep 100
global hadd_min_keep 18
global hadd_max_keep 100

global FMax 25
global maxfiter 30
global cod_comm_discard_mortality 1
global haddock_comm_discard_mortality 1

/* Mortality rate of the released fish (UNIT FREE) */
scalar mortality_release=0.3




/* Retention of sub-legal fish */
/* cod_relax: window below the minimum size that anglers might retain sublegal fish */
/* cod_sublegal_keep: probability that an angler will retain a sublegal cod in that size window*/

global cod_relax=2
global cod_sublegal_keep=0

/* hadd_relax: window below the minimum size that anglers might retain sublegal fish */
/* haddock_sublegal_keep: probability that an angler will retain a sublegal haddock in that size window*/

global hadd_relax=1
global haddock_sublegal_keep=0


/* discard of legal sized fish */
global dl_cod=0
global dl_hadd=0


/* Ignoring the Possession Limit */
/* For GOM Cod, approximately 1.5% of trips which kept cod kept more than the 10 fish possession limit */
/* These 11th and higher fish caught on these trips were responsible for 5.5% of all kept cod (by numbers).*/
/* In order to address this, i'll set 2 globals which are the probability which an angler will `comply with the bag limit'  */

global pcbag_comply=1
global phbag_comply=1


disp "Are you calibrating or running the model?  Be sure that the Initial stock conditions are properly set at bookmarks 1 and 2."
pause

/* set up the name of the postfiles.  These names are use by the postfile command*/
tempname species1 species2 species3 economic rec_catch

postfile `species1' age0 age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate year pseudoFh converged hadd_ssb cbag hbag cmin hmin cmax hmax using "haddock_biology.dta", replace
postfile `species2' age0 age1 age2 age3 age4 age5 age6 age7 age8 age9 replicate year pseudoFc converged cod_ssb cbag hbag cmin hmin cmax hmax using "cod_biology.dta", replace
postfile `economic' total_trips WTP replicate year cbag hbag cmin hmin cmax hmax codbag_comply cod_sublegal_keep using "economic_data.dta", replace
postfile `rec_catch' total_trips cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_weight_kept cod_weight_discard haddock_weight_kept haddock_weight_discard replicate year cbag hbag cmin hmin cmax hmax crep hrep codbag_comply cod_sublegal_keep using "recreational_catches.dta", replace

/* set up the tempfiles to store cod and haddock eoy temporary data*/
tempfile cod_eoy1 cod_eoy2 cod_eoy3 hadd_eoy1 hadd_eoy2 hadd_eoy3
tempfile holdingbin_yr3  holdingbin_yr2 holdingbin_yr1 

/* These globals contain the locations of the cod age-length key raw data */
global codalkey cod_al_key.dta
global haddalkey haddock_al_key9max.dta


/* Here are some parameters */
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787


/* NOTE cTAC and hTAC should be in lbs */
global cTAC= 2215*$mt_to_kilo*$kilo_to_lbs
global hTAC= 1000*$mt_to_kilo*$kilo_to_lbs

global cod_lwa -11.7231
global cod_lwb 3.0521
global had_lwa 0.00000987
global had_lwe 3.0987


/* min and max sizes of cod and haddock in inches */
global codmin=3
global codmax=47
global haddmin=4
global haddmax=28



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
global cTAC= 2215*$mt_to_kilo*$kilo_to_lbs*10000
global hTAC= 1000*$mt_to_kilo*$kilo_to_lbs*10000
/* END:section of temporary macro adjustment */

/*************************************************************/

/* Specify commerical quota1  */
/* IN LBS */
/*These are set to actual landings (NERO) for the 2010 fishing year*/
global haddock_quota1=(367.8+6.9)*$mt_to_kilo*$kilo_to_lbs
global haddock_quota2=$haddock_quota1
global haddock_quota3=$haddock_quota1

global cod_quota1=(3537.1+195.2)*$mt_to_kilo*$kilo_to_lbs
global cod_quota2=$cod_quota1
global cod_quota3=$cod_quota1


/* Hinge value for Cod recruitment (KG)*/
global cod_SSBHinge=7300*$mt_to_kilo*$kilo_to_lbs


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
/* total natural mortality */

global hMp1=0.25
global hFp1=0.25
global hM=.2

/* selectivity  -- at least one of the columns here must be 1*/
mata:
haddock_age_selectivity=(0.009, 0.017, 0.091, 0.297, 0.672, 0.660, 1, 1, 1)
/* Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) all of these weights are taken from AgePro/Pop Dynamics
and are in kilograms*/


/* fraction discarded (hfdis) and maturity hmaturity are UNIT FREE*/
haddock_jan1_weights=(0.100, 0.298, 0.706, 0.984,1.208,1.498,1.650,1.786, 1.967)
haddock_midyear_weights=(0.178, 0.603, 0.905, 1.075, 1.357, 1.629, 1.699, 1.879, 1.967)

haddock_catch_weights= haddock_midyear_weights
haddock_ssb_weights=haddock_jan1_weights
haddock_discard_weights=haddock_catch_weights
haddock_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0)
haddock_maturity=(0.027,0.236,0.773,0.974,0.998,1, 1,  1,  1)


/* this step converts Haddock (h) January weights(hj1w) , Catch weights (hcw), midyear weights (hmyw), and spawning weights (hssbw), discard weights (hdw) to lbs */
haddock_jan1_weights=$kilo_to_lbs*haddock_jan1_weights
haddock_catch_weights=$kilo_to_lbs*haddock_catch_weights
haddock_midyear_weights=$kilo_to_lbs*haddock_midyear_weights
haddock_ssb_weights=$kilo_to_lbs*haddock_ssb_weights
haddock_discard_weights=$kilo_to_lbs*haddock_discard_weights
end

use "haddock_recruit.dta", clear
/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/
mkmat recruit cdf, matrix(hrecruit_cdf)
scalar z1=rowsof(hrecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/

levelsof cdf, local(locrecruit_cdf) separate(,)
global hglobrecruit_cdf `locrecruit_cdf'
/***************************END Haddock SETUP ******************************/
/***************************** ******************************/
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
global cMp1=0.25
global cFp1=0.25
/* total natural mortality */

global cM=.2

mata:
/* selectivity  -- at least one of these columns must be 1*/
cod_age_selectivity=(0.02, 0.109, 0.395, 0.844, 1, 1, 0.896, 0.880, 0.673)
/* cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw), and fraction discarded (cfdis)*/
cod_jan1_weights=(0.156, 0.496, 1.159, 2.109, 2.925, 3.567, 4.855, 6.933, 12.342)
cod_midyear_weights=(0.293, 0.914, 1.708, 2.677, 3.28, 3.855, 5.773, 8.120, 12.343)
cod_catch_weights= cod_midyear_weights
cod_ssb_weights=cod_jan1_weights
cod_discard_weights=cod_catch_weights
cod_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0)
cod_maturity=(0.094, 0.287, 0.610, 0.859, 0.959, 0.989, 0.997, 0.999, 1)


/* this step converts Cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw) to lbs */
cod_jan1_weights=$kilo_to_lbs*cod_jan1_weights
cod_catch_weights=$kilo_to_lbs*cod_catch_weights
cod_midyear_weights=$kilo_to_lbs*cod_midyear_weights
cod_ssb_weights=$kilo_to_lbs*cod_ssb_weights
cod_discard_weights=$kilo_to_lbs*cod_discard_weights
end

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

use"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/haddock agepro/hadd_agepro_2012/haddock_beginning_dataset.dta", clear
keep if year==2013
putmata haddock_age=(age1-age9), replace

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/source_data/cod agepro/cod_beginning.dta", clear
keep if year==2013

putmata cod_age=(age1-age9), replace

mata
cac=cols(cod_age_selectivity)
ncm=J(1,cac,$hM)
ones=J(1, cac,1)


cod_mature=cod_age:*cod_maturity
cod_ssb=cod_mature*cod_ssb_weights'

cF=.3*cod_age_selectivity

cac1=cF:/(ncm+cF)
cac2=(ones:-exp(-ncm-cF))
cod_catch_count=(cac1:*cac2):*cod_age

cam1=ncm:/(ncm+cF)
cam2=(ones:-exp(-ncm-cF))
cod_nmort_count=(cac1:*cac2):*cod_age

cod_survived=cod_age:-cod_catch_count:-cod_nmort_count

cod_mature=cod_survived:*cod_maturity

cod_ssb=cod_mature*cod_ssb_weights'

end

clear

getmata cod_ssb 
/* convert from pounds to mt*/
replace cod_ssb=cod_ssb/($mt_to_kilo*$kilo_to_lbs)

