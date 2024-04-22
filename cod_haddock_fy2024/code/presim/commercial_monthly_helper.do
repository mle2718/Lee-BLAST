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
drop _merge;

gen str4 sppcode="COD" if itis_tsn==164712;
replace sppcode="HADD" if itis_tsn==164744;

replace discard=0 if discard==.;
replace livelnd=0 if livelnd==.;
gen live=livelnd+discard;
label var live "removals in live pounds" ;
save "${source_data}/cfdbs/monthly_`prefix'_${commercial_grab_start}_${commercial_grab_end}.dta", replace;









/* Minor bits of cleanup */

/* Keep only GOM landings */

drop if year==.|month==.;

gen fishing_year=year;
replace fishing_year=fishing_year-1 if month<=4;

/*Lets "tag" the most recent "full" fishing year */
bysort fishing_year sppcode: gen c=_N;
gen full_fy = c==12;
drop c;


/* alternatively, tag the fishign year from $calibration_end
gen tag=0;
replace tag=1 if fishing_year<=$commercial_calibrate_end and fishing_year>=commercial_calibrate_start
 */



save "${source_data}/cfdbs/monthly_`prefix'_${commercial_grab_start}_${commercial_grab_end}.dta", replace;
keep if full_fy==1;
gen month_fy=month-4;
replace month_fy=month_fy+12 if month_fy<=0;
qui summ fishing_year;
scalar p=r(max);
gen tag=0;
replace tag=1 if fishing_year==p;


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


use "${source_data}/cfdbs/monthly_`prefix'_${commercial_grab_start}_${commercial_grab_end}.dta", replace;
keep if full_fy==1;
collapse (sum) live, by(itis_tsn sppcode fishing_year);
replace live=live/2204;
rename live live_mt;
save "${source_data}/cfdbs/annual_removals_fy_${commercial_grab_start}_${commercial_grab_end}.dta", replace;


use "${source_data}/cfdbs/monthly_`prefix'_${commercial_grab_start}_${commercial_grab_end}.dta", replace;
bysort year sppcode: gen c=_N;
gen full_y = c==12;
drop c;
keep if full_y==1;
collapse (sum) live, by(itis_tsn sppcode year);
replace live=live/2204;
rename live live_mt;
save "${source_data}/cfdbs/annual_removals_cy_${commercial_grab_start}_${commercial_grab_end}.dta", replace;

