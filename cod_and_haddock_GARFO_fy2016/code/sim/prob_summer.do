/* this files is agnostic to Metric or Imperial */
/* note replace the first line with whatever you want the decision rule to be */
replace trip_occur = cond(prob>=$cutoff_prob, 1, 0) 

tempvar tcod thaddock dcod dhaddock

gen `tcod'=0
quietly replace `tcod'=cweight if trip_occur==1
gen `thaddock'=0
quietly replace `thaddock'=hweight if trip_occur==1
replace running_cod=sum(`tcod')
replace running_hadd=sum(`thaddock')

gen `dcod'=0
quietly replace `dcod'=c_disc_weight if trip_occur==1
gen `dhaddock'=0
quietly replace `dhaddock'=h_disc_weight if trip_occur==1
replace running_disc_cod=sum(`dcod')
replace running_disc_hadd=sum(`dhaddock')

