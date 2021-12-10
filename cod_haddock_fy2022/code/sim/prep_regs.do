*do "${code_dir}/sim/read_in_regs.do"
/* code to read in regulations from a csv. */

clear
import delimited  "${code_dir}/sim/regulations/${rec_management}.csv"
levelsof scenario
global scenario_list=r(levels)





save "${code_dir}/sim/regulations/$rec_management.dta", replace

/* error checking */
collapse (min) mins=simmonth (max) maxs=simmonth, by(scenario)
/* min(month) by scenario should be 1 */
assert mins==1
/* max(month)-4 should be divisible by 12 */
replace maxs=maxs-4
assert mod(maxs,12)==0
