global imax=$cmax_age-1

mata:

 cod_end_of_wave_counts$current_wave=cod_end_of_cm-rec_dead_cod

/*fix any negative age classes by moving them to adjacent age classes 
Although negative age classes should not be possible at this stage*/
iter2=0
do {
for(i=2;i<=$imax;i++){
	if (cod_end_of_wave_counts$current_wave[i]<0){
		cod_end_of_wave_counts$current_wave[i+1]=cod_end_of_wave_counts$current_wave[i+1]+.5*cod_end_of_wave_counts$current_wave[i]
		cod_end_of_wave_counts$current_wave[i-1]=cod_end_of_wave_counts$current_wave[i-1]+.5*cod_end_of_wave_counts$current_wave[i]
		cod_end_of_wave_counts$current_wave[i]=0
	}
}


	if (cod_end_of_wave_counts$current_wave[1]<0){
		cod_end_of_wave_counts$current_wave[2]=cod_end_of_wave_counts$current_wave[2]+cod_end_of_wave_counts$current_wave[1]
		cod_end_of_wave_counts$current_wave[1]=0
}
	if (cod_end_of_wave_counts$current_wave[$cmax_age]<0){
		cod_end_of_wave_counts$current_wave[$cmax_age-1]=cod_end_of_wave_counts$current_wave[$cmax_age-1]+cod_end_of_wave_counts$current_wave[$cmax_age]
		cod_end_of_wave_counts$current_wave[$cmax_age]=0
}
	iter2=iter2+1
}while (iter2<=2)


end

