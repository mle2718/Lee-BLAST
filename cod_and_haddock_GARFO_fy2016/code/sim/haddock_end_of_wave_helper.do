global imax=$hmax_age-1

mata: 
	haddock_end_of_wave_counts$current_wave=haddock_end_of_period-rec_dead_haddock

do {
for(i=2;i<=$imax;i++){
	if (haddock_end_of_wave_counts$current_wave[i]<0){
		haddock_end_of_wave_counts$current_wave[i+1]=haddock_end_of_wave_counts$current_wave[i+1]+.5*haddock_end_of_wave_counts$current_wave[i]
		haddock_end_of_wave_counts$current_wave[i-1]=haddock_end_of_wave_counts$current_wave[i-1]+.5*haddock_end_of_wave_counts$current_wave[i]
		haddock_end_of_wave_counts$current_wave[i]=0
	}
}


	if (haddock_end_of_wave_counts$current_wave[1]<0){
		haddock_end_of_wave_counts$current_wave[2]=haddock_end_of_wave_counts$current_wave[2]+haddock_end_of_wave_counts$current_wave[1]
		haddock_end_of_wave_counts$current_wave[1]=0
}
	if (haddock_end_of_wave_counts$current_wave[$hmax_age]<0){
		haddock_end_of_wave_counts$current_wave[$hmax_age-1]=haddock_end_of_wave_counts$current_wave[$hmax_age-1]+haddock_end_of_wave_counts$current_wave[$hmax_age]
		haddock_end_of_wave_counts$current_wave[$hmax_age]=0
}
	iter2=iter2+1
}while (iter2<=2)





end
