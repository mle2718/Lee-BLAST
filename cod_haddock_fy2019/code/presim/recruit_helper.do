recruit helper
/* copy and paste in */

rename base recruits
sort recruits
qui count
scalar p=r(N)-1
gen pdfrecruits=1/p
gen cdfrecruits=sum(pdf)
replace cdf=cdf-pdf

replace recruit=recruit*1000
