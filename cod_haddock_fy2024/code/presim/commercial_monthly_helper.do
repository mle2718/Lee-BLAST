/* This do file will extract the commercial data and examine the temporal distribution */
/* I aggregate by wave and use live weights */
/* The goal of this output is to partition the ratio of commercial fishing into each of the waves
May 12, 2014
 */


#delimit ;
/* here is a local which contains the sql statement which I want to run*/

local prefix "my_cod_haddock";


clear;
/* Extract landings */
	odbc load,  exec("select sum(nvl(lndlb,0)) as landings,  sum(livlb) as livelnd, year, month, itis_tsn from cams_garfo.cams_land cl where 
		cl.area between 511 and 515 and 
		cl.year between $commercial_grab_start and $commercial_grab_end and
		itis_tsn in ('164712','164744')
group by year, month, itis_tsn;") $myNEFSC_USERS_conn ;
destring itis_tsn, replace;

destring, replace ;
renvars, lower;
compress;
tempfile landings;
save `landings', replace;
clear;

/* Extract discards */
odbc load,  exec("select year, extract(month from date_trip) as month, itis_tsn, sum(nvl(cams_discard,0)) as discard from cams_garfo.cams_discard_all_years cl where 
		cl.area between 511 and 515 and 
		year>=2022 and 
		itis_tsn in (164712,164744)
		group by year, extract(month from date_trip), itis_tsn;") $myNEFSC_USERS_conn ;
destring itis_tsn, replace;

merge 1:1 year month itis_tsn using `landings';


gen str4 sppcode="COD" if itis_tsn==164712;
replace sppcode="HADD" if itis_tsn==164744;

replace discard=0 if discard==.;
replace livelnd=0 if livelnd==.;
gen live=livelnd+discard;

save "${source_data}/cfdbs/monthly_`prefix'_${commercial_grab_start}_${commercial_grab_end}.dta", replace;









/* Minor bits of cleanup */

/* Keep only GOM landings */

drop if year==.|month==.;

gen fishing_year=year;
replace fishing_year=fishing_year-1 if month<=4;

/*Lets "tag" the most recent "full" fishing year */
bysort fishing_year sppcode: gen c=_N;
keep if c==12;
qui summ fishing_year;
scalar p=r(max);
gen tag=0;
replace tag=1 if fishing_year==p;


/* alternatively, tag the fishign year from $calibration_end
gen tag=0;
replace tag=1 if fishing_year<=$commercial_calibrate_end and fishing_year>=commercial_calibrate_start
 */



save "${source_data}/cfdbs/monthly_`prefix'_${commercial_grab_start}_${commercial_grab_end}.dta", replace;
gen month_fy=month-4;
replace month_fy=month_fy+12 if month_fy<=0;
keep if tag==1;
save "${source_data}/cfdbs/monthly_cod_timing.dta", replace;
save "${source_data}/cfdbs/monthly_haddock_timing.dta", replace;

use "${source_data}/cfdbs/monthly_haddock_timing.dta", clear;
keep if sppcode=="HADD";
collapse (sum) live, by(month);
egen tl=total(live);
gen frac=live/tl;
sort month;
putmata haddock_commercial_monthly=(month frac), replace;
save "${source_data}/cfdbs/monthly_haddock_timing.dta", replace;



use "${source_data}/cfdbs/monthly_cod_timing.dta", clear;
keep if sppcode=="COD";
collapse (sum) live, by(month);
egen tl=total(live);
gen frac=live/tl;
sort month;
putmata cod_commercial_monthly=(month frac), replace;

save "${source_data}/cfdbs/monthly_cod_timing.dta", replace;
clear;
