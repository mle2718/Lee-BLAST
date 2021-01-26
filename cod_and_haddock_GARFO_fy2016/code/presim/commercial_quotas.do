/* Specify commercial quotas -- */

/* Maximum iterations and maximum F for the commercial fishery (UNIT FREE)*/
global maxiterations=30
global maxfishingmortality=25



global cod2011a=4462
global cod2012a=2211
global cod2013a=741
global cod2014a=663

/* note, this reflect our information back when we were doing the simulations for FY2016 */
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






/* 
/* Break the annual fishing into a proportion by waves 
Compute the POUNDS caught by the commercial fishery in each wave */
clear
do "${code_dir}/presim/commercial_helper.do"
do "${code_dir}/presim/commercial_monthly_helper.do" */

 use "${source_data}/cfdbs/haddock_timing.dta", clear
 putmata haddock_commercial_waves=(wave frac), replace

  use  "${source_data}/cfdbs/cod_timing.dta", clear
 putmata cod_commercial_waves=(wave frac), replace







/* I think I can offload this to the "commercial_quotas.do" file.*/
/* I have concatenated catch from 2011 through 2017 (quota1 to quota7) for cod and haddock.  To get things synched up, I've padded the vectors with two zeros corresponding to the first 2 waves of 2011.  
The commercial catch vectors start on Jan 1, 2011 and end on April 30, 2018 (end of FY2017)*/

/**/
mata: cod_commercial_catch=(0 \ 0 \ $cod_quota1*cod_commercial_waves[.,2] \ $cod_quota2*cod_commercial_waves[.,2] \ $cod_quota3*cod_commercial_waves[.,2]\ $cod_quota4*cod_commercial_waves[.,2]\ $cod_quota5*cod_commercial_waves[.,2] \ $cod_quota6*cod_commercial_waves[.,2])
mata: haddock_commercial_catch=(0 \ 0 \  $haddock_quota1*haddock_commercial_waves[.,2] \ $haddock_quota2*haddock_commercial_waves[.,2] \ $haddock_quota3*haddock_commercial_waves[.,2]\ $haddock_quota4*haddock_commercial_waves[.,2]\ $haddock_quota5*haddock_commercial_waves[.,2] \ $haddock_quota6*haddock_commercial_waves[.,2])

mata: cod_commercial_catch=cod_commercial_catch[|$comm_wave_starter \.|] 
mata: haddock_commercial_catch=haddock_commercial_catch[|$comm_wave_starter \.|]

clear
