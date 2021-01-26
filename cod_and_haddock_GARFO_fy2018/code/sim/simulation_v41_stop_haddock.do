/**************************************************************/
/*************************************************************/
/*************************************************************/

/*
This .do file was adapted by Min-Yang.Lee@noaa.gov from original code by Sonia Jarvis.
Version 4.1nc
May 2, 2014


TABLE OF CONTENTS
0.  File description, Meta Data and changelog
1.  Global, scalar, and other setup (parameterization)
2.  Line Drops and Trip Section
3.  WTP Section -- Trip level WTP and cost calculations
4.  Aggregation and  ACLs/TACs


BEGIN Section 0: FILE DESCRIPTION


This file simulates recreational trips (line drops, catches, releases, and end of trips) under differing policy regimes:

The purpose of this simulation is to calculate
	a. WTP for various trips in order to calculate welfare measures
	b. Catch=Kept + discard of both species
 		i.  Kept + discard go into the WTP forumula differentely
		ii.  Kept eventually is output as the total catch of each size of a stock
	c.  This is a Gulf of Maine model only (see parameterization).
		





Changelog:
41a: People continue to encounter fish when the bag limit is hit.	


OTHER NOTES:

Now the results of the RUM are from Kristy/Scott.

Bugs and to do 
A.  The section in which I "check" whether the ACLs have been hit has been removed.  In part because there is no in season monitoring.  
In part because I moved this part to Mata and I don't know how to code it yet.

B.  I've removed "illegal fishing" (sub-legal) and 



/**********************END SECTION 0: FILE DESCRIPTION******************/
/*************************************************************/


*/




/* Take the length strutures, adjust for historical selectivity, and build a matrix (cdf) to draw recreational fish
	The draws of fish length depend on 2 things [selectivity, which is constant] and numbers at length, which will vary by wave in every simulation run
*/
do "setup_fish_length_draws.do"





/* these two globals are related to the feasible lengths (inches) of fish */
/* They are equal to the feasible "size classes" (max_size-min_size+1)*/
global centries=$codmax-$codmin+1
global hentries=$haddmax-$haddmin+1

clear
set obs $wave_numtrips
local wave_obs = _N



/*BEGIN SECTION OF PARAMETER INITIALIZATION */
/* I've done this to push these calculations into an auxilliary do file because they are repetitive but take up alot of space.  This lets me write the auxilliary file using replace instead of gen*/

quietly gen q1=.
quietly gen q2=.
quietly gen q3=.
quietly gen q4=.
quietly gen q5=.
quietly gen q6=.
quietly gen prob=.
quietly gen probold=.

quietly gen trip_occur = . 
quietly gen WTP=0 

quietly gen tripcost=.

quietly gen running_cod=.
quietly gen running_hadd=.

quietly gen running_disc_cod=.
quietly gen running_disc_hadd=.


/* THIS IS THE END OF SECTION 0 */


/* TRIP TYPE, costs, length SECTION*/
/* These proprotions are assigned on the MRFSS data */
tempvar rand81 rand82 temp1
gen `rand81'=uniform()

gen byte mode=cond(`rand81'<=shore, 1, cond(`rand81'<= (shore+boat), 2, cond(`rand81'<=(shore+boat+party), 3, 4)))
label define modetype 1 "shore" 2 "boat" 3 "party/head" 4 "charter"
label values mode modetype
	

	gen shore=0
		replace shore=1 if mode==1
	gen boat=0
		replace boat=1 if mode==2
	gen party=0
		replace party=1 if mode==3
	gen charter=0
		replace charter=1 if mode==4
	gen forhire=0
		replace forhire=1 if mode==3 |mode==4
gen `rand82'=uniform()

		gen triplength=cond(`rand82'<=hour4, 4, cond(`rand82'<=(hour4+hour8), 8, 12 ) )
		

/*These values for trip costs should be double checked */
gen `temp1'=runiform()
replace tripcost=5+200*`temp1' if mode==1
replace tripcost=15+300*`temp1' if mode==2
/*convert cost per hour into total trip cost */
/* SJ - a bit artificial -- but basically how much does it cost */
replace tripcost=15+`temp1'*c_party*triplength if mode==3 
replace tripcost=15+`temp1'*c_chart*triplength if mode==4
 /**************************************************************/











mata:
/* This code gets the number of linedrops for haddock. I wrote it in two lines to make it explicit:
		temp1=rdiscrete($wave_numtrips,1 ,hadd_catch_class_by_month[.,$wave_of_cy+1])
 THE FIRST LINE creates a Nx1 vector of "index positions" based on the values of the pdf in the $current_wave+1 position in the catch-class-distribution matrix. 
 The +1 accounts for the fact that the the catch_class matrix also has the number of fish in the first column

	hrand=hadd_catch_class_by_month[temp1,1]
 THIS LINE takes that index position and ``looks up'' the corresponding number of fish.  We need this clunkyness the index and numbers of fish are not always the same [offset]

	hrand=hadd_catch_class_by_month[rdiscrete(`wave_obs',1 ,hadd_catch_class_by_month[.,$wave_of_cy]),1]
Instead of using $wave_numtrips, it's safer to use the _N  <-- probably wrong*/

/* This code gets the number of linedrops  (expected and actual) for cod and haddock. I wrote it in one line to make it faster*/
hrand=hadd_catch_class_by_month[rdiscrete(`wave_obs',1 ,hadd_catch_class_by_month[.,$wave_of_cy+1]),1]
crand=cod_catch_class_by_month[rdiscrete(`wave_obs',1 ,cod_catch_class_by_month[.,$wave_of_cy+1]),1]
ehrand=hadd_catch_class_by_month[rdiscrete(`wave_obs',1 ,hadd_catch_class_by_month[.,$wave_of_cy+1]),1]
ecrand=cod_catch_class_by_month[rdiscrete(`wave_obs',1 ,cod_catch_class_by_month[.,$wave_of_cy+1]),1]


/* This code constructs the matrices of fish which are caught/released */

/* we can do this in 1 step*/
expected_haddock_lengths=rowshape(matahaddlength_pdf[rdiscrete(`wave_obs'*$haddock_upper_bound,1 ,matahaddlength_pdf[.,2]),1]:+ $lngcat_offset_haddock, `wave_obs') 
expected_cod_lengths=rowshape(matacodlength_pdf[rdiscrete(`wave_obs'*$cod_upper_bound,1 ,matacodlength_pdf[.,2]),1]:+$lngcat_offset_cod, `wave_obs')

haddock_lengths=rowshape(matahaddlength_pdf[rdiscrete(`wave_obs'*$haddock_upper_bound,1 ,matahaddlength_pdf[.,2]),1]:+$lngcat_offset_haddock, `wave_obs')
cod_lengths=rowshape(matacodlength_pdf[rdiscrete(`wave_obs'*$cod_upper_bound,1 ,matacodlength_pdf[.,2]),1]:+$lngcat_offset_cod, `wave_obs')


/* THIS PART IS EXPECTED COD*/
/* HERE IS THE GENERAL STRATEGY */

/* Retention of sub-legal fish */

/* 
0.  Draw 2 random variables that represents the individual's trip's propensity to keep sub-legal cod or haddock.  Probably could be the same number for both cod and haddock. See comment SL1
1.  Construct an Expected Keep matrix=1 for keepable and a expected release matrix=1 for released a <:+> operation will summ to a matrix of 1's.  
2.  Check the line-drops.  Set entries the keep-length and and release-length matrices equal to zero for fish which are never caught.
3.  Check the bag limit and the line drop limit
4.  Compute expected kept and released.
*/
/* We assume that there are two different classes of sublegal fish.  One is "small". These are fish that are a "little bit" smaller than legal sized fish.  
The other is "tiny."  These are smaller than small. */


/* Draw 2 random variables that represents the individual's trip's propensity to keep sub-legal cod or haddock.  Then concatenate this into a matrix.*/
wcodt=runiform(`wave_obs',1)
wcod=mm_expand(wcodt,1,cols(cod_lengths))
whaddt=runiform(`wave_obs',1)


/* SL1 To set trips to have the different underlying propensity, do:*/
whadd=mm_expand(whaddt,1,cols(haddock_lengths))
/* SL1 To set trips to have the same underlying propensity, do:
whadd=mm_expand(wcodt,1,cols(haddock_lengths))
*/

mata drop wcodt whaddt

/* Constructing the adjusted length matrix */

/* small just deals with cod that are small
D=((cod_lengths:<$cod_min_keep):*(cod_lengths:>=$cod_min_keep-$cod_relax)) --> for cod that are small

E1=(wcod:<=$cod_sublegal_keep) -->IF the propensity score is between 0 and the first cutoff propensity (cod_sublegal_keep)  
E2 = ($cod_min_keep+.7) --> set the adjusted length equal to a legal size
F1=(wcod:>$cod_sublegal_keep) --> If the propensity score is above the cutoff probability,  
F2 = cod_lengths --> and set the rest equal to cod_lengths
For cod_lengths that are legal sized OR "tiny" , values of this matrix will be zero. 
*/
ac_small=((expected_cod_lengths:<$cod_min_keep):*(expected_cod_lengths:>=$cod_min_keep-$cod_relax)):*((wcod:<=$cod_sublegal_keep):*($cod_min_keep+.7) + (wcod:>$cod_sublegal_keep2):*expected_cod_lengths)

/* ac_tiny just deals with cod that are tiny
A=(cod_lengths:<$cod_min_keep-$cod_relax) -- for cod_lengths that are tiny 
B1=(wcod:<=$cod_sublegal_keep2) -->IF the propensity score is between 0 and the second cutoff propensity (cod_sublegal_keep2)  
B2= ($cod_min_keep+.2) -->set the "adjusted length" equal to a legal size
C1= (wcod:>$cod_sublegal_keep2)--> If the propensity score is above the cutoff probability, 
C2= cod_length --> set the rest equal to cod_lengths
For cod_lengths that are legal sized OR "small" , values of this matrix will be zero. 
*/

ac_tiny=(expected_cod_lengths:<$cod_min_keep-$cod_relax):*((wcod:<=$cod_sublegal_keep2):*($cod_min_keep+.2) + (wcod:>$cod_sublegal_keep2):*expected_cod_lengths)
aeclengths=expected_cod_lengths:*(expected_cod_lengths:>=$cod_min_keep) +ac_tiny+ac_small
t1=aeclengths:>=$cod_min_keep


/* 1.  Construct a Keep matrix=1 for keepable and a release matrix=1 for released a <:+> operation will summ to a matrix of 1's.  [we don't actually need this matrix]*/
/*Count the number of expected ffish which are greater than or equal to the min size) */
/* I haven't figured hout how to code a 'slot' in an elegant way.  what i've done is to code a pair of 0/1 matrices for the upper and lower limits.  Then I've colon-multiplied them together.
Ugly, but works.  There is probably a very minimal amount of computing time cost*/
t1=expected_cod_lengths:>=$cod_min_keep
t2=expected_cod_lengths:<=$cod_max_keep
eckeepable=t1:*t2
ecreleasable=eckeepable:==0

mata drop t1 t2 ac_tiny ac_small aeclengths


/*2.  Check the line-drops.  Set entries the keep-length and and release-length matrices equal to zero for fish which are never caught */
for (i=1; i<=rows(eckeepable); i++) {
	if (ecrand[i,1]<$cod_upper_bound){
		eckeepable[|i,ecrand[i,1]+1\ i,$cod_upper_bound|]=J(1,$cod_upper_bound-ecrand[i,1],0)
		ecreleasable[|i,ecrand[i,1]+1\ i,$cod_upper_bound|]=J(1,$cod_upper_bound-ecrand[i,1],0)
	}
	else { /* DON'T DO anything if CRAND=the upper bound */
	}	
	
}



/*catch fish that are encountered, add to bag, close bag */
ec_encountered=J(`wave_obs', $cod_upper_bound,1)

for (i=1; i<$cod_upper_bound; i++) {
	if (ecrand[i,1]<$cod_upper_bound){
		ec_encountered[|i,ecrand[i,1]+1\ i,$cod_upper_bound|]=J(1,$cod_upper_bound-ecrand[i,1],0)
	}
	else {
	}
}
etempcbag=eckeepable:*ec_encountered
/*Close the bag when  the "sum" of fish is greater than the bag limit. Pay attention to equalities.*/
/* Add up all the fish in the temporary bag */

erunning_sum_tempcbag=J(`wave_obs', $cod_upper_bound,0)
for (i=1; i<=rows(eckeepable); i++) {
	erunning_sum_tempcbag[i,.] =runningsum(etempcbag[|i,1\i,$cod_upper_bound|])
}

/* Create a matrix that indicates that the bag is open by:
1.  Creating a matrix that is 1 if the "temporary bag" is greater than or equal to the bag limit. And 0 otherwise.
2.  Constructing the "runningsum" matrix (position) of that matrix.  An entry in "position" will equal 1 for the fish which fills the bag
3.  Create a matrix that is=1 for "position<=1". And zero otherwise.  
*/
position=erunning_sum_tempcbag:>=$codbag
for (i=1; i<=rows(eckeepable); i++) {
	position[i,.] =runningsum(position[|i,1\i,$cod_upper_bound|])
}
ecbagopen=position:<=1

/* this is a bit of a hack for a bag limit=0 */
if ($codbag==0) {
	ecbagopen=J(`wave_obs', $cod_upper_bound,0)
	}
else{
}



/*classify each choice occasion as complying with the haddock bag limit or not.
We do this by randomly drawing a number on [0,1]. Then if it is less than the non-complying rate, it is classified as non-complying.
For these rows, overwrite the hbagopen matrix to always be 1 (always open).
*/
if ($pcbag_non!=0){
cbag_noncomply=runiform(`wave_obs',1):<=$pcbag_non

for (k=1; k<=rows(cbag_noncomply); k++) {
	if (cbag_noncomply[k,1]==1){
	ecbagopen[k,.] = J(1,cols(ecbagopen),1)
	}
	else{
	}
}
}
else{
}


/*BEGIN COMMENT OUT 
THIS SECTION OF CODE WILL FORCE ANGLERS TO STOP FISHING ONCE THE BAG LIMIT IS HIT.


/*Fish are actually caught if hbagopen==1 and h_encountered==1*/
eccaught1=ecbagopen:*ec_encountered


ecod_kept=eccaught1:*eckeepable 
ecod_released=eccaught1:*ecreleasable

END COMMENT OUT */


/* THIS SECTION OF CODE WILL ALLOW ANGLERS TO CONTINUE FISHING IF THE BAG LIMIT IS HIT.
END COMMENT OUT
*/

/*Legal sized fish (ckeepable) that are encountered while the bag is open are retained*/
ecod_kept=ecbagopen:*ec_encountered:*eckeepable

/*Legal sized fish (ckeepable) that are encountered while the bag is CLOSED are released*/
/*All sublegal sized fish (creleasable) are released*/
ecbagclosed=J(rows(ecbagopen),cols(ecbagopen),1)-ecbagopen
ecod_released=ec_encountered:*ecreleasable+ ec_encountered:*eckeepable:*ecbagclosed 

eckeep=rowsum(ecod_kept)
ecrel=rowsum(ecod_released)











/* cleanup mata variables */
mata drop ec_encountered etempcbag erunning_sum_tempcbag position ecbagopen  ecbagclosed


/* THIS PART IS EXPECTED HADDOCK -- NO Comments since it's the same as COD, just with different names */
/* Constructing the adjusted length matrix */
ah_small=((expected_haddock_lengths:<$hadd_min_keep):*(expected_haddock_lengths:>=$hadd_min_keep-$hadd_relax)):*((whadd:<=$haddock_sublegal_keep):*($hadd_min_keep+.7) + (whadd:>$haddock_sublegal_keep2):*expected_haddock_lengths)
ah_tiny=(expected_haddock_lengths:<$hadd_min_keep-$hadd_relax):*((whadd:<=$haddock_sublegal_keep2):*($hadd_min_keep+.2) + (whadd:>$haddock_sublegal_keep2):*expected_haddock_lengths)
aehlengths=expected_haddock_lengths:*(expected_haddock_lengths:>=$hadd_min_keep)+ah_tiny+ah_small

t1=aehlengths:>=$hadd_min_keep
t2=expected_haddock_lengths:<=$hadd_max_keep
ehkeepable=t1:*t2
ehreleasable=ehkeepable:==0

mata drop t1 t2 ah_tiny ah_small aehlengths 

for (i=1; i<=rows(ehkeepable); i++) {
	if (ehrand[i,1]<$haddock_upper_bound){
		ehkeepable[|i,ehrand[i,1]+1\ i,$haddock_upper_bound|]=J(1,$haddock_upper_bound-ehrand[i,1],0)
		ehreleasable[|i,ehrand[i,1]+1\ i,$haddock_upper_bound|]=J(1,$haddock_upper_bound-ehrand[i,1],0)
	}
	else { /* DON'T DO anything if CRAND=the upper bound */
	}	
	
}
/*catch fish that are encountered, add to bag, close bag */
eh_encountered=J(`wave_obs', $haddock_upper_bound,1)

for (i=1; i<$haddock_upper_bound; i++) {
	if (ehrand[i,1]<$haddock_upper_bound){
		eh_encountered[|i,ehrand[i,1]+1\ i,$haddock_upper_bound|]=J(1,$haddock_upper_bound-ehrand[i,1],0)
	}
	else {
	}
}
etemphbag=ehkeepable:*eh_encountered
/*Close the bag when  the "sum" of fish is greater than the bag limit. Pay attention to equalities.*/
/* Add up all the fish in the temporary bag */

erunning_sum_temphbag=J(`wave_obs', $haddock_upper_bound,0)
for (i=1; i<=rows(ehkeepable); i++) {
	erunning_sum_temphbag[i,.] =runningsum(etemphbag[|i,1\i,$haddock_upper_bound|])
}

/* Create a matrix that indicates that the bag is open by:
1.  Creating a matrix that is 1 if the "temporary bag" is greater than or equal to the bag limit. And 0 otherwise.
2.  Constructing the "runningsum" matrix (position) of that matrix.  An entry in "position" will equal 1 for the fish which fills the bag
3.  Create a matrix that is=1 for "position<=1". And zero otherwise.  
*/
position=erunning_sum_temphbag:>=$haddockbag
for (i=1; i<=rows(ehkeepable); i++) {
	position[i,.] =runningsum(position[|i,1\i,$haddock_upper_bound|])
}
ehbagopen=position:<=1

/* this is a bit of a hack for a bag limit=0 */
if ($haddockbag==0) {
	ehbagopen=J(`wave_obs', $haddock_upper_bound,0)
	}
else{
}


/*classify each choice occasion as complying with the haddock bag limit or not.
We do this by randomly drawing a number on [0,1]. Then if it is less than the non-complying rate, it is classified as non-complying.
For these rows, overwrite the hbagopen matrix to always be 1 (always open).
*/
if ($phbag_non!=0){
hbag_noncomply=runiform(`wave_obs',1):<=$phbag_non

for (k=1; k<=rows(hbag_noncomply); k++) {
	if (hbag_noncomply[k,1]==1){
	ehbagopen[k,.] = J(1,cols(ehbagopen),1)
	}
	else{
	}
}
}
else{
}




/*BEGIN COMMENT OUT 
THIS SECTION OF CODE WILL FORCE ANGLERS TO STOP FISHING ONCE THE BAG LIMIT IS HIT.*/

/*Fish are actually caught if hbagopen==1 and h_encountered==1*/
ehcaught1=ehbagopen:*eh_encountered


/*Fish are actually caught if hbagopen==1 and h_encountered==1
This could be coded in 1 line with:
ehadd_kept=ehbagopen:*eh_encountered:*ehkeepable 
ehadd_released=ehbagopen:*eh_encountered:*ehreleasable*/

ehadd_kept=ehcaught1:*ehkeepable 
ehadd_released=ehcaught1:*ehreleasable



ehbagclosed=J(rows(ehbagopen),cols(ehbagopen),1)-ehbagopen

/* THIS SECTION OF CODE WILL ALLOW ANGLERS TO STOP CONTINUE FISHING IF THE BAG LIMIT IS HIT.


/*Legal sized fish (ckeepable) that are encountered while the bag is open are retained*/
ehadd_kept=ehbagopen:*eh_encountered:*ehkeepable


/*Legal sized fish (ckeepable) that are encountered while the bag is CLOSED are released*/
/*All sublegal sized fish (creleasable) are released*/
ehbagclosed=J(rows(ehbagopen),cols(ehbagopen),1)-ehbagopen
ehadd_released=eh_encountered:*ehreleasable+ eh_encountered:*ehkeepable:*ehbagclosed 
*/
ehkeep=rowsum(ehadd_kept)
ehrel=rowsum(ehadd_released)

mata drop eh_encountered etemphbag erunning_sum_temphbag position ehbagopen ehbagclosed

end


getmata ehkeep ehrel ehrand eckeep ecrel ecrand



/* This aux do file generates and regenerates probability of a trip occurring  */
do "aux_prob.do"

putmata prob, replace

/*
do "prob_summer.do"
*/

/* NOW WE NEED TO REPEAT OUR PROCESS FOR ACTUAL CATCH   IT IS SIMILAR TO EXPECTED CATCH,WITH A FEW EXCEPTIONS.  
1.  ADD 'WEIGHTS'
2.  SUM WEIGHTS IF TRIP OCCURRED.
3.  STACK UP LENGTHS IF TRIP OCCURRED. 
PROBABLY BEST TO DO 1,2,3 BY USING MATA'S SELECT


There is a preserve statement here because I'm going to-from mata to collapse the length structure of retained and released fish.  So wrapping a preserve/restore lets me keep my trip level data 
in memory. A slicker way to do this would be tempfile or NOT using stata's collapse.*/




preserve
mata:

/* debug step to drop some matrices just to make sure I'm doing what I want to do */
mata drop eckeep eckeepable ecod_kept ecod_released ecrand ecrel ecreleasable ehadd_kept ehadd_released ehkeep ehkeepable ehrand ehrel ehreleasable expected_cod_lengths expected_haddock_lengths i
/*
hrand
crand
haddock_lengths
cod_lengths
*/

/* THIS PART IS COD-  NO COMMENTS Except where it differs from the expectations.*/


/* Retention of sub-legal fish */
/* Constructing the adjusted length matrix */
/* ac_small just deals with the fish that the cod that are small */
ac_small=((cod_lengths:<$cod_min_keep):*(cod_lengths:>=$cod_min_keep-$cod_relax)):*((wcod:<=$cod_sublegal_keep):*($cod_min_keep+.7) + (wcod:>$cod_sublegal_keep2):*cod_lengths)

/* ac_tiny just deals with cod that are tiny */
ac_tiny=(cod_lengths:<$cod_min_keep-$cod_relax):*((wcod:<=$cod_sublegal_keep2):*($cod_min_keep+.2) + (wcod:>$cod_sublegal_keep2):*cod_lengths)
aclengths=cod_lengths:*(cod_lengths:>=$cod_min_keep) +ac_tiny+ac_small

/*4.  This "adjusted" length matrix is used to check the minimum size limits. */

t1=aclengths:>=$cod_min_keep
t2=cod_lengths:<=$cod_max_keep
ckeepable=t1:*t2
creleasable=ckeepable:==0

mata drop t1 t2 aclengths ac_tiny ac_small


for (i=1; i<=rows(ckeepable); i++) {
	if (crand[i,1]<$cod_upper_bound){
		ckeepable[|i,crand[i,1]+1\ i,$cod_upper_bound|]=J(1,$cod_upper_bound-crand[i,1],0)
		creleasable[|i,crand[i,1]+1\ i,$cod_upper_bound|]=J(1,$cod_upper_bound-crand[i,1],0)
	}
	else { /* DON'T DO anything if CRAND=the upper bound */
	}	
	
}


/* initialize the matrix h_encountered to a matrix of 1s:*/
c_encountered=J(`wave_obs', $cod_upper_bound,1)


/*Only fish that were in "position< hrand" are caught. Set h_encountered[i,.] to 0 if i>hrand.   */ 

/* LOGICAL SETS TO 0 if EHRAND hit. */
for (i=1; i<$cod_upper_bound; i++) {
	if (crand[i,1]<$cod_upper_bound){
		c_encountered[|i,crand[i,1]+1\ i,$cod_upper_bound|]=J(1,$cod_upper_bound-crand[i,1],0)
	}
	else {
	}
}

/* Put ALL of the keepable fish into the temporary bag.  
MULTIPLY hkeepable by h_encountered to mark the fish that go into the temporary bag */
tempcbag=ckeepable:*c_encountered

/*Close the bag when  the "sum" of fish is greater than the bag limit. Pay attention to equalities.*/
/* Add up all the fish in the temporary bag */

running_sum_tempcbag=J(`wave_obs', $cod_upper_bound,0)
for (i=1; i<=rows(ckeepable); i++) {
	running_sum_tempcbag[i,.] =runningsum(tempcbag[|i,1\i,$cod_upper_bound|])
}

/* Create a matrix that indicates that the bag is open by:
1.  Creating a matrix that is 1 if the "temporary bag" is greater than or equal to the bag limit. And 0 otherwise.
2.  Constructing the "runningsum" matrix (position) of that matrix.  An entry in "position" will equal 1 for the fish which fills the bag
3.  Create a matrix that is=1 for "position<=1". And zero otherwise.  
*/
position=running_sum_tempcbag:>=$codbag
for (i=1; i<=rows(ckeepable); i++) {
	position[i,.] =runningsum(position[|i,1\i,$cod_upper_bound|])
}
cbagopen=position:<=1

/* this is a bit of a hack for a bag limit=0 */
if ($codbag==0) {
	cbagopen=J(`wave_obs', $cod_upper_bound,0)
	}
else{
}


if ($pcbag_non!=0){
for (k=1; k<=rows(cbag_noncomply); k++) {
	if (cbag_noncomply[k,1]==1){
	cbagopen[k,.] = J(1,cols(cbagopen),1)
	}
	else{
	}
}
}
else{
}




/*BEGIN COMMENT OUT 
THIS SECTION OF CODE WILL FORCE ANGLERS TO STOP FISHING ONCE THE BAG LIMIT IS HIT.
/*Fish are actually caught if hbagopen==1 and h_encountered==1*/
ccaught1=cbagopen:*c_encountered


/*Fish are actually caught if hbagopen==1 and h_encountered==1
This could be coded in 1 line with:
hadd_kept=hbagopen:*h_encountered:*hkeepable 
hadd_released=hbagopen:*h_encountered:*hreleasable*/

cod_kept=ccaught1:*ckeepable 
cod_released=ccaught1:*creleasable


END COMMENT OUT */





/* THIS SECTION OF CODE WILL ALLOW ANGLERS TO  CONTINUE FISHING IF THE BAG LIMIT IS HIT.
*/
/*Legal sized fish (ckeepable) that are encountered while the bag is open are retained*/
cod_kept=cbagopen:*c_encountered:*ckeepable


/*Legal sized fish (ckeepable) that are encountered while the bag is CLOSED are released*/
/*All sublegal sized fish (creleasable) are released*/
cbagclosed=J(rows(cbagopen),cols(cbagopen),1)-cbagopen
cod_released=c_encountered:*creleasable+ c_encountered:*ckeepable:*cbagclosed 












/*count of kept and released per trip */
ckeep=rowsum(cod_kept)
crel=rowsum(cod_released)

/* these are the probability weighted counts of kept and released cod */
pw_ckeep=ckeep'*prob
pw_crel=crel'*prob

/* Part A: I will compute cod_kept and released, weight kept and released for all prospective trips */
/* I will also compute cod_kept and released, weight kept and released for trips which occurred
global $current_wave
 */

/* Lengths of kept and released cod */ 
/* stack the lengths matrix into a vector */

cod_lengths_kept=cod_kept:*cod_lengths
cod_lengths_released=cod_released:*cod_lengths

mata drop c_encountered tempcbag running_sum_tempcbag position cbagopen cbagclosed
/* The first "tempr" rows are from trip 1, the next "tempr" rows are from trips 2....*/
/* I need to check to see if this is done correctly! */
tempr=rows(cod_lengths_kept')
clkvec=vec(cod_lengths_kept')
clrvec=vec(cod_lengths_released')

/* tile out the prob vector into a similar length vector.*/

probvec=prob#J(tempr,1,1)
ck1=(clkvec, probvec)
/* drop out the values where the length>1 -- speeds up the getmata statement */
ck1=select(ck1, ck1[.,1]:>=1)
cr1=(clrvec,probvec)
cr1=select(cr1, cr1[.,1]:>=1)

/*if the ck or cr matrix is 0, set it to 1 5 inch fish*/
if (rows(ck1)==0) {
	ck1=(5,1)
	}
else{
}

if (rows(cr1)==0) {
	cr1=(5,1)
	}
else{
}



end

/* you should be able to do this without casting to stata and back 
your goal is to build a matrix that contains the number of fish, pweighted, in each length class
*/
timer on 88
clear
getmata (v1 v2)=ck1
drop if v1==0
collapse (sum) v2, by(v1)
putmata ckept_matrix=(v1 v2), replace

clear
getmata (v1 v2)=cr1
drop if v1==0
collapse (sum) v2, by(v1)
putmata creleased_matrix=(v1 v2), replace
display "simulation checkpoint 3"
timer off 88
mata

creleased_matrix=(creleased_matrix,$kilo_to_lbs:* $cod_lwa:*(((creleased_matrix[.,1]):/$cm_to_inch):^$cod_lwb))
ckept_matrix=(ckept_matrix,$kilo_to_lbs:* $cod_lwa:*(((ckept_matrix[.,1]):/$cm_to_inch):^$cod_lwb))

/* Add up the weights of cod_kept and cod_released */




/* Part B: Producing the biological outputs */
/* colon Multiplying lenghts kept and released by the trip_occur column produces a `wave_obs' X line drops vector which contains lengths of fish for trips which occurred OR zeros.  
This is stacked into a vector and the zeros are filtered out
Then the L-W equation is employed and the aggregate sum is computed */


aggregate_cod_kept_pounds=ckept_matrix[.,2]'*ckept_matrix[.,3]
aggregate_cod_released_pounds=creleased_matrix[.,2]'*creleased_matrix[.,3]
cod_released_dead_pounds=aggregate_cod_released_pounds*$mortality_release

st_numscalar("cod_discarded_dead_weight", cod_released_dead_pounds)










/*count of kept and released per per wave ONLY FOR TRIPS WHICH OCCUR! */
/* Error handling --what happens if there are no fish kept or released in a wave? Does my code break if ckept_matrix is null? */
ackeep=pw_ckeep
acrel=pw_crel






/* Next thing is to stack and count the length structure of cod kept using a new version of bio_out */




/* THIS PART IS HADDOCK -- NO Comments since it's the same as COD, just with different names */

/* Constructing the adjusted length matrix */
ah_small=((haddock_lengths:<$hadd_min_keep):*(haddock_lengths:>=$hadd_min_keep-$hadd_relax)):*((whadd:<=$haddock_sublegal_keep):*($hadd_min_keep+.7) + (whadd:>$haddock_sublegal_keep2):*haddock_lengths)
ah_tiny=(haddock_lengths:<$hadd_min_keep-$hadd_relax):*((whadd:<=$haddock_sublegal_keep2):*($hadd_min_keep+.2) + (whadd:>$haddock_sublegal_keep2):*haddock_lengths)
ahlengths=haddock_lengths:*(haddock_lengths:>=$hadd_min_keep)+ah_tiny+ah_small

t1=ahlengths:>=$hadd_min_keep
t2=haddock_lengths:<=$hadd_max_keep
hkeepable=t1:*t2
hreleasable=hkeepable:==0

mata drop t1 t2 ah_tiny ah_small ahlengths

for (i=1; i<=rows(hkeepable); i++) {
	if (hrand[i,1]<$haddock_upper_bound){
		hkeepable[|i,hrand[i,1]+1\ i,$haddock_upper_bound|]=J(1,$haddock_upper_bound-hrand[i,1],0)
		hreleasable[|i,hrand[i,1]+1\ i,$haddock_upper_bound|]=J(1,$haddock_upper_bound-hrand[i,1],0)
	}
	else { /* DON'T DO anything if CRAND=the upper bound */
	}	
	
}



/* initialize the matrix h_encountered to a matrix of 1s:*/
h_encountered=J(`wave_obs', $haddock_upper_bound,1)


/*Only fish that were in "position< hrand" are caught. Set h_encountered[i,.] to 0 if i>hrand.   */ 

/* LOGICAL SETS TO 0 if EHRAND hit. */
for (i=1; i<$haddock_upper_bound; i++) {
	if (hrand[i,1]<$haddock_upper_bound){
		h_encountered[|i,hrand[i,1]+1\ i,$haddock_upper_bound|]=J(1,$haddock_upper_bound-hrand[i,1],0)
	}
	else {
	}
}
/* Put ALL of the keepable fish into the temporary bag.  
MULTIPLY hkeepable by h_encountered to mark the fish that go into the temporary bag */
temphbag=hkeepable:*h_encountered

/*Close the bag when  the "sum" of fish is greater than the bag limit. Pay attention to equalities.*/
/* Add up all the fish in the temporary bag */

running_sum_temphbag=J(`wave_obs', $haddock_upper_bound,0)
for (i=1; i<=rows(hkeepable); i++) {
	running_sum_temphbag[i,.] =runningsum(temphbag[|i,1\i,$haddock_upper_bound|])
}

/* Create a matrix that indicates that the bag is open by:
1.  Creating a matrix that is 1 if the "temporary bag" is greater than or equal to the bag limit. And 0 otherwise.
2.  Constructing the "runningsum" matrix (position) of that matrix.  An entry in "position" will equal 1 for the fish which fills the bag
3.  Create a matrix that is=1 for "position<=1". And zero otherwise.  
*/
position=running_sum_temphbag:>=$haddockbag
for (i=1; i<=rows(hkeepable); i++) {
	position[i,.] =runningsum(position[|i,1\i,$haddock_upper_bound|])
}
hbagopen=position:<=1

/* this is a bit of a hack for a bag limit=0 */
if ($haddockbag==0) {
	hbagopen=J(`wave_obs', $haddock_upper_bound,0)
	}
else{
}


if ($phbag_non!=0){

for (k=1; k<=rows(hbag_noncomply); k++) {
	if (hbag_noncomply[k,1]==1){
	hbagopen[k,.] = J(1,cols(hbagopen),1)
	}
	else{
	}
}
}
else{
}




/*BEGIN COMMENT OUT 
THIS SECTION OF CODE WILL FORCE ANGLERS TO STOP FISHING ONCE THE BAG LIMIT IS HIT.
*/
/*Fish are actually caught if hbagopen==1 and h_encountered==1*/
hcaught1=hbagopen:*h_encountered


/*Fish are actually caught if hbagopen==1 and h_encountered==1
This could be coded in 1 line with:
hadd_kept=hbagopen:*h_encountered:*hkeepable 
hadd_released=hbagopen:*h_encountered:*hreleasable*/

hadd_kept=hcaught1:*hkeepable 
hadd_released=hcaught1:*hreleasable



hbagclosed=J(rows(hbagopen),cols(hbagopen),1)-hbagopen

/* THIS SECTION OF CODE WILL ALLOW ANGLERS TO CONTINUE FISHING IF THE BAG LIMIT IS HIT.


/*Legal sized fish (ckeepable) that are encountered while the bag is open are retained*/
hadd_kept=hbagopen:*h_encountered:*hkeepable


/*Legal sized fish (ckeepable) that are encountered while the bag is CLOSED are released*/
/*All sublegal sized fish (creleasable) are released*/
hbagclosed=J(rows(hbagopen),cols(hbagopen),1)-hbagopen
hadd_released=h_encountered:*hreleasable+ h_encountered:*hkeepable:*hbagclosed 

*/









hkeep=rowsum(hadd_kept)
hrel=rowsum(hadd_released)

/* these are the probability weighted counts of kept and released cod */
pw_hkeep=hkeep'*prob
pw_hrel=hrel'*prob

/*count of kept and released per per wave ONLY FOR TRIPS WHICH OCCUR! */

ahkeep=pw_hkeep
ahrel=pw_hrel


mata drop h_encountered temphbag running_sum_temphbag position hbagopen hbagclosed 

/* Part A: I will compute cod_kept and released, weight kept and released for all prospective trips */
/* I will also compute cod_kept and released, weight kept and released for trips which occurred
global $current_wave
 */

/* Lengths of kept and released cod */ 
/* stack the lengths matrix into a vector */
/* I need to check this to make sure it's correct */
haddock_lengths_kept=hadd_kept:*haddock_lengths
haddock_lengths_released=hadd_released:*haddock_lengths


/* The first "tempr" rows are from trip 1, the next "tempr" rows are from trips 2....*/
hlkvec=vec(haddock_lengths_kept')
hlrvec=vec(haddock_lengths_released')
tempr=rows(haddock_lengths_kept')

/* tile out the prob vector into a similar length vector.*/

probvec=prob#J(tempr,1,1)
hk1=(hlkvec, probvec)
/* drop out the values where the length=0 -- speeds up the getmata statement */
hk1=select(hk1, hk1[.,1]:>=1)

hr1=(hlrvec,probvec)
hr1=select(hr1, hr1[.,1]:>=1)


/*if the hk or hr matrix is 0, set it to 1 5 inch fish*/
if (rows(hk1)==0) {
	hk1=(5,1)
	}
else{
}

if (rows(hr1)==0) {
	hr1=(5,1)
	}
else{
}
end

clear
getmata (v1 v2)=hk1
drop if v1==0
collapse (sum) v2, by(v1)
putmata hkept_matrix=(v1 v2), replace

clear
getmata (v1 v2)=hr1
drop if v1==0
collapse (sum) v2, by(v1)
putmata hreleased_matrix=(v1 v2), replace

mata

hreleased_matrix=(hreleased_matrix, $kilo_to_lbs:*$had_lwa:*(((hreleased_matrix[.,1]):/$cm_to_inch):^$had_lwe)  )
hkept_matrix=(hkept_matrix,$kilo_to_lbs:*$had_lwa:*(((hkept_matrix[.,1]):/$cm_to_inch):^$had_lwe)  )

/* Add up the weights of cod_kept and cod_released */



/* Part B: Producing the biological outputs */
/* colon Multiplying lenghts kept and released by the trip_occur column produces a `wave_obs' X line drops vector which contains lengths of fish for trips which occurred OR zeros.  
This is stacked into a vector and the zeros are filtered out
Then the L-W equation is employed and the aggregate sum is computed */
/* Error handling --what happens if there are no fish kept or released in a wave? Does my code break if hkept_matrix is null? */


aggregate_haddock_kept_pounds=hkept_matrix[.,2]'*hkept_matrix[.,3]
aggregate_haddock_rel_pounds=hreleased_matrix[.,2]'*hreleased_matrix[.,3]


haddock_rel_dead_pounds=aggregate_haddock_rel_pounds*$haddock_mortality_release

/* Compute weight of discarded fish */
st_numscalar("haddock_discard_dead_weight", haddock_rel_dead_pounds)



end

restore

getmata ckeep crel hkeep hrel

gen cod_open=1
gen haddock_open=1

/* Uncomment this to enable a partial "in-season" shutdown */
/* quietly do "fishery_shutdown.do" */

/* Check both TACs -- these 2 scalars are the trip numbers which are the final trips
tempvar obsn
tempname shut_cod shut_haddock

gen `obsn'=_n
quietly summ `obsn' if running_cod>=$cTAC, meanonly
scalar `shut_cod'=r(min)

quietly summ `obsn' if running_hadd>=$hTAC, meanonly
scalar `shut_haddock'=r(min) */




/* THIS IS THE END OF THE checking ACLs eECTION */

/**************************************************************/
/**************************************************************/

/* Compute WTP for all trips*/


