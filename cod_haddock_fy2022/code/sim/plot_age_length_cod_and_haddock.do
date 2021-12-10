
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/"
use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/cod_al_key.dta", clear
destring, replace
scalar cm_to_inch=0.39370787
foreach var of varlist * {
	capture confirm string variable `var'
		if !_rc{
			egen `var'2 = sieve(`var'), keep(n)
			destring `var'2, replace
			drop `var'
			rename `var'2 `var'
		}
	}
		
/* here is a comment */
drop if age==0
replace length=round(length*cm_to_inch) 
 /* THIS STEP CONVERTS THINGS FROM METRIC TO IMPERIAL */
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
	lowess `var' length, adjust bwidth(.3) gen(s`var') nograph
	replace s`var'=0 if s`var'<=0
}


reshape long count scount, i(length) j(age)
order age length
sort age length 

notes: this is the counts which have been 'smoothed'.  Just go ahead and run the normal Age-Length processing on this dataset to get smoothed probabilities.
notes: count has been smoothed in this dataset.

xtset age length
xtset age length
label var age "age"
label var length "length (inches)"
label var count "raw count"
label var scount "smoothed count"
xtline count scount, tlabel(#5)  ylabel(#3) lpattern(solid dash)

graph save "cod_raw_graph", replace
graph export "cod_raw_graph.tif", replace as(tif)

reshape long
egen double rtc=total(count), by(age)
gen double rprob=count/rtc

replace rprob=0 if rprob<=9e-11

egen double stc=total(scount), by(age)
gen double sprob=scount/stc

replace sprob=0 if sprob<=9e-11
label var rprob "Raw Probability"
label var sprob "Smoothed Probability"

xtline rprob sprob, tlabel(#5)  ylabel(#3) lpattern(solid dash)
graph save "cod_prob_graph", replace
graph export "cod_prob_graph.tif", replace as(tif)




















use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock/haddock_al_key9max.dta", clear
destring, replace
scalar cm_to_inch=0.39370787
foreach var of varlist * {
	capture confirm string variable `var'
		if !_rc{
			egen `var'2 = sieve(`var'), keep(n)
			destring `var'2, replace
			drop `var'
			rename `var'2 `var'
		}
	}
		
/* here is a comment */
drop if age==0
replace length=round(length*cm_to_inch) 
 /* THIS STEP CONVERTS THINGS FROM METRIC TO IMPERIAL */
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
	lowess `var' length, adjust bwidth(.3) gen(s`var') nograph
	replace s`var'=0 if s`var'<=0
}


reshape long count scount, i(length) j(age)
order age length
sort age length 

notes: this is the counts which have been 'smoothed'.  Just go ahead and run the normal Age-Length processing on this dataset to get smoothed probabilities.
notes: count has been smoothed in this dataset.

xtset age length
xtset age length
label var age "age"
label var length "length (inches)"
label var count "raw count"
label var scount "smoothed count"
xtline count scount, tlabel(#5) ylabel(#3) lpattern(solid dash)

graph save "hadd_raw_graph", replace
graph export "hadd_raw_graph.tif", replace as(tif)

reshape long
egen double rtc=total(count), by(age)
gen double rprob=count/rtc

replace rprob=0 if rprob<=9e-11

egen double stc=total(scount), by(age)
gen double sprob=scount/stc

replace sprob=0 if sprob<=9e-11
label var rprob "Raw Probability"
label var sprob "Smoothed Probability"

xtline rprob sprob, tlabel(#5) ylabel(#3) lpattern(solid dash)
graph save "hadd_prob_graph", replace
graph export "hadd_prob_graph.tif", replace as(tif)








