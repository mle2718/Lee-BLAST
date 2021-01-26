/* BUILD THE ROLLING LENGTH--> AGE KEYS FOR COD AND HADDOCK */

/* Construct the length--> age mapping based on actual length structure */
/* read in the current age structure of cod */

/* Construct the Wave-specific length-to-age key
This is saved in  file cod_rolling_length_to_age_key.dta */

/* This is the old way: it reads in beginning age structure (before commercial or natural mortality)
use "cod_age_count.dta", replace */

/* This is the new way, it grabs the age structure after comm/nat mortality */

clear
getmata (age*)=cod_end_of_cm

keep *age*
/* keep cyr1_age* */
xpose, clear varname
rename v1 j1count
gen age=substr(_varname, -1,.)
destring, replace
drop _varname
order age j1count
sort age
do "${code_dir}/sim/cod_age_length_auxiliary_file.do"


/* This is the old way: it reads in beginning age structure (before commercial or natural mortality)
use "haddock_age_count.dta", clear
keep *age*
 keep hyr1_age*  */
/* This is the new way, it grabs the age structure after comm/nat mortality */
clear
getmata (age*)=haddock_end_of_period

keep *age*

xpose, clear varname
rename v1 j1count
gen age=substr(_varname, -1,.)
drop _varname
destring, replace
order age j1count
sort age
/* Construct the YEAR_SPECIFIC length-to-age key
This is saved in  file haddock_rolling_length_to_age_key.dta */

do "${code_dir}/sim/hadd_age_length_auxiliary_file.do"
