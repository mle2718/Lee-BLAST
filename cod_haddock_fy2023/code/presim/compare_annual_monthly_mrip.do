
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all
pause off
global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2020"

/* setup directories */
global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"


/* cod and haddock disaggregated monthly distributions */
global cod_catch_class "${source_data}/mrip/cod_catch_class2019.dta" 
global haddock_catch_class "${source_data}/mrip/haddock_catch_class2019.dta" 

 global cod_historical_sizeclass "${source_data}/mrip/cod_size_class2019.dta"  
 global haddock_historical_sizeclass "${source_data}/mrip/haddock_size_class2019.dta" 
 
 
/* cod and haddock aggregated annual distributions */


global cod_catch_classA "${source_data}/mrip/atlanticcod_annual_catch_class_2019.dta" 
global haddock_catch_classA "${source_data}/mrip/haddock_annual_catch_class_2019.dta" 


 global cod_historical_sizeclassA "${source_data}/mrip/cod_size_class_annual_2019.dta"  
 global haddock_historical_sizeclassA "${source_data}/mrip/haddock_size_class_annual_2019.dta" 

/* cod catch per trip */
clear
use $cod_catch_class
rename count count_monthly


merge 1:1 month num using $cod_catch_classA
rename count count_annual

xtset month num
bysort month :egen ta=total(count_annual)
gen pdfa=count_a/ta
bysort month: egen tm=total(count_mon)
gen pdfm=count_m/tm
drop ta tm
xtline pdfa pdfm if num<=20, legend(order(1 "Annual" 2 "Monthly"))  lwidth(thin thick) lpattern(dash solid) byopts(title("cod catch per trip"))
graph export "$output_dir/cod_catch_comparision2019.png", as(png) replace


/* haddock catch per trip */
clear
use $haddock_catch_class
rename count count_monthly


merge 1:1 month num using $haddock_catch_classA
rename count count_annual

xtset month num
bysort month :egen ta=total(count_annual)
gen pdfa=count_a/ta
bysort month: egen tm=total(count_mon)
gen pdfm=count_m/tm
drop ta tm
xtline pdfa pdfm if num_fish<=30, legend(order(1 "Annual" 2 "Monthly"))  lwidth(thin thick) lpattern(dash solid) byopts(title("haddock catch per trip"))
graph export "$output_dir/haddock_catch_comparision2019.png", as(png) replace


use  $cod_historical_sizeclass, clear  
rename count count_monthly
merge 1:1 month lngcat using $cod_historical_sizeclassA
drop if lngcat==. |lngcat==0
assert _merge==3

rename countn count_annual
xtset month lngcat
bysort month :egen ta=total(count_annual)
gen pdfa=count_a/ta
bysort month: egen tm=total(count_mon)
gen pdfm=count_m/tm
drop ta tm
xtline pdfa pdfm , legend(order(1 "Annual" 2 "Monthly"))   lwidth(thin thick) lpattern(dash solid) byopts(title("Cod Length Distribution"))

graph export "$output_dir/cod_length_comparision2019.png", as(png) replace
 



use  $haddock_historical_sizeclass, clear  
rename count count_monthly
merge 1:1 month lngcat using $haddock_historical_sizeclassA
drop if lngcat==. |lngcat==0
assert _merge==3

rename countn count_annual
xtset month lngcat
bysort month :egen ta=total(count_annual)
gen pdfa=count_a/ta
bysort month: egen tm=total(count_mon)
gen pdfm=count_m/tm
drop ta tm
xtline pdfa pdfm , legend(order(1 "Annual" 2 "Monthly")) byopts(title("Haddock Length Distribution"))  lwidth(thin thick) lpattern(dash solid)

graph export "$output_dir/haddock_length_comparision2019.png", as(png) replace
