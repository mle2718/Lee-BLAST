/* This files fills in zeros for age-length combinations with missing values.  It smooths
	the Age-length key using bandwidth =0.3 
	fills in the missing age8 year class with the average of the age6 and 8 counts
	
	computes:
	1.  The age-length mapping cod_smoooth_age-to-length.dta
	2.  The length-age mapping cod_smoooth_length-to-age.dta

NOTE: USE DOUBLE PRECISION IN THE CALCULATE OF PROBABILITIES TO REDUCE ROUNDING ERRORS.
*/


use $codalkey, clear
destring, replace

foreach var of varlist * {
	capture confirm string variable `var'
		if !_rc{
			egen `var'2 = sieve(`var'), keep(n)
			destring `var'2, replace
			drop `var'
			rename `var'2 `var'
		}
	}
		
/* here is a comment
Convert CM to inches and then then round DOWN to nearest inch.  This is consistent with LNGCAT from the recreational catches 
 */
drop if age==0
replace length=floor(length*$cm_to_inch) 

 /* THIS STEP CONVERTS THINGS FROM METRIC TO IMPERIAL
I use FLOOR to be consistent with the way that the length categories are constructed in the recreational data
 */
replace age=9 if age>=9

collapse (sum) count, by(age length)
/* this step fills in any missing age and length classes with missing values */
reshape wide count, i(age) j(length)
tsset age
tsfill, full

reshape long
reshape wide count, i(length) j(age)
tsset length
tsfill, full

reshape long
reshape wide count, i(length) j(age)



/* This step fills in any missing values with zeros and then does a separate lowess smoother for each age class */
foreach var of varlist count*{
	replace `var'=0 if `var'==.
	lowess `var' length, adjust bwidth(.5) gen(s`var') nograph
	replace s`var'=0 if s`var'<=0
}

/*
drop count*

forvalues i=1/9{
	rename scount`i' count`i'
}

*/

reshape long count scount, i(length) j(age)
order age length
sort age length 

notes: this is the counts which have been 'smoothed'.  Just go ahead and run the normal Age-Length processing on this dataset to get smoothed probabilities.
notes: count has been smoothed in this dataset.

save ${working_data}/cod_al_keysmooth.dta, replace

/* here we calculate the smooth_age_to_length.dta */
egen double tc=total(count), by(age)
gen double prob=count/tc

keep age length prob
replace prob=0 if prob<=9e-11


/* there's a little change of variable names here 
don't change the order of the next three lines*/

rename length t
rename prob length
reshape wide length, i(age) j(t)
/* round off errors in prob lead to the sum of probablities =1 +/- 5e-12.  This should be good enough*/
save ${working_data}/cod_smooth_age_length.dta, replace
putmata cod_smooth_age_length=(length*), replace





