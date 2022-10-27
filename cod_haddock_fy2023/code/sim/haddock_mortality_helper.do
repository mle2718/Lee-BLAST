/* I need to pick an Fh such that the total weight of fish is equal to the sub ACL AND the selectivity is correct */
/* See pages 2-5 and 53 of the AgePro manual */
/* Commercial Mortality */
local imax=$hmax_age-1
mata:

hac=cols(haddock_age_selectivity)
haddock_initial_weight_period= haddock_initial_counts:*haddock_catch_weights

nhm=J(1,hac,$hM)
ones=J(1, hac,1)

iter=0
/* AGEPRO uses Newtons method to compute F if there is an ACL/TAC.
It is easier to code up the secant method as a derivative free method.
This method requires 2 starting points but this is not so bad. Approximate the derivative by calculating 2 values of the objective function. */

/* See Miranda and Fackler, Page 36-37 for details of the secant method 
	
   The Definitions of Landings, Catch, F, and M are taken from the AgePro Manual (Brodziak)

I would to find F, such that L(F)-Q=0 [Rootfinding ].  Alternatively F=F-[L(F)-Q].

in M&F notation: 
f=L(F)-Q
x=Fishing mortality
*/


/*initial values */
Fh0= 0
Fh1=.0001

/* The code is a little sensitive to starting values it might be a good idea to start at small numbers and approach from one side.  Also terminate at a maximum. */

iter=0
do {
	mcca = (Fh0*haddock_age_selectivity) :/ (Fh0*haddock_age_selectivity:+nhm )
	mccb =  (ones - exp( -nhm- Fh0*haddock_age_selectivity)) :* haddock_initial_counts
	my_haddock_catch_counts0= mcca :*mccb
	my_haddock_catch_weights0 = my_haddock_catch_counts0:*haddock_catch_weights
	my_haddock_landings0=(my_haddock_catch_counts0:*haddock_catch_weights):*(ones-haddock_discard_fraction)

	mccc = (Fh1*haddock_age_selectivity) :/ (Fh1*haddock_age_selectivity+nhm )
	mccd =  (ones - exp( -nhm- Fh1*haddock_age_selectivity)) :* haddock_initial_counts
	my_haddock_catch_counts1= mccc :*mccd
	my_haddock_catch_weights1 = my_haddock_catch_counts1:*haddock_catch_weights
	my_haddock_landings1=(my_haddock_catch_counts1:*haddock_catch_weights):*(ones-haddock_discard_fraction)

	fprime_upper = (rowsum(my_haddock_landings1)-st_numscalar("haddock_quota"))-(rowsum(my_haddock_landings0)-st_numscalar("haddock_quota"))
	fprime_lower=Fh1-Fh0

	fprime=fprime_upper:/fprime_lower
	Fh2=Fh1-fprime^-1*(rowsum(my_haddock_landings1)-st_numscalar("haddock_quota"))

	delta=Fh2-Fh1

	Fh0=Fh1
	Fh1=Fh2
	iter=iter+1
}while (abs(delta>=1e-6) & iter<=$maxfiter & Fh2~=.)

Fhstatus=1

/* Infeasible F: AGEPRO uses FMax=25.   
if F>FMax then set F=FMax and recompute my_haddock_landings1 */

if (Fh1>=$FMax) {
	Fh1=$FMax
	mccc = (Fh1*haddock_age_selectivity) :/ (Fh1*haddock_age_selectivity+nhm )
	mccd =  (ones - exp( -nhm- Fh1*haddock_age_selectivity)) :* haddock_initial_counts
	my_haddock_catch_counts1= mccc :*mccd
	my_haddock_catch_weights1 = my_haddock_catch_counts1:*haddock_catch_weights
	my_haddock_landings1=(my_haddock_catch_counts1:*haddock_catch_weights):*(ones-haddock_discard_fraction)
	Fhstatus=2
}

/* Negative F?
Set F=0
 */

if (Fh1<0) {
	Fh1=0

	mccc = (Fh1*haddock_age_selectivity) :/ (Fh1*haddock_age_selectivity+nhm )
	mccd =  (ones - exp( -nhm- Fh1*haddock_age_selectivity)) :* haddock_initial_counts
	my_haddock_catch_counts1= mccc :*mccd
	my_haddock_catch_weights1 = my_haddock_catch_counts1:*haddock_catch_weights
	my_haddock_landings1=(my_haddock_catch_counts1:*haddock_catch_weights):*(ones-haddock_discard_fraction)
	Fhstatus=3
}

/* Compute age structures of natural mortality, catch (done), landings(done) and remaining fish */
mcce = (nhm):/ (Fh1*haddock_age_selectivity+nhm )
haddock_nat_mort_counts=mcce:*mccd

haddock_landing_counts=my_haddock_catch_counts1:*(ones-haddock_discard_fraction)
haddock_discard_counts=my_haddock_catch_counts1:*haddock_discard_fraction

haddock_end_of_period=haddock_initial_counts:-haddock_nat_mort_counts:-haddock_landing_counts:-$haddock_comm_discard_mortality*haddock_discard_counts

/*fix any negative age classes by moving them to adjacent age classes 
Although negative age classes should not be possible at this stage*/
iter2=0

do {
for(i=2;i<=`imax';i++){
	if (haddock_end_of_period[i]<0){
		haddock_end_of_period[i+1]=haddock_end_of_period[i+1]+.5*haddock_end_of_period[i]
		haddock_end_of_period[i-1]=haddock_end_of_period[i-1]+.5*haddock_end_of_period[i]
		haddock_end_of_period[i]=0
	}
}


	if (haddock_end_of_period[1]<0){
		haddock_end_of_period[2]=haddock_end_of_period[2]+haddock_end_of_period[1]
		haddock_end_of_period[1]=0
}
	if (haddock_end_of_period[$hmax_age]<0){
		haddock_end_of_period[$hmax_age-1]=haddock_end_of_period[$hmax_age-1]+haddock_end_of_period[$hmax_age]
		haddock_end_of_period[$hmax_age]=0
}
	iter2=iter2+1
}while (iter2<=6)
/* if the naa are still negative, they shoudl be pretty small, so set them to zero*/
for(i=1;i<=$hmax_age;i++){
	if (haddock_end_of_period[i]<0){
		haddock_end_of_period[i]=0
	}
}







haddock_landing_counts_wave$current_wave = haddock_landing_counts
haddock_discard_counts_wave$current_wave = haddock_discard_counts
haddock_end_of_period_wave$current_wave=haddock_end_of_period

haddock_landing_weight_wave$current_wave = haddock_landing_counts*haddock_catch_weights'
haddock_discard_weight_wave$current_wave = haddock_discard_counts*haddock_discard_weights'

st_numscalar("haddock_commercial_landings",haddock_landing_weight_wave$current_wave)
st_numscalar("haddock_commercial_discards",haddock_discard_weight_wave$current_wave)


mata drop my_haddock_catch_counts0 my_haddock_catch_counts1 my_haddock_catch_weights0 my_haddock_catch_weights1

st_numscalar("F_COMM_HADDOCK", Fh1)
st_numscalar("F_HADDOCK_STATUS", Fhstatus)


/*
SSBhaddock=(haddock_ssb_count:*haddock_maturity)*haddock_ssb_weights'
st_numscalar("HADDOCK_SSB", SSBhaddock)
*/


end
