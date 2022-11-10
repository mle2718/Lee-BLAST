

/*  haddock recruits, lifted from the agepro INP*/
clear
input recruits
6546.322
1577.82
6606.133
7304.956
4885.123
998.7703
2683.679
1125.707
317.0006
295.5949
151.1924
442.0122
217.2176
280.9525
299.9154
787.5254
1499.461
3254.451
2905.05
1288.522
2616.614
2774.945
16073.22
3095.291
1399.093
1580.378
313.2323
8391.499
531.041
1531.972
1748.146
317.021
467.6682
1377.784
12091.79
3537.407
13031.04
83931.95
4914.645
5169.056
6976.235
5629.35
2080.317
3058.83
22780.99
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

