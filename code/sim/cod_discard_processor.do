/* DISCARD PROCESSOR  - this file takes the "cod_discard_saverXXXX.dta" file and computes discards per simulation (replicate-and "policy" , year combination) */

/* keep only fishing year data */
keep if wave>=3
/* add a check for the 2nd and beyond fishing year? */


collapse (sum) released, by(length replicate fishing_year)

drop if length==.
/* apply L-W equation */

