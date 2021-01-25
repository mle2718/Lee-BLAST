/* weights to mt */

use `rec_catch', clear
foreach var of varlist cod_weight_kept cod_weight_discard cod_discard_dead_weigth haddock_weight_kept haddock_weight_discard haddock_discard_dead_weight{
	replace `var'=`var'/($global mt_to_kilo*$global kilo_to_lbs)
}

save `rec_catch', replace
