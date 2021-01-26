cd "$my_wd/source_data"

/* ORACLE SQL IN UBUNTU using Stata's connectstring feature.*/
/* THE GOM stratum for cod which should be used are: 01260-01300 and 01360-01400*/

/* THE GOM Haddock stratum which should be used are: 01260-01280 and 01360-01400*/
/* This builds a dataset for cod and haddock that contains the age-length key based on SVDBS cruises.  The years used are $calibration_start to $calibration_end*/




clear
do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do"

#delimit ;


/* Read in cod data the data */
	odbc load,  exec("select cruise6, stratum, svspp,length, age, count(age) as count from UNION_FSCS_SVBIO
where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code in(10,11) and status_code=10 and Season in ( 'SPRING', 'FALL')) and
svspp in (73) and cruise6>=200701 and age is not null and ((stratum between 01260 and 01300) or (stratum between 01360 and 01400))
group by svspp, length, age, cruise6, stratum;") conn("$mysole_conn") lower;
destring, replace;
sort cruise6;
notes: This dataset contains raw data of age-length for each cruise6.
compress;
save "$my_wd/cod_svspp_raw.dta", replace;

clear;
odbc load,  exec("select cruise6, season, year from svdbs_cruises where year>=2007 and purpose_code=10 and status_code=10 and season in ('SPRING', 'FALL')") conn("$mysole_conn") lower;
destring, replace;
sort cruise6;
save "$my_wd/fall_spring_cruises.dta", replace;

use "$my_wd/cod_svspp_raw.dta", clear;
merge m:1 cruise6 using "$my_wd/fall_spring_cruises.dta";
keep if _merge==3;
drop _merge;
sort season;
encode season, gen(myseason);
drop season;
rename myseason season;

save "$my_wd/cod_svspp_raw.dta", replace;
replace age=9 if age>=9;
collapse (sum) count, by(year season svspp age length);
sort svspp year age length count;
save "$my_wd/cod_fall_spring.dta", replace;


/* Cod */
/* To produce the "old" age length key with no seasons */
keep if year>=$lcalibration_start & year<=$lcalibration_end;
collapse (sum) count, by(svspp length age);
sort svspp;
save "$codalkey", replace;
clear;




/* Haddock */
/* Read in cod data the data */
	odbc load,  exec("select cruise6, stratum, svspp,length, age, count(age) as count from UNION_FSCS_SVBIO
where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code=10 and status_code=10 and Season in ( 'SPRING', 'FALL')) and
svspp in (74) and cruise6>=200701 and age is not null and ((stratum between 01260 and 01280) or (stratum between 01360 and 01400))
group by svspp, length, age, cruise6, stratum;") conn("$mysole_conn") lower;
destring, replace;
sort cruise6;
notes: This dataset contains raw data of age-length for each cruise6.
compress;
save "$my_wd/haddock_svspp_raw.dta", replace;

merge m:1 cruise6 using "$my_wd/fall_spring_cruises.dta";
keep if _merge==3;
drop _merge;
sort season;
encode season, gen(myseason);
drop season;
rename myseason season;
save haddock_svspp_raw.dta, replace;


keep if svspp==74;
replace age=9 if age>=9;
collapse (sum) count, by(year season svspp age length);
sort svspp year age length count;
save "$my_wd/haddock_fall_spring.dta", replace;

/* To produce the "old" age length key with no seasons */
keep if year>=$lcalibration_start & year<=$lcalibration_end;
collapse (sum) count, by(svspp length age);
sort svspp;
save "$haddalkey", replace;

cd "$my_wd";

