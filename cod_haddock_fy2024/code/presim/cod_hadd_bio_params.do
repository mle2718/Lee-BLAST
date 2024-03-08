/* this is just a storage do file for the biological parameters for both species */


 
/* Here are some parameters */
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787


/* min and max sizes of cod and haddock in inches */
global codmin=4
global codmax=47
global haddmin=4
global haddmax=28

/* max age class for cod and haddock */

global cmax_age 9
global hmax_age 9

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

 
 




/*global for the monthly cod and haddock catch-at-length distributions (MRIP) */
global cod_historical_sizeclass "${mrip_source_data}/cod_size_class2023.dta"  
global haddock_historical_sizeclass "${mrip_source_data}/haddock_size_class2023.dta" 
/***
/*global for the ANNUAL cod and haddock catch-class distributions (MRIP)*/
global cod_catch_class "${mrip_source_data}/cod_catch_classANNUAL2023.dta" 
global haddock_catch_class "${mrip_source_data}/haddock_catch_classANNUAL2023.dta" 

******************************/


/*global for the OPEN and CLOSED split for cod catch-at-length distributions (MRIP

 global cod_historical_sizeclass "${mrip_source_data}/cod_size_class_OPEN_SPLIT2023.dta"  
  */
 /* If you want to use ANNUAL length-frequency data uncomment this 
 *global cod_historical_sizeclass "${mrip_source_data}/cod_size_class_ANNUAL2023.dta"  
 global haddock_historical_sizeclass "${mrip_source_data}/haddock_size_class_ANNUAL2023.dta" 
 */
 /* If you want to use monthly catch-class data uncomment this */

global cod_catch_class "${mrip_source_data}/cod_catch_class2023.dta" 
global haddock_catch_class "${mrip_source_data}/haddock_catch_class2023.dta" 







/* This should contain the historical time series of NAA. There should be 1 observation per year */

global cod_naa "${source_data}/cod agepro/historical_and_mean_projected_Cod_NAA.dta"
global hadd_naa "${source_data}/haddock agepro/historical_and_mean_projected_Haddock_NAA.dta"


/* this is a dataset that has the output of the AGEPRO in it. I don't think  i always use this.*/ 
global hadd_naa_start "${source_data}/haddock agepro/NAA_GOM_HADDOCK_2022_FMSY.dta"
global cod_naa_start "${source_data}/cod agepro/NAA_GOM_COD_2021_UPDATE_BOTH.dta"




global hadd_naa_sort "${source_data}/haddock agepro/haddock_beginning_sorted2023.dta"
global cod_naa_sort "${source_data}/cod agepro/cod_beginning_sorted2023.dta"


global haddock_recruits_file "${source_data}/haddock agepro/haddock_recruits_2023base.dta"
global cod_recruits_file "${source_data}/cod agepro/cod_recruits_2023both.dta"



/* Hinge value for Cod recruitment (converted to pounds) 2019 op update*/
global cod_SSBHinge=7900*$mt_to_kilo*$kilo_to_lbs


 
/* Mortality rate of the released fish (UNIT FREE) for cod */
global mortality_release=0.15

/* Mortality rate of the released haddock is a vector (following Mandelman (2017).  We'll store the vector here, then look up the value inside the loop */
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
global hM=$hMyr/$months


/* 
selectivity  -- at least one of the columns here must be 1*/
mata:

haddock_maturity=(0.051,  0.324,  0.811,  0.975,  0.997,  1, 1, 1,1  )  
haddock_age_selectivity=(0.003, 0.051,  0.182,  0.34 , 0.531 , 0.687 , 0.869 , 1.000 , 0.794  )
haddock_catch_weights= (0.213 , 0.446,  0.638,  0.873,  1.158, 1.425,  1.611,  1.818 , 2.25  )
haddock_midyear_weights= haddock_catch_weights
haddock_jan1_weights=(0.127 , 0.322, 0.552, 0.781, 1.061, 1.33 , 1.537 , 1.737,  2.25)

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
/* or use haddock_recruits_2015constrain.dta */

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
global cssb_floor=floor(($cMp1*$periods_per_year)/2)
global cssb_ceil=ceil(($cMp1*$periods_per_year)/2)

/* total natural mortality */
global M4=0.4
global M2=0.2

global cMyr=$M2
global cM=$cMyr/$months


/*


 */
mata:

/* selectivity  -- at least one of these columns must be 1*/
cod_age_selectivity_base=(0.013,  0.066,  0.271 , 0.663 , 0.912 , 0.982,  0.997 , 1 , 1) /*from 2019 OP UP */
cod_age_selectivity_mramp=(0.009 , 0.051,  0.241 , 0.651 , 0.917 , 0.985 , 0.997,  1 , 1  ) /*from 2019 OP UP */

cod_age_selectivity=(cod_age_selectivity_base+cod_age_selectivity_mramp)/2  /* you've set this to the average of the two */

/* cod (c) January weights(cj1w) , Catch weights (ccw), midyear weights (cmyw), and spawning weights (cssbw), discard weights (cdw), and fraction discarded (cfdis)*/
cod_jan1_weights=(0.057,  0.365,  0.908 , 1.662 , 2.426 , 3.307 , 4.09 , 5.928 , 10.375 ) /*from 2019 OP UP */
cod_midyear_weights=(0.225,  0.677 , 1.342 , 2.144 , 2.773 , 3.729 , 4.64 , 7.323 , 10.375  ) /*from 2019 OP UP */
cod_catch_weights= (0.229 , 0.693 , 1.43 , 2.48 , 3.341 , 4.534 , 5.406 , 7.821 , 10.479  ) /*from 2019 OP UP */
cod_ssb_weights=cod_jan1_weights /*from 2019 OP UP */
cod_discard_weights=cod_catch_weights /*from 2019 OP UP */
cod_discard_fraction=(0, 0, 0, 0, 0, 0, 0, 0, 0) /*from 2019 OP UP */
cod_maturity=(0.087 , 0.318 , 0.697 , 0.919 , 0.982 , 0.996,  0.999 , 1.000,  1.000  ) /*from 2015 OP UP . No change in 2019 */


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





