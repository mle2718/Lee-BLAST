/* This do file will extract the commercial data and examine the temporal distribution */
/* I aggregate by wave and use live weights */
/* The goal of this output is to partition the ratio of commercial fishing into each of the waves
May 12, 2014
 */


do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do"

#delimit ;
/* here is a local which contains the sql statement which I want to run*/
local first= $commercial_grab_start;
local last= $commercial_grab_end;
local prefix "my_cod_haddock";



/* Extraction loop */
forvalues yr=`first'/`last'{;
/* and here is the odbc load command */
	clear;
	tempfile new;
	local files `"`files'"`new'" "';
	odbc load,  exec("select g.carea, s.gearid, s.tripid, s.sppcode, s.qtykept, s.datesold from vtr.veslog`yr's s, vtr.veslog`yr'g g where g.gearid=s.gearid and s.sppcode in ('COD', 'HADD') and g.carea between 511 and 515;
") conn("$mysole_conn") lower;
	gen year=`yr';
	quietly save `new';
};

dsconcat `files';
dups, drop terse;
destring, replace ;
renvars, lower;
compress;
save "$my_wd/monthly_`prefix'_`first'_`last'.dta", replace;




/* Minor bits of cleanup */

/* Keep only GOM landings */

keep if carea>=511 & carea<=515;
drop if qtykept==.;
gen month=month(dofc(datesold));
drop if year==.|month==.;
gen nespp3=081 if strmatch(sppcode, "COD");
replace nespp3=147 if strmatch(sppcode, "HADD");

collapse (sum) live=qtykept, by(nespp3 year month);
gen fishing_year=year;
replace fishing_year=fishing_year-1 if month<=4;

/*Lets "tag" the most recent "full" fishing year */
bysort fishing_year nespp3: gen c=_N;
keep if c==12;
qui summ fishing_year;
scalar p=r(max);
gen tag=0;
replace tag=1 if fishing_year==p;


/* alternatively, tag the fishign year from $calibration_end
gen tag=0;
replace tag=1 if fishing_year<=$commercial_calibrate_end and fishing_year>=commercial_calibrate_start
 */


save "$my_wd/monthly_`prefix'_`first'_`last'.dta", replace;

gen month_fy=month-4;
replace month_fy=month_fy+12 if month_fy<=0;
keep if tag==1;
save "$my_wd/monthly_cod_timing.dta", replace;
save "$my_wd/monthly_haddock_timing.dta", replace;

use "$my_wd/monthly_haddock_timing.dta", clear;
keep if nespp3==147;
collapse (sum) live, by(month);
egen tl=total(live);
gen frac=live/tl;
sort month;
putmata haddock_commercial_monthly=(month frac), replace;
save $my_wd/monthly_haddock_timing.dta, replace;



use $my_wd/monthly_cod_timing.dta, clear;
keep if nespp3==081;
collapse (sum) live, by(month);
egen tl=total(live);
gen frac=live/tl;
sort month;
putmata cod_commercial_monthly=(month frac), replace;

save $my_wd/monthly_cod_timing.dta, replace;
clear;
