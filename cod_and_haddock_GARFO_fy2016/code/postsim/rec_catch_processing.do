browse
local rec_out "recreational_catches2016w25opend.dta"
use `rec_out', clear

/* get rid of waves 1-2 */

drop if wave<=2

drop if wave>=9

tab cbag hbag
tab cmin hmin
tab wave cbag
tab wave cmin

tab wave hbag
tab wave hmin

foreach var of varlist cod_weight_kept cod_weight_discard cod_discard_dead_weight haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight{
replace `var'=`var'/2204
}


gen cod_removals=cod_weight_kept+cod_discard_dead
gen haddock_removals=haddock_weight_kept+haddock_discard_dead_weight
collapse (sum) total_trips-haddock_discard_dead_weight cod_removals haddock_removals, by(replicate scenario )


rm temporary.csv

levelsof scenario, local(myl)
foreach ll of local myl {
	quietly estpost summarize total_trips cod_removals haddock_removals cod_weight_kept cod_weight_discard  haddock_weight_kept haddock_weight_discard if scenario==`ll', detail
	disp `ll'
	esttab . using temporary.csv, cells("p50") noobs csv append plain
} 

bysort scenario: count if cod_removals<=157
bysort scenario: count if haddock_removals<=928
