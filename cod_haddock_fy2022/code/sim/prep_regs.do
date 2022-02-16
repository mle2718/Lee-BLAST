*do "${code_dir}/sim/read_in_regs.do"
/* code to read in regulations from a csv. */

clear
import delimited  "${code_dir}/sim/regulations/${rec_management}.csv"
levelsof scenario
global scenario_list=r(levels)





save "${code_dir}/sim/regulations/$rec_management.dta", replace
/**************** error checking *****************/
tsset scenario simmonth

/*all scenarios have the same simmonths */
assert "`r(balanced)'"=="strongly balanced"

/*There are no gaps*/
assert `r(gaps)'==0

/* min(month) by scenario should be 1 */
assert r(tmin)==1
/* max(month)-4 should be divisible by 12 */
assert mod((r(tmax)-4),12)==0

