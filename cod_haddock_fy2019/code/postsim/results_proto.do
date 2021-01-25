
*do "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_haddock_2017_set5_hadd_stop.do"
*do "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_haddock_2017_set8_hadd_stop.do"

*do "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_haddock_2017_set6_hadd_stop.do"
*do "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_haddock_2017_set7_hadd_stop.do"

*do "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_haddock_2017_set10_hadd_stop.do"

*do "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/cod_haddock_2017_set9_hadd_stop.do"


/*clear
do "cod_haddock_2017_set2.do"*/

global my_wd "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017"
global my_data_dir "$my_wd/source_data"
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
local rec_out1 "$my_wd/recreational_catches2017_sq_regsa.dta"
local rec_out2 "$my_wd/recreational_catches2017_set2.dta"
local rec_out3 "$my_wd/recreational_catches2017_set3.dta"
local rec_out5 "$my_wd/recreational_catches2017_set5.dta"
local rec_out6 "$my_wd/recreational_catches2017_set6.dta"
local rec_out7 "$my_wd/recreational_catches2017_set7.dta"
local rec_out8 "$my_wd/recreational_catches2017_set8.dta"
local rec_out9 "$my_wd/recreational_catches2017_set9.dta"
local rec_out10 "$my_wd/recreational_catches2017_set10.dta"


*dsconcat `rec_out1' `rec_out2' `rec_out3' `rec_out5' `rec_out6' `rec_out7' `rec_out8' `rec_out9' `rec_out10'
dsconcat `rec_out1' `rec_out2' `rec_out3' `rec_out5' `rec_out6' `rec_out7'   `rec_out8' `rec_out9'

keep if month>=17 & month<=28
gen cod_dead_pounds=cod_pounds_kept+cod_discard_dead_pounds
gen haddock_dead_pounds=haddock_pounds_kept+haddock_discard_dead_pounds

order cod_dead haddock_dead, after(haddock_discard_dead_pounds)


/* examine the effects of zero encounters (and 50% as many encounters) if both species are closed */

expand 2, generate(myexp0)
expand 2 if myexp0==0, generate(myexp50)

replace scenario=scenario+100 if myexp0==1
replace scenario=scenario+1000 if myexp50==1

foreach var of varlist total_trips-haddock_dead_pounds{
replace `var'=0 if myexp0==1 & hmin==99 & cmin==99
replace `var'=0.5*`var' if myexp50==1 & hmin==99 & cmin==99
}


collapse (sum) total_trips-haddock_dead, by(scenario replicate)

gen cod_ok=0
replace cod_ok=1 if cod_dead_pound<=157*$mt_to_kilo*$kilo_to_lbs

gen haddock_ok=0
replace haddock_ok=1 if haddock_dead_pounds<=1160*$mt_to_kilo*$kilo_to_lbs


collapse (median) total_trips-haddock_dead (sum) cod_ok haddock_ok, by(scenario )

gen cod_mortality_mt=cod_dead_pounds/($kilo_to_lbs*$mt_to_kilo)
order cod_mortality_mt, after(cod_dead_pounds)

gen haddock_mortality_mt=haddock_dead_pounds/($kilo_to_lbs*$mt_to_kilo)
order haddock_mortality_mt, after(haddock_dead_pounds)


gen haddock_discard_mt=haddock_pounds_discard/($kilo_to_lbs*$mt_to_kilo)
order haddock_discard_mt, after(haddock_pounds_discard)

gen cod_discard_mt=cod_pounds_discard/($kilo_to_lbs*$mt_to_kilo)
order cod_discard_mt, after(cod_pounds_discard)



label var total "Trips"
label var cod_num_kept "Cod Kept (#)"
label var cod_num_released "Cod Released (#)"
label var haddock_num_kept "Haddock Kept (#)"
label var haddock_num_released "Haddock Released (#)"
label var cod_pounds_kept "Cod Kept (lbs)"
label var cod_pounds_discard  "Cod Released (lbs)"
label var haddock_pounds_kept "Haddock Kept (lbs)"
label var haddock_pounds_discard "Haddock Released (lbs)"
label var cod_dead_pounds "Cod Mortality (lbs)"
label var haddock_dead_pounds "Haddock Mortality (lbs)"
label var cod_ok "Cod under sub-acl (#)"
label var haddock_ok "Haddock under sub-acl (#)"
label var cod_mortality_mt  "Cod Mortality (mt)"
label var haddock_mortality_mt  "Haddock Mortality (mt)"
label var haddock_discard_mt "Haddock Discards (mt)"
label var cod_discard_mt "Cod Discards (mt)"

tempfile qr
save `qr'
sort scenario




export excel scenario total_trips cod_ok haddock_ok cod_dead_pounds cod_mortality_mt haddock_dead_pounds haddock_mortality_mt cod_num_kept cod_num_released haddock_num_kept haddock_num_released cod_pounds_kept cod_pounds_discard haddock_pounds_kept haddock_pounds_discard using "$my_wd/results_2017_exportD.xlsx", replace firstrow( varlabels) sheet("results") 

putexcel set "$my_wd/results_2017_exportD.xlsx", modify sheet(results)

putexcel (A1:P1), border("bottom", "medium", "black")
putexcel (A2:P200), nformat("number_sep")

*putexcel A60="Scenarios in the 100s indicate: trips that occur in months that BOTH cod and haddock are closed do not encounter any cod or haddock"
*putexcel A61="Scenarios in the 1000s indicate: half of the trips that occur in months that BOTH cod and haddock are closed do not encounter any cod or haddock"
*putexcel A62="Scenarios in the 20s indicate: 6 cod max encounters; anglers stop encountering haddock if the bag limit is reached (behavioral change)"


clear

*dsconcat `rec_out1' `rec_out2' `rec_out3' `rec_out5' `rec_out6' `rec_out7' 

dsconcat `rec_out1' `rec_out2' `rec_out3' `rec_out5' `rec_out6' `rec_out7' `rec_out8' `rec_out9' `rec_out10'
keep if replicate==1
gen cy=2016
replace cy=2017 if month>=13
replace cy=2018 if month>=25


gen fy=2015
replace fy=2016 if month>=5
replace fy=2017 if month>=17
replace fy=2018 if month>=29
keep if month>=17 & month<=28
label var cy "calendar year"
label var fy "fishing year"
label var month "month of sim"

keep scenario fy cy month cbag-hmin cod_release_mort hadd_release_mort
order scenario fy cy month
keep if (month>=20 & month<=22 ) | month==17
gen calendar_month=month-12
replace calendar_month=12 if calendar_month==0
order calendar_month, after(cy)

export excel using "$my_wd/results_2017_exportD.xlsx",  firstrow(varlabels) sheet("regulations") sheetreplace 


use `qr', clear
keep scenario
sort scenario
dups, drop terse

gen str60 reg_notes=" "
gen str60 behavior_notes= " " 

replace reg_notes= "Status quo 2016 measures: 1 cod at 24in in August and Sept" if inlist(scenario,0,100,1000)
replace reg_notes= "Cod closed all year. 15 haddock at 17in" if inlist(scenario,1,101,1001,21,53,121,1021,153,1053, 61,161, 1061, 81,181,1081)
replace reg_notes= "Cod closed all year. 12 haddock at 17in" if inlist(scenario,2,102,1002,52,152,1052, 65, 165, 1065)
replace reg_notes= "Cod closed all year. 10 haddock at 17in" if inlist(scenario,3,103,1003,31,51,131,1031,151,1051, 69, 169, 1069)
replace reg_notes= "Cod closed all year. 8 haddock at 17in" if inlist(scenario,4,104,1004, 85, 185, 1085)
replace reg_notes= "Cod closed all year. 5 haddock at 17in" if inlist(scenario,5,105,1005)


replace reg_notes= "Cod closed all year. 15 haddock at 17in. Haddock closed in May" if inlist(scenario,53, 153, 1053, 62, 162, 1062,82,182,1082)
replace reg_notes= "Cod closed all year. 15 haddock at 17in.  Haddock closed in Sept"  if inlist(scenario,7,107,1007,22,122,1022, 63, 163, 1063, 83, 183, 1083)
replace reg_notes= "Cod closed all year. 15 haddock at 17in.  Haddock closed in October"  if inlist(scenario,8,108,1008,23,123,1023, 64, 164, 1064, 84, 184, 1084)

replace reg_notes= "Cod closed all year. 12 haddock at 17in. Haddock closed in May" if inlist(scenario,52, 152, 1052, 66, 166, 1066)
replace reg_notes= "Cod closed all year. 12 haddock at 17in.  Haddock closed in Sept" if inlist(scenario,9,109,1009,34,35,134,135,1034,1035, 67, 167, 1067)
replace reg_notes= "Cod closed all year. 12 haddock at 17in.  Haddock closed in October" if inlist(scenario,10,110,1010,36,136,1036, 68, 168, 1068)

replace reg_notes= "Cod closed all year. 10 haddock at 17in. Haddock closed in May" if inlist(scenario,51, 151, 1051, 70, 170, 1070)
replace reg_notes= "Cod closed all year. 10 haddock at 17in.  Haddock closed in Sept" if inlist(scenario,11,111,1011,32,132,1032, 71, 171, 1071)
replace reg_notes= "Cod closed all year. 10 haddock at 17in.  Haddock closed in October" if inlist(scenario,12,112,1012,33,133,1033, 72, 172, 1072)


replace reg_notes= "Cod closed all year. 8 haddock at 17in.  Haddock closed in May." if inlist(scenario,86,186,1086)
replace reg_notes= "Cod closed all year. 8 haddock at 17in. Haddock closed in Sept" if inlist(scenario,87,187,1087)
replace reg_notes= "Cod closed all year. 8 haddock at 17in. Haddock closed in October" if inlist(scenario,88,188,1088)





replace behavior_notes= "Encounters continue when bag limit is hit" if scenario<=12
replace behavior_notes= "Stop encountering haddock once bag limit is reached. 6 max cod encounters.  50 max haddock" if scenario>=20 & scenario<=59 
replace behavior_notes= "Stop encountering haddock once bag limit is reached. 10 max cod encounters.  50 max haddock" if scenario>=60 & scenario<=75 

replace behavior_notes= "Stop encountering haddock once bag limit is reached. 30 max cod encounters.  50 max haddock" if scenario>=80 & scenario<=88 


replace behavior_notes= "If BOTH cod and haddock are closed,trips do not encounter any cod or haddock." if scenario>=100  & scenario<1000
replace behavior_notes= "If BOTH cod and haddock are closed, half of the trips do not encounter any cod or haddock." if scenario>=1000

replace  behavior_notes= behavior_notes + " Stop encountering haddock once bag limit is reached. 6 max cod encounters.  50 max haddock." if scenario>=120 &  scenario<=159 
replace  behavior_notes= behavior_notes + " Stop encountering haddock once bag limit is reached. 6 max cod encounters.  50 max haddock." if scenario>=1020 &  scenario<=1059 

replace  behavior_notes= behavior_notes + " Stop encountering haddock once bag limit is reached. 10 max cod encounters.  50 max haddock." if scenario>=160 &  scenario<=175 
replace  behavior_notes= behavior_notes + " Stop encountering haddock once bag limit is reached. 10 max cod encounters.  50 max haddock." if scenario>=1060 &  scenario<=1075 

replace  behavior_notes= behavior_notes + " Stop encountering haddock once bag limit is reached. 30 max cod encounters.  50 max haddock." if scenario>=180 &  scenario<=189 
replace  behavior_notes= behavior_notes + " Stop encountering haddock once bag limit is reached. 30 max cod encounters.  50 max haddock." if scenario>=1080 &  scenario<=1089 



sort scenario


export excel scenario reg_notes behavior_notes using "$my_wd/results_2017_exportD.xlsx",  firstrow(varlabels) sheet("quick_regs") sheetreplace 











! cp "/home/mlee/Documents/Workspace/recreational_simulations/cod_and_haddock_GARFO_fy2017/results_2017_exportD.xlsx" "/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee/dropoff/results_2017_exportD.xlsx"
