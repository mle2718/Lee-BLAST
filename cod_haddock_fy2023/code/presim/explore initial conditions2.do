/* explore the initial stock structures for haddock and cod */



/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2023" 
	global MRIP_dir  "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2023_01_04" 
	quietly do "C:/Users/Min-Yang.Lee/Documents/common/odbc_setup_macros.do"
	global 	oracle_cxn  " $mysole_conn"
}


 
/* Here are some parameters */
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787



global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global mrip_source_data "${project_dir}/mrip"

global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"


global image_dir "${project_dir}/images"
cap mkdir ${image_dir}


/* This should contain the historical time series of NAA. There should be 1 observation per year */

global cod_naa "${source_data}/cod agepro/historical_and_mean_projected_Cod_NAA.dta"
global hadd_naa "${source_data}/haddock agepro/historical_and_mean_projected_Haddock_NAA.dta"


/* this is a dataset that has the output of the AGEPRO in it. I don't think  i always use this.*/ 
global hadd_naa_start "${source_data}/haddock agepro/NAA_GOM_HADDOCK_2022_FMSY.dta"
global cod_naa_start "${source_data}/cod agepro/NAA_GOM_COD_2021_UPDATE_BOTH.dta"


global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"



/* fiddle with alkey- -- cast to wide. */
use $codalkey, clear
replace length=ceil(length*$cm_to_inch)

collapse (sum) count, by(age length)
/* this little step fills in any missing age and length classes with missing values */
egen double tc=total(count), by(age)
gen double prob=count/tc

tsset age length
tsfill, full

keep age length prob
replace prob=0 if prob<=9e-11
replace prob=0 if prob==.
keep age length prob

reshape wide prob, i(age) j(length)

tempfile codkey
save `codkey', replace


use $haddalkey, clear

replace length=ceil(length*$cm_to_inch)



collapse (sum) count, by(age length)
/* this little step fills in any missing age and length classes with missing values */
egen double tc=total(count), by(age)
gen double prob=count/tc

tsset age length
tsfill, full

keep age length prob
replace prob=0 if prob<=9e-11
replace prob=0 if prob==.
keep age length prob

reshape wide prob, i(age) j(length)

tempfile haddkey
save `haddkey', replace






















use "${hadd_naa_start}", clear

collapse (median) age*, by(year)
reshape long age, i(year) j(ageclass)
rename age count
replace count=count/100000
label var count "Fish (000,000s)"


/* lets merge in the age-length key and compute the length structure */
rename ageclass age
merge m:1 age using `haddkey' 

keep if _merge==3
drop _merge
foreach var of varlist prob*{
	gen cl`var'=count*`var'
}

keep year cl*

collapse (sum) clprob*, by( year)
reshape long clprob, i(year) j(sizeclass)
rename clprob count
label var count "Fish (000,000s)"




forvalues myy=2022/2024{ 
	line count sizeclass if year==`myy',  title("Haddock Length Structure `myy'") yscale(range(0 50)) ylabel(0(10)50) xtitle("Length, inches")

	graph export "${image_dir}/haddock_med_`myy'length.tif", as(tif) replace
}







use "${hadd_naa}", clear

collapse (median) age*, by(year)
reshape long age, i(year) j(ageclass)
rename age count
replace count=count/100000
label var count "Fish (000,000s)"


/* lets merge in the age-length key and compute the length structure */
rename ageclass age
merge m:1 age using `haddkey' 

keep if _merge==3
drop _merge
foreach var of varlist prob*{
	gen cl`var'=count*`var'
}

keep year cl*

collapse (sum) clprob*, by( year)
reshape long clprob, i(year) j(sizeclass)
rename clprob count
label var count "Fish (000,000s)"




forvalues myy=2018/2022{ 
	line count sizeclass if year==`myy',  title("Haddock Length Structure `myy'") xtitle("Length, inches")

	graph export "${image_dir}/haddock_means_`myy'length.tif", as(tif) replace
}




























/* explore the initial stock structures for haddock and cod */
use "${cod_naa_start}", clear

collapse (median) age*, by(year)
reshape long age, i(year) j(ageclass)
rename age count
replace count=count/1000
label var count "Fish (000s)"


/* lets merge in the age-length key and compute the length structure */
rename ageclass age
merge m:1 age using `codkey' 

keep if _merge==3
drop _merge
foreach var of varlist prob*{
	gen cl`var'=count*`var'
}

keep year cl*

collapse (sum) clprob*, by( year)
reshape long clprob, i(year) j(sizeclass)
rename clprob count
label var count "Fish (000s)"




forvalues myy=2022/2024{ 
	line count sizeclass if year==`myy',  title("Cod Length Structure `myy'") xtitle("Length, inches")
	graph export "${image_dir}/cod_med_`myy'length.tif", as(tif) replace
}





use "${cod_naa}", clear

collapse (median) age*, by(year)
reshape long age, i(year) j(ageclass)
rename age count
replace count=count/1000
label var count "Fish (000s)"


/* lets merge in the age-length key and compute the length structure */
rename ageclass age
merge m:1 age using `codkey' 

keep if _merge==3
drop _merge
foreach var of varlist prob*{
	gen cl`var'=count*`var'
}

keep year cl*

collapse (sum) clprob*, by( year)
reshape long clprob, i(year) j(sizeclass)
rename clprob count
label var count "Fish (000s)"




forvalues myy=2018/2022{ 
	line count sizeclass if year==`myy',  title("Cod Length Structure `myy'") xtitle("Length, inches")

	graph export "${image_dir}/cod_means_`myy'length.tif", as(tif) replace
}




















