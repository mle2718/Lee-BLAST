

/*2016 Regs
August 1-September 30: 1 cod at 24" (W4, part2 and W5, part 1)
zero possession otherwise

May1-Feb 28 and April 15-April 30: 15 haddock @ 17" (Year round is close enough)


2017 regs rolled over until the end of July, 2017
HBAG: 12 at the end of July, 2017
HBAG: zero for: 
	second half of Sept. and all of october
	All of march, half of April
	
Bring Back Half of April

	
COD: Closed all year
cod was originally supposed to be open in Aug/sept. but it was closed

For the half-months, we'll leave the regs alone and use the number of trips to calibrate.
https://www.greateratlantic.fisheries.noaa.gov/nr/2017/July/17mulrec2017measuresphl.html
*/





mata:
/* Haddock bags*/
hbag_cy12=J(1,$periods_per_year,35)
hbag_cy13=J(1,$periods_per_year,35)
hbag_cy14=(J(1,4,35), J(1,8,3))
hbag_cy15=J(1,$periods_per_year,3)
hbag_cy16=(J(1,4,3), J(1,8,15))
hbag_cy17=J(1,$periods_per_year,15)


hbag_cy17=(J(1,7,15), J(1,5,12))
hbag_cy18=J(1,12,12)
hbag_cy19=hbag_cy18


/* Haddock size*/
hmin_cy12=J(1,$periods_per_year,18)
hmin_cy13=(J(1,4,18), J(1,8,21))
hmin_cy14=J(1,$periods_per_year,21)
hmin_cy15=hmin_cy14
hmin_cy16=(J(1,4,21), J(1,8,17))

hmin_cy17=J(1,$periods_per_year,17)
hmin_cy17[10]=99

hmin_cy18=hmin_cy17
hmin_cy18[3]=99

hmin_cy19=hmin_cy18



/* Cod bags*/
cbag_cy12=(J(1,4,10), J(1,8,9))
cbag_cy13=J(1,$periods_per_year,9)
cbag_cy14=cbag_cy13
cbag_cy15=cbag_cy14
cbag_cy16=cbag_cy15
cbag_cy17=cbag_cy16


cbag_cy16[8]=1
cbag_cy16[9]=1

cbag_cy18=cbag_cy17
cbag_cy19=cbag_cy18


/* Cod Mins*/
cmin_cy12=(J(1,4,24), J(1,8,19))
cmin_cy13=J(1,$periods_per_year,19)
cmin_cy14=(J(1,4,19), J(1,4,21), J(1,4,99))

cmin_cy15=J(1,$periods_per_year,99)
cmin_cy16=J(1,$periods_per_year,99)
cmin_cy16[8]=24
cmin_cy16[9]=24

cmin_cy17=J(1,$periods_per_year,99)
cmin_cy18=cmin_cy17
cmin_cy19=cmin_cy18



end




/*This assembles the bag and size limits*/
mata:haddock_bag_vec=(hbag_cy15,hbag_cy16, hbag_cy17,hbag_cy18,hbag_cy19)

mata:cod_bag_vec=(cbag_cy15,cbag_cy16,cbag_cy17,cbag_cy18,cbag_cy19)
mata: haddock_min_vec=(hmin_cy15,hmin_cy16,hmin_cy17,hmin_cy18,hmin_cy19)

mata: haddock_max_vec=J(1,length(haddock_min_vec),100)

mata: cod_min_vec=(cmin_cy15,cmin_cy16, cmin_cy17,cmin_cy18, cmin_cy19)
mata: cod_max_vec=J(1,length(cod_min_vec),100)
mata: haddock_bag_vec=haddock_bag_vec[|$rec_month_starter \.|]
mata: cod_bag_vec=cod_bag_vec[|$rec_month_starter \.|]
mata: haddock_min_vec=haddock_min_vec[|$rec_month_starter \.|]
mata: haddock_max_vec=haddock_max_vec[|$rec_month_starter \.|]
mata: cod_min_vec=cod_min_vec[|$rec_month_starter \.|]
mata: cod_max_vec=cod_max_vec[|$rec_month_starter \.|]



/* Compute the distribution of effort by the recreational fishery in each wave or month
Right now this distribution is hard coded -- one day it should be set up to look at the data*/
/* Allocate the commercial cod and haddock mortality to each of the 6 waves.  Allocate the recreational effort to each of the waves*/


mata:
recreational_effort_waves = (1,0 \ 2,0.0 \ 3,0.28 \ 4,0.60 \ 5, 0.09 \ 6, 0.00)
recreational_effort_months = (1,0.0 \ 2,0.0 \ 3, 0.00 \ 4,0.005 \ 5, 0.106 \ 6, 0.266 \ 7 ,0.254 \ 8, .259 \ 9 , .052 \10, .033 \ 11, .025 \ 12,0.00)   
end

mata: recreational_effort_waves = J(10,1,recreational_effort_waves)
mata: recreational_effort_monthly = J(10,1,recreational_effort_months) 


