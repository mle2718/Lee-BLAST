/* THIS AUXILIARY DO FILE IS A small block of code which must be repeated.  So it has been moved out of the main file to make it more compact */

/* CHANGELOG DEC 5, 2011 
1.04 -- This file is agnostic to Imperial or Metric
1.03 -- This has been forked to aux_wtp
1.02 -- The probability statement has been rewritten again to reflect the square root term in the utility function.  
1.01 -- The Probability statement in the original is likely to be wrong.  I've rewritten it and commented out the code which I believe is incorrect */

/* The WTP function must be replace with the correct functional form which accounts for non-linearity
quietly replace WTP=mwtp_ckeep*ckeep+mwtp_crel*crel+mwtp_hkeep*hkeep+mwtp_hrel*hrel 
*/
tempname ckval crval hkval hrval


scalar `ckval'=-$pi_cod_keep/(2*$pi_cost)
scalar `crval'=-$pi_cod_release/(2*$pi_cost)
scalar `hkval'=-$pi_hadd_keep/(2*$pi_cost)
scalar `hrval'=-$pi_hadd_release/(2*$pi_cost)

/* A trip with zero catch and zero release is assumed to have WTP of zero */
/* The mWTP formula is:
kept cod: pi_cod_keep/2pi_cost*1/sqrt(#of kept cod)
released cod: pi_cod_release/2pi_cost*1/sqrt(#of released cod)
kept haddock: pi_hadd_keep/2pi_cost*1/sqrt(#of kept hadd)
released haddock:pi_hadd_release/2pi_cost*1/sqrt(#of released hadd)
 Therefore, the total WTP is calculated by integrating (summing) the marginal WTPs from 0 to the total fish kept
*/

replace WTP=0


quietly summ ckeep
global b=r(max)

forvalues val=1/$b{
	quietly replace WTP=WTP+`ckval'*(1/sqrt(`val')) if ckeep>=`val'
}

quietly summ crel
global b=r(max)


forvalues val=1/$b{
	quietly replace WTP=WTP+`crval'*(1/sqrt(`val')) if crel>=`val'
}

quietly summ hkeep
global b=r(max)


forvalues val=1/$b{
	quietly replace WTP=WTP+`hkval'*(1/sqrt(`val')) if hkeep>=`val'
}

quietly summ hrel
global b=r(max)
forvalues val=1/$b{
	quietly replace WTP=WTP+`hrval'*(1/sqrt(`val')) if hrel>=`val'
}
macro drop b
/*
quietly replace WTPs=WTP*shore 
quietly replace WTPb=WTP*boat 
quietly replace WTPp=WTP*party 
quietly replace WTPc=WTP*charter 


foreach var of varlist WTP WTPs WTPb WTPp WTPc{
	assert `var' ~=.
}
*/

tempvar V
gen `V'=$pi_cod_keep*sqrt(ckeep)+$pi_cod_release*sqrt(crel)+ $pi_hadd_keep*sqrt(hkeep) + $pi_hadd_release*sqrt(hrel)
gen utilActual=-ln(1+exp(`V'))/$pi_cost

replace `V'=$pi_cod_keep*sqrt(eckeep)+$pi_cod_release*sqrt(ecrel)+ $pi_hadd_keep*sqrt(ehkeep) + $pi_hadd_release*sqrt(ehrel)
gen utilExpected=-ln(1+exp(`V'))/$pi_cost


disp "aux WTP done"
