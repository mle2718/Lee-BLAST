

/*  haddock recruits, lifted from the agepro INP*/
clear
input recruits
6756 
1628  
6813  
7541  
5036  
1029  
2757  
1151  
324  
301  
153  
446  
220  
285  
305  
802
1522  
3299  
2937  
1298  
2626  
2784  
16348  
3215  
1466  
1665  
334  
8998  
584  
1724  
2026  
383  
598  
1844  
17611  
5800  
24849  
140737  
7962  
7502
end

sort recruits
qui count
scalar p=r(N)-1
gen pdfrecruits=1/p
gen cdfrecruits=sum(pdf)
replace cdf=cdf-pdf

replace recruit=recruit*1000

save "${source_data}/haddock agepro/haddock_recruits_2021base.dta", replace

/*these are from the 2020 AGEPRO FILE */
clear
input recruits
12109
13477
13648
10385
16239
16852 
30236       
4524
        4625        
		8324        
		8303        
		10588       
		3496       
		3780        
		3106        
		5074        
		4469        
		8769        
		5105        
		1316        
		5786        
		2075        
		6701        
		4084        
		6896        
		5431        
		4130        
		2750        
		1713        
		1626        
		1606        
		667         
		2119        
		804         
		530        
		966
		12526.93    
		13972.74    
		14055.2
		10783.6     
		16641.55    
		17668.34    
		32599.89    
		5048.573    
		5414.064    
		10073.68    
		10656.05    
		14674.1     
		5250.046    
		6206.12     
		5574.253    
		9767.23     
		9103.618    
		19073.47
		11485.81    
		2988.684    
		13292.96    
		4813.193    
		15437.82    
		9159.349    
		15121.25    
		11404.95    
		8284.727    
		5289.35     
		3198.493    
		3054.69     
		3284.715    
		1484.388    
		4739.48     
		1698.862    
		1023.996    
		1716.58    
end




sort recruits
qui count
scalar p=r(N)-1
gen pdfrecruits=1/p
gen cdfrecruits=sum(pdf)
replace cdf=cdf-pdf

replace recruit=recruit*1000


save "${source_data}/cod agepro/cod_recruits_2021both.dta", replace

