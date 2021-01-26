/*Data setup */
clear
mata:mata clear
macro drop _all
scalar drop _all
matrix drop _all
pause off
/* linux */
/*
global project_dir "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2016"
*/
/*windows */
global project_dir "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_and_haddock_GARFO_fy2016"
global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"




global which_year=2015


global hadd_naa_start "${source_data}/haddock agepro/2016_HAD_GM_NAA.dta"
global cod_naa_start "${source_data}/cod agepro/2016_COD_BOTH_NAA.dta"


global hadd_naa_sort "${working_data}/haddock_beginning_sorted2015.dta"
global cod_naa_sort "${working_data}/cod_beginning_sorted2015.dta"








/*****************************Initial Conditions ******************************/
/* This section of code ensures some replicability in the draws of intial conditions.  Every 'replicate' will have the same initial stock size. 
THIS IS USEFUL FOR OPTION 2 in which I draw from variable starting conditions*/

/* cod and haddock beginning age structures */
use "$cod_naa_start", clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save "$cod_naa_sort", replace



use "$hadd_naa_start", clear
gen u1=runiform()
gen u2=runiform()
sort u2 u1
bysort year: gen id=_n
order id
drop u1 u2
save "$hadd_naa_sort", replace








