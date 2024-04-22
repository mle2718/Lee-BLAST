
/* ORACLE SQL IN UBUNTU using Stata's connectstring feature.*/
/* THE GOM stratum for cod which should be used are: 01260-01300 and 01360-01400*/

/* THE GOM Haddock stratum which should be used are: 01260-01280 and 01360-01400*/
/* This builds a dataset for cod and haddock that contains the age-length key based on SVDBS cruises.  The years used are $calibration_start to $calibration_end*/




clear
*do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do"

#delimit ;
tempfile cod_temp_ages hadd_temp_ages;
set obs 9;
gen age=_n;
gen svspp=73;
save `cod_temp_ages', replace;
replace svspp=74;

save `hadd_temp_ages', replace;

clear;

/* Read in cod data the data */
	odbc load,  exec("select cruise6, stratum, svspp,length, age, count(age) as count from UNION_FSCS_SVBIO
where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code in(10,11) and status_code=10 and Season in ( 'SPRING', 'FALL')) and
svspp in (73) and cruise6>=201201 and age is not null and ((stratum between 01260 and 01300) or (stratum between 01360 and 01400))
group by svspp, length, age, cruise6, stratum;") $oracle_cxn;
destring, replace;
sort cruise6;
notes: This dataset contains raw data of age-length for each cruise6.
compress;
drop if age==0;
save "${source_data}/svdbs/cod_svspp_raw.dta", replace;

clear;
odbc load,  exec("select cruise6, season, year from svdbs_cruises where year>=2007 and purpose_code=10 and status_code=10 and season in ('SPRING', 'FALL')") $oracle_cxn;
destring, replace;
sort cruise6;
save "${source_data}/svdbs/fall_spring_cruises.dta", replace;

use "${source_data}/svdbs/cod_svspp_raw.dta", clear;
merge m:1 cruise6 using "${source_data}/svdbs/fall_spring_cruises.dta";
keep if _merge==3;
drop _merge;
sort season;
encode season, gen(myseason);
drop season;
rename myseason season;

save "${source_data}/svdbs/cod_svspp_raw.dta", replace;
replace age=9 if age>=9;
collapse (sum) count, by(year season svspp age length);
sort svspp year age length count;
save "${source_data}/svdbs/cod_fall_spring.dta", replace;


/* Cod */
/* To produce the "old" age length key with no seasons */
use  "${source_data}/svdbs/cod_fall_spring.dta", replace;

keep if year>=$lcalibration_start & year<=$lcalibration_end;
collapse (sum) count, by(svspp length age);
sort svspp;


bysort age: egen t=total(count);
drop if t<=10;
tempfile cod_lengths;
save `cod_lengths', replace;

use `cod_temp_ages';
/* potentially fill in any missing age classes */

merge 1:m svspp age using `cod_lengths';

sort svspp age length;

count if _merge==1;
if(r(N)>=1){;
/* this will only work for continuous holes at the upper end of the age distribution */
levelsof age if _merge==1, local(missing) sep(",");
levelsof age if _merge==3, local(matched);
qui summ age if _merge==3;


local good=r(max);
qui summ age if _merge==1;
local bad=r(max);
local reps=`bad'-`good';
drop if inlist(age,`missing');
expand `reps'+1 if age==`good';
cap drop _merge;

bysort svspp length age count: gen mark=_n;
replace age=age+mark-1 if age==`good';
};
cap drop t ;
cap drop mark;

qui summ age;
assert r(max)==9;
assert r(min)==1;

levelsof age, matrow(myage);
mat b=rowsof(myage);
assert b[1,1]==9;
cap drop _merge;
save "$codalkey", replace;
clear;




/* Haddock */
/* Read in haddock data */
	odbc load,  exec("select cruise6, stratum, svspp,length, age, count(age) as count from UNION_FSCS_SVBIO
where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code=10 and status_code=10 and Season in ( 'SPRING', 'FALL')) and
svspp in (74) and cruise6>=201201 and age is not null and ((stratum between 01260 and 01280) or (stratum between 01360 and 01400))
group by svspp, length, age, cruise6, stratum;")  $oracle_cxn;
destring, replace;
sort cruise6;
notes: This dataset contains raw data of age-length for each cruise6.
compress;
drop if age==0;
save "${source_data}/svdbs/haddock_svspp_raw.dta", replace;

merge m:1 cruise6 using "${source_data}/svdbs/fall_spring_cruises.dta";
keep if _merge==3;
drop _merge;
sort season;
encode season, gen(myseason);
drop season;
rename myseason season;
save "${source_data}/svdbs/haddock_svspp_raw.dta", replace;


keep if svspp==74;
replace age=9 if age>=9;
collapse (sum) count, by(year season svspp age length);
sort svspp year age length count;
save "${source_data}/svdbs/haddock_fall_spring.dta", replace;


# delimit ;
use "${source_data}/svdbs/haddock_fall_spring.dta", replace;

/* To produce the "old" age length key with no seasons */
keep if year>=$lcalibration_start & year<=$lcalibration_end;
sort svspp;



keep if year>=$lcalibration_start & year<=$lcalibration_end;
collapse (sum) count, by(svspp length age);
sort svspp;


bysort age: egen t=total(count);
drop if t<=10;
tempfile hadd_lengths;
save `hadd_lengths', replace;

use `hadd_temp_ages';
/* potentially fill in any missing age classes */

merge 1:m svspp age using `hadd_lengths';

sort svspp age length;

count if _merge==1;
if(r(N)>=1){;
/* this will only work for continuous holes at the upper end of the age distribution */
levelsof age if _merge==1, local(missing) sep(",");
levelsof age if _merge==3, local(matched);
qui summ age if _merge==3;


local good=r(max);
qui summ age if _merge==1;
local bad=r(max);
local reps=`bad'-`good';
drop if inlist(age,`missing');
expand `reps'+1 if age==`good';
cap drop _merge;

bysort svspp length age count: gen mark=_n;
replace age=age+mark-1 if age==`good';
};
cap drop t ;
cap drop mark;

qui summ age;
assert r(max)==9;
assert r(min)==1;

levelsof age, matrow(myage);
mat b=rowsof(myage);
assert b[1,1]==9;
cap drop _merge;

save "$haddalkey", replace;

