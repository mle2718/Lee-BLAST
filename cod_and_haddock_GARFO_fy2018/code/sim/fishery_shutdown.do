
/* Closures of the fishery components */
/* THIS IS EXTREMELY IMPORTANT TO UNDERSTAND */
/* WHEN THE COD ACL IS HIT, WE ASSUME NO MORE TARGETING or CATCHING OF COD */
/* WHEN THE HADDOCK ACL IS HIT, WE ASSUME NO MORE TARGETING or CATCHING OF HADDOCK*/
/*
CHECK WHICH ACL IS HIT FIRST.  CLOSE THAT FISHERY AND ADJUST FUTURE TRIPS.   THEN CHECK THE OTHER SPECIES ACL

The structure of these loops:

1.  If neither closes, then do nothing.  display "Neither fishery closes"
2.  If cod closes first, then display "Cod closes first at Trip number XXXX" :
	a.  All subsequent catches of cod into the never caught group
	b.  Set the weight of those subsequent catches of cod equal to zero
	c.  Recalculate probabilities of subsequent trips (because the subsequent catches=0
	d.  Recalculate the welfare and catches associated with subsequent trips
	e.  Check the Haddock fishery for closures
		i.  If it stays open, do nothing.  Display "haddock did not close"
		ii. If it closes, display "haddock closed at Trip number YYYY"
3.  If haddock closes first, then display "Haddock closes first at Trip number ZZZZ" :
	a.  All subsequent catches of haddock into the never caught group
	b.  Set the weight of those subsequent catches of haddock equal to zero
	c.  Recalculate probabilities of subsequent trips (because the subsequent catches=0
	d.  Recalculate the welfare and catches associated with subsequent trips
	e.  Check the cod fishery for closures
		i.  If it stays open, do nothing.  Display "cod did not close"
		ii. If it closes, display "cod closed at Trip number AAAA"
	*/
	
	
quietly if (`shut_cod'==. & `shut_haddock'==.){ /*This is the loop labeled 1 above */
	noisily display "Neither Fishery Closed"

}
quietly if `shut_cod'<`shut_haddock'{/*This is the loop labeled 2 above */
		noisily disp "Cod closed first at Trip number " `shut_cod'
		replace cweight=0 if _n>`shut_cod'
		replace cod_open=0 if _n>`shut_cod'
			foreach cs of varlist cod_status*{
				quietly replace `cs'=0 if _n>`shut_cod'
			}
		replace ckeep=0 if _n>`shut_cod'
		replace crel=0 if _n>`shut_cod'
		do "aux_prob.do" /* we don't need to use and if statement here be -- there will be no changes to an 'open' trip  */
		do "prob_summer.do"
		/*This is the step labeled 2e above */
		gen obsn=_n
		summ obsn if running_hadd>=$hTAC, meanonly
		tempname shut_haddock2
		scalar `shut_haddock2'=r(min)
		drop obsn
		if `shut_haddock2'<=$numtrips{ /*This is the step labeled 2.e. ii above */
			noisily disp "Cod closed first at Trip number " shut_cod " and Haddock Then Closed at Trip " `shut_haddock2'
			replace hweight=0 if _n>`shut_haddock2'
			replace haddock_open=0 if _n>`shut_haddock2'
			foreach hsa of varlist hadd_status*{
				replace `hsa'=0 if _n>`shut_haddock2'
			}
			replace hkeep=0 if _n>`shut_haddock2'
			replace hrel=0 if _n>`shut_haddock2'
			do "aux_prob.do" /* we don't need to use and if statement here be -- there will be no changes to an 'open' trip  */
			do "prob_summer.do"
			replace trip_occur=0 if _n>`shut_haddock2'/* This marks trips which would have occured after both fisheries closed with a 0 */
		}
		if `shut_haddock2'==.{
			noisily disp "Cod closed first at Trip number " `shut_cod' " and Haddock does not close" /*This is the step labeled 2.e.i above */
		}
		if (`shut_haddock2'>$numtrips & `shut_haddock2'~=.){
			noisily disp "Something's very wrong"
		}
	}
quietly if `shut_haddock'<`shut_cod'{/*This is the loop labeled 3 above */
		noisily disp "Haddock closes first at Trip number" `shut_haddock'
		replace hweight=0 if _n>`shut_haddock'
		replace haddock_open=0 if _n>`shut_haddock'
		foreach hsa of varlist hadd_status*{
			quietly replace `hsa'=0 if _n>`shut_haddock'
		}
		replace hkeep=0 if _n>`shut_haddock'
		replace hrel=0 if _n>`shut_haddock'
		do "aux_prob.do" /* we don't need to use and if statement here be -- there will be no changes to an 'open' trip  */
		do "prob_summer.do"
		/*This is the step labeled 3e above */
		gen obsn=_n
		summ obsn if running_cod>=$cTAC, meanonly
		tempname shut_cod2
		scalar `shut_cod2'=r(min)
		drop obsn
		if `shut_cod2'<=$numtrips{ /*This is the step labeled 3.e. ii above */
			noisily disp "Haddock closed first at Trip number " `shut_haddock' " and Cod Then Closed at Trip " `shut_cod2'
			replace cweight=0 if _n>`shut_cod2'
			replace cod_open=0 if _n>`shut_cod2'
			foreach csa of varlist cod_status*{
				replace `csa'=0 if _n>`shut_cod2'
			}
			replace ckeep=0 if _n>`shut_cod2'
			replace crel=0 if _n>`shut_cod2'
			do "aux_prob.do" /* we don't need to use and if statement here be -- there will be no changes to an 'open' trip  */
			do "prob_summer.do"
			replace trip_occur=0 if _n>`shut_cod2'/* This marks trips which would have occured after both fisheries closed with a 0 */

		}
		if `shut_cod2'==.{
			noisily disp "Haddock closed first at Trip number " `shut_haddock' " and Cod did not close" /*This is the step labeled 3.e.i above */
		}
		if (`shut_cod2'>$numtrips & `shut_cod2'~=.){
			noisily disp "Something's very wrong"
		}
		
	}

