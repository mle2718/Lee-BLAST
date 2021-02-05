
cd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO"

/* plot stock size and catchability */
use "cod_rec_selectivity.dta", clear
label F_rec "Cod Selectivity (q)"
label var stocksize "Cod Numbers at Length"
label var length "Length (inches)"
replace stocksize=stocksize/3
twoway (line stocksize length, ytick(#2)) (line F_rec length, lpattern(dash) yaxis(2)), ylabel(#3) legend(order(1 "Cod Mean Numbers-at-Length 2007-2009" 2 "Recreational Cod Selectivity") row(2)) ytitle("Cod Selectivity (q)", axis(2))
graph save "cod_stock_and_select", replace
graph export "cod_stock_and_select.tif", replace as(tif)




/* plot stock size and catchability */

use "hadd_rec_selectivity.dta", clear
label F_rec "Haddock Selectivity (q)"
label var stocksize "Haddock Numbers at Length"
label var length "Length (inches)"

replace stocksize=stocksize/3

twoway (line stocksize length) (line F_rec length, lpattern(dash) yaxis(2)), ylabel(#3) legend(order(1 "Haddock Mean Numbers-at-Length 2007-2009" 2 "Recreational Haddock Selectivity") row(2)) ytitle("Haddock Selectivity (q)", axis(2))

graph save "hadd_stock_and_select", replace
graph export "hadd_stock_and_select.tif", replace as(tif)





/*Use the Median NAA from 2013  */

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/source_data/cod agepro/cod_beginning.dta", clear
foreach var of varlist age1-age9{
	rename `var' cyr1_`var'
}
keep if year==2013
collapse (median) cyr1_age1-cyr1_age9

notes: this contains the median numbers at age of cod
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

merge 1:1 length using "cod_rec_selectivity.dta"


replace count=0 if count==.
gen double adj_count=count*nFc 
assert adj_count<=count

tempvar tcount 
sort length
egen double `tcount'=total(adj_count)
gen double pmfcount=adj_count/`tcount'

tsset length
label var count "Median Projected Cod Numbers at Length 2013" 
label var pmfcount "Probability Distribution of Recreational Catch-at-Length" 


twoway (tsline count) (tsline pmfcount, yaxis(2)), ytitle("Cod Numbers at Length", axis(1)) ytitle("Probability ", axis(2)) legend(row(2))
graph save "cod_2013_and_pdf", replace
graph export "cod_2013_and_pdf.tif", replace as(tif)


/* repeat for Haddock */


/*Use the Median NAA from 2013  */

use"/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/source_data/haddock agepro/hadd_agepro_2014/haddock_beginning_dataset.dta", clear
keep if year==2013
drop repl year
foreach var of varlist age1-age9{
	rename `var' hyr1_`var'
}
collapse (median) hyr1_age1-hyr1_age9
notes: this contains the median numbers at age of haddock for the current replicate
keep hyr1_age*
xpose, clear varname
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

/* this section takes the age structure and converts it into numbers at length*/



merge 1:1 length using "hadd_rec_selectivity.dta"


replace count=0 if count==.
gen double adj_count=count*nFh 
assert adj_count<=count

tempvar tcount 
sort length
egen double `tcount'=total(adj_count)
gen double pmfcount=adj_count/`tcount'

tsset length
label var count "Median Projected Haddock Numbers at Length 2013" 
label var pmfcount "Probability Distribution of Recreational Catch-at-Length" 


twoway (tsline count) (tsline pmfcount, yaxis(2)), ytitle("Haddock Numbers at Length", axis(1)) ytitle("Probability ", axis(2)) legend(row(2))
graph save "haddock_2013_and_pdf", replace
graph export "haddock_2013_and_pdf.tif", replace as(tif)




/* This section just plots cod recreational catch */

use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/cod_rec_selectivity.dta"
label var length "Length (in)"
label var rec_catch "Raw Recreational Catch"
label var myrec "Smoothed Recreational Catch"
twoway (tsline rec_catch) (tsline myrec)
graph save "cod_rec_catch", replace
graph export "cod_rec_catch.tif", replace as(tif)





use "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO/hadd_rec_selectivity.dta"
label var length "Length (in)"
label var rec_catch "Raw Recreational Catch"
label var myrec "Smoothed Recreational Catch"
twoway (tsline rec_catch) (tsline myrec)
graph save "hadd_rec_catch", replace
graph export "hadd_rec_catch.tif", replace as(tif)
