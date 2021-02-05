
/* This part gets iterated over */
/* multiply the numbers-at-length by the selectivity 
manipulate this a little bit and compute the pdf for the wave */

/* Dependencies globals: codmin, codmax, haddmin, haddmax, wave_of_cy
mata:  hadd_selectivity_by_wave, cod_selectivity_by_wave
*/

display "checkpoint sfl99"
use ${working_data}/cod_length_count.dta, clear
replace length=$codmin if length<=$codmin
replace length=$codmax if length>=$codmax
collapse (sum) count*, by(length)

mata: cs_index=cod_selectivity_by_month[.,1]
mata: cs2=cod_selectivity_by_month[|1,2\ .,.  |]

/*You need to pull out the $wave_of_cy plus 1 entry from "cod_selectivity_by_month" mata matrix */


getmata (nFc*)=cs2, id(length=cs_index)
keep length count nFc$wave_of_cy

keep if length>=$codmin & length<=$codmax

replace count=0 if count==.
gen double adj_count=count*nFc
assert adj_count<=count

tempvar tcount
sort length
egen double `tcount'=total(adj_count)
gen double codpdf=adj_count/`tcount'
replace codpdf=0 if codpdf==.
sort length

/*  THIS matrix will have the selectivity by wave in it */
putmata matacodlength_pdf=(length codpdf), replace
global mycl=_N-1 






use ${working_data}/haddock_length_count.dta, clear
replace length=$haddmin if length<=$haddmin
replace length=$haddmax if length>=$haddmax
collapse (sum) count*, by(length)

mata: hs_index=hadd_selectivity_by_month[.,1]
mata: hs2=hadd_selectivity_by_month[|1,2\ .,.  |]

*getmata (lengthh nFh1 nFh2 nFh3 nFh4 nFh5 nFh6)=hadd_selectivity_by_wave, id(length=hs_index)
getmata (nFh*)=hs2, id(length=hs_index)
keep length count nFh$wave_of_cy

keep if length>=$haddmin & length<=$haddmax

replace count=0 if count==.
gen double adj_count=count*nFh
assert adj_count<=count

tempvar tcount
sort length
egen double `tcount'=total(adj_count)
gen double haddpdf=adj_count/`tcount'
replace haddpdf=0 if haddpdf==.
sort length

/*  THIS matrix will have the selectivity by wave in it */
putmata matahaddlength_pdf=(length haddpdf), replace
global mycl=_N-1 
display "setup_fish_length_draws.do done"
