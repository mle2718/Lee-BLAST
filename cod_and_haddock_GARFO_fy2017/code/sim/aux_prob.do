/* THIS AUXILIARY DO FILE IS A small block of code which must be repeated.  So it has been moved out of the main file to make it more compact */

/* CHANGELOG DEC 5, 2011 
1.04 -- This file is agnostic to Imperial or Metric
1.03 -- This has been forked to aux_prob
1.02 -- The probability statement has been rewritten again to reflect the square root term in the utility function.  
1.01 -- The Probability statement in the original is likely to be wrong.  I've rewritten it and commented out the code which I believe is incorrect */

/* The original q6 and prob were: 
	gen q6=triplength*$ptleng
	gen prob=1/(1+exp(-(q1+q2+q3+q4+q5+q6+q6*triplength)))
I'm pretty sure that these are wrong 
1. TRIP LENGTH only appears in the `for hire' categories when calculating probability of trip occurring.
2. The quadratic computation was wrong. 
 
 */

/* The 'global' p's are mWTPs for particular attributes and generated from the RUM*/



quietly replace q1=sqrt(eckeep)*$pi_cod_keep
quietly replace q2=sqrt(ecrel)*$pi_cod_release
quietly replace q3=sqrt(ehkeep)*$pi_hadd_keep
quietly replace q4=sqrt(ehrel)*$pi_hadd_release
quietly replace q5=tripcost*$pi_cost
quietly replace q6=forhire*(triplength*$pi_trip_length + triplength^2*$pi_trip_length2)
quietly replace prob=1/(1+exp(-(q1+q2+q3+q4+q5+q6)))


/* 	We maintain the decision rule that a trip occurs if it has better than 50% chance of occurring.  
	Instead of  deleting trips which don't occur, I set up a dummy to flag those trips.*/
	
/* The WTP function must be replace with the correct functional form which accounts for non-linearity
quietly replace WTP=mwtp_ckeep*ckeep+mwtp_crel*crel+mwtp_hkeep*hkeep+mwtp_hrel*hrel 
*/

/*
foreach var of varlist q1 q2 q3 q4 q5 q6 prob {
	assert `var' ~=.
}





quietly replace q1=sqrt(ckeep)*$pi_cod_keep
quietly replace q2=sqrt(crel)*$pi_cod_release
quietly replace q3=sqrt(hkeep)*$pi_hadd_keep
quietly replace q4=sqrt(hrel)*$pi_hadd_release
quietly replace q5=tripcost*$pi_cost
quietly replace q6=forhire*(triplength*$pi_trip_length + triplength^2*$pi_trip_length2)
quietly replace probold=1/(1+exp(-(q1+q2+q3+q4+q5+q6)))
*/




disp "Aux prob done"
