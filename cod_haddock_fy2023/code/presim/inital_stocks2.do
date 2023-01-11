/* investigate age-length keys */
clear
mata:mata clear
scalar drop _all
matrix drop _all

set seed  4160

/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2023" 
	global MRIP_dir  "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2023_01_04" 
	quietly do "C:/Users/Min-Yang.Lee/Documents/common/odbc_setup_macros.do"
	global 	oracle_cxn  " $mysole_conn"
}





global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global mrip_source_data "${project_dir}/mrip"

global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"


global image_dir "${project_dir}/images"
cap mkdir ${image_dir}

use "${source_data}/svdbs/cod_fall_spring.dta", replace
keep if year>=2021
collapse (sum) count, by(year age length)
preserve
keep if year==2021


tsset age length

xtline count
graph export ${image_dir}/cod2021_alkey.png, replace width(2000)
restore
keep if year>=2021
collapse (sum) count, by(year age length)
preserve
keep if year==2022


tsset age length

xtline count
graph export ${image_dir}/cod2022_alkey.png, replace width(2000)
restore

preserve
collapse (sum) count, by( age length)

tsset age length

xtline count
 graph export ${image_dir}/codboth_alkey.png, replace width(2000)
restore









use "${source_data}/svdbs/haddock_fall_spring.dta", replace
keep if year>=2021
collapse (sum) count, by(year age length)
preserve
keep if year==2021


tsset age length

xtline count
graph export ${image_dir}/hadd2021_alkey.png, replace width(2000)
restore
keep if year>=2021
collapse (sum) count, by(year age length)
preserve
keep if year==2022


tsset age length

xtline count
graph export ${image_dir}/hadd2022_alkey.png, replace width(2000)
restore

preserve
collapse (sum) count, by( age length)

tsset age length

xtline count
graph export ${image_dir}/haddboth_alkey.png, replace width(2000)
restore





















