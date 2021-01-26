
local imax=$cmax_age-1

mata:
cac=cols(cod_age_selectivity)
cod_initial_weight= cod_initial_counts:*cod_catch_weights

ncm=J(1,cac,$cM)
ones=J(1, cac,1)

iter=0

/*initial values */
Fc0= 0
Fc1=.0001

/* The code is a little sensitive to starting values it might be a good idea to start at small numbers and approach from one side.  Also terminate at a maximum. */


/* Wrap a do , while  loop around this */
iter=0
do {
	mcca = (Fc0*cod_age_selectivity) :/ (Fc0*cod_age_selectivity:+ncm )
	mccb =  (ones - exp( -ncm- Fc0*cod_age_selectivity)) :* cod_initial_counts
	my_cod_catch_counts0= mcca :*mccb
	my_cod_catch_weights0 = my_cod_catch_counts0:*cod_catch_weights
	my_cod_landings0=(my_cod_catch_counts0:*cod_catch_weights):*(ones-cod_discard_fraction)

	mccc = (Fc1*cod_age_selectivity) :/ (Fc1*cod_age_selectivity+ncm )
	mccd =  (ones - exp( -ncm- Fc1*cod_age_selectivity)) :* cod_initial_counts
	my_cod_catch_counts1= mccc :*mccd
	my_cod_catch_weights1 = my_cod_catch_counts1:*cod_catch_weights
	my_cod_landings1=(my_cod_catch_counts1:*cod_catch_weights):*(ones-cod_discard_fraction)

	fprime_upper = (rowsum(my_cod_landings1)-st_numscalar("cod_quota"))-(rowsum(my_cod_landings0)-st_numscalar("cod_quota"))
	fprime_lower=Fc1-Fc0

	fprime=fprime_upper:/fprime_lower
	Fc2=Fc1-fprime^-1*(rowsum(my_cod_landings1)-st_numscalar("cod_quota"))

	delta=Fc2-Fc1

	Fc0=Fc1
	Fc1=Fc2
	iter=iter+1
}while (abs(delta>=1e-6) & iter<=$maxfiter & Fc2~=.)
Fcstatus=1


/* Infeasible F: AGEPRO uses FMax=25.   
if F>FMax then set F=FMax and recompute my_cod_landings1 */

if (Fc1>=$FMax) {
	Fc1=$FMax
	mccc = (Fc1*cod_age_selectivity) :/ (Fc1*cod_age_selectivity+ncm )
	mccd =  (ones - exp( -ncm- Fc1*cod_age_selectivity)) :* cod_initial_counts
	my_cod_catch_counts1= mccc :*mccd
	my_cod_catch_weights1 = my_cod_catch_counts1:*cod_catch_weights
	my_cod_landings1=(my_cod_catch_counts1:*cod_catch_weights):*(ones-cod_discard_fraction)
	Fcstatus=2
}

/* Negative F?
Set F=0
 */

if (Fc1<0) {
	Fc1=0

	mccc = (Fc1*cod_age_selectivity) :/ (Fc1*cod_age_selectivity+ncm )
	mccd =  (ones - exp( -ncm- Fc1*cod_age_selectivity)) :* cod_initial_counts
	my_cod_catch_counts1= mccc :*mccd
	my_cod_catch_weights1 = my_cod_catch_counts1:*cod_catch_weights
	my_cod_landings1=(my_cod_catch_counts1:*cod_catch_weights):*(ones-cod_discard_fraction)
	Fcstatus=3
}

/* Compute age structures of natural mortality, catch (done), landings(done) and remaining fish */
mcce = (ncm):/ (Fc1*cod_age_selectivity+ncm )

/*Natural mortality, landings, and discard age structure */
cod_nat_mort_counts$current_wave=mcce:*mccd
cod_landing_counts_wave$current_wave=my_cod_catch_counts1:*(ones-cod_discard_fraction)
cod_discard_counts_wave$current_wave=my_cod_catch_counts1:*cod_discard_fraction

/*living cod */
cod_end_of_cm=cod_initial_counts:-cod_nat_mort_counts$current_wave:-cod_landing_counts_wave$current_wave:-$cod_comm_discard_mortality*cod_discard_counts_wave$current_wave

/*fix any negative age classes by moving them to adjacent age classes 
Although negative age classes should not be possible at this stage*/
iter2=0
do {
for(i=2;i<=`imax';i++){
	if (cod_end_of_cm[i]<0){
		cod_end_of_cm[i+1]=cod_end_of_cm[i+1]+.5*cod_end_of_cm[i]
		cod_end_of_cm[i-1]=cod_end_of_cm[i-1]+.5*cod_end_of_cm[i]
		cod_end_of_cm[i]=0
	}
}


	if (cod_end_of_cm[1]<0){
		cod_end_of_cm[2]=cod_end_of_cm[2]+cod_end_of_cm[1]
		cod_end_of_cm[1]=0
}
	if (cod_end_of_cm[$cmax_age]<0){
		cod_end_of_cm[8]=cod_end_of_cm[$cmax_age-1]+cod_end_of_cm[$cmax_age]
		cod_end_of_cm[$cmax_age]=0
}
	iter2=iter2+1
}while (iter2<=6)

for(i=1;i<=$cmax_age;i++){
	if (cod_end_of_cm[i]<0){
		cod_end_of_cm[i]=0
	}
}






cod_end_of_cm_method_2=cod_initial_counts:*(exp(-cod_age_selectivity*Fc2 - ncm) ) 



cod_end_of_cm$current_wave = cod_end_of_cm


/*weights of landed and discarded fish */
cod_landing_weight_wave$current_wave = cod_landing_counts_wave$current_wave*cod_catch_weights'
cod_discard_weight_wave$current_wave = cod_discard_counts_wave$current_wave*cod_discard_weights'


mata drop my_cod_catch_counts0 my_cod_catch_counts1 my_cod_catch_weights0 my_cod_catch_weights1
st_numscalar("cod_commercial_landings",cod_landing_weight_wave$current_wave)
st_numscalar("cod_commercial_discards",cod_discard_weight_wave$current_wave)

/*save this to cod_ages_out.dta*/

st_numscalar("F_COMM_COD", Fc1)
st_numscalar("F_COD_STATUS", Fcstatus)



end

