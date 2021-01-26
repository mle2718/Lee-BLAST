/* this is just a storage do file for the biological parameters for both species */
/* min and max sizes of cod and haddock in inches */
global codmin=4
global codmax=47
global haddmin=4
global haddmax=28
/*Agepro convergence housekeeping params */
global FMax 25
global maxfiter 30
global cod_comm_discard_mortality 1
global haddock_comm_discard_mortality 1


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


 
 /*global for the cod and haddock catch-at-length distributions (MRIP) */
 

 
 
 global cod_historical_sizeclass "${source_data}/mrip/cod_size_class20145_20154.dta"  
 global haddock_historical_sizeclass "${source_data}/mrip/haddock_size_class20145_20154.dta" 







/*global for the cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class "${source_data}/mrip/cod_catch_class20145_20154.dta" 
global haddock_catch_class "${source_data}/mrip/haddock_catch_class20145_20154.dta" 

 /*global for the cod and haddock historical age structures  */




  

  
 global cod_naa "${source_data}/cod agepro/cod_naa_2015updatem2.dta"
 global hadd_naa "${source_data}/haddock agepro/haddock_naa_2015update.dta"

 /*global for the cod and haddock initial NAA - PDB/AGEPRO, possibly projected 1 year forward.
*/
 
global hadd_naa_start "${source_data}/haddock agepro/2015_HAD_GM_MOD_ASAP_BASE_MCMC.dta"
global cod_naa_start "${source_data}/cod agepro/2015_COD_BOTH.dta "


global hadd_naa_sort "${working_data}/haddock_beginning_sorted2015.dta"
global cod_naa_sort "${working_data}/cod_beginning_sorted2015.dta"



global haddock_recruits_file "${source_data}/haddock agepro/haddock_recruits_2015base.dta"
global cod_recruits_file "${source_data}/cod agepro/cod_recruits_2015average.dta"



/* Hinge value for Cod recruitment (converted to pounds)*/
global cod_SSBHinge=6300*$mt_to_kilo*$kilo_to_lbs


 
/* Mortality rate of the released fish (UNIT FREE) for cod */
global mortality_release=0.15

/* Mortality rate of the released haddock is a vector (following Mandelman (2017).  We'll store the vector here, then look up the value inside the loop */
global haddock_mortality_release=0.50

mata: mandelman_mortality_large=(J(1,6,.113), J(1,6,.459)) 
mata: mandelman_mortality_small=(J(1,6,.321), J(1,6,.742))




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



/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/
use "$haddock_recruits_file", clear 
/* haddock_recruits_files should point to. use */

mkmat recruit cdf, matrix(hrecruit_cdf)
scalar z1=rowsof(hrecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/

levelsof cdf, local(locrecruit_cdf) separate(,)
global hglobrecruit_cdf `locrecruit_cdf'
/***************************END Haddock SETUP ******************************/
/***************************** ******************************/






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


/*


 */
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




/********************THIS BIT READS IN THE RECRUITMENT FILE, MAKES A CDF, and sets up a local for the `irecode' function which is used in the recruitment sections******************************/


use "${cod_recruits_file}", clear
mkmat recruit cdf, matrix(crecruit_cdf)
scalar c1=rowsof(crecruit_cdf)-1
/* The scalar must be ''offset'' by 1 unit to account for the addition of the 0 recruit with probability 0 addition to the cdf*/

levelsof cdf, local(locrecruit_cdf) separate(,)
global cglobrecruit_cdf `locrecruit_cdf'
/***************************END COD SETUP ******************************/





