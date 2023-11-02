/* THIS AUXILIARY DO FILE IS A small block of code which must be repeated.  So it has been moved out of the main file to make it more compact */
/* The 'global' p's are mWTPs for particular attributes and generated from the RUM*/



quietly replace q1=sqrt(eckeep)*$pi_cod_keep
quietly replace q2=sqrt(ecrel)*$pi_cod_release
quietly replace q3=sqrt(ehkeep)*$pi_hadd_keep
quietly replace q4=sqrt(ehrel)*$pi_hadd_release
quietly replace q5=tripcost*$pi_cost
quietly replace q6=forhire*(triplength*$pi_trip_length + triplength^2*$pi_trip_length2)

tempvar temp_prob
quietly gen `temp_prob'=1/(1+exp(-(q1+q2+q3+q4+q5+q6)))
quietly replace prob=prob+ `temp_prob'*$scale_factor


tempvar V

gen `V'=$pi_cod_keep*sqrt(eckeep)+$pi_cod_release*sqrt(ecrel)+ $pi_hadd_keep*sqrt(ehkeep) + $pi_hadd_release*sqrt(ehrel)
replace `V'=-ln(1+exp(`V'))/$pi_cost
replace utilExpected=utilExpected+`V'*$scale_factor

disp "Aux prob done"
