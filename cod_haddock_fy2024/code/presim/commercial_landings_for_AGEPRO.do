/*Data setup */
clear
mata:mata clear
scalar drop _all
matrix drop _all

set seed  4160

/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){
	global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2024" 
	global MRIP_dir  "V:/READ-SSB-Lee-MRIP-BLAST/data_folder/main/MRIP_2023_11_07" 
	global 	oracle_cxn  " $mysole_conn"
}





global code_dir "${project_dir}/code"
global source_data "${project_dir}/source_data"
global mrip_source_data "${project_dir}/mrip"

global working_data "${project_dir}/working_data"
global output_dir "${project_dir}/output"







global codalkey "${working_data}/cod_al_key.dta"
global haddalkey "${working_data}/haddock_al_key9max.dta"

/************These come from the preamble to the blast model wrapper. Not all are needed***************************************/

global which_year=2023

global calibration_end 2023
global this_year=year(date("$S_DATE","DMY"))
global this_year=2023
global months=12
global periods_per_year=$months


/* don't change these two lines.  You are storing a bigger matrix of commercial catch and rec regulations. these couple of lines just exclude the 'old' years, prior to the calibration years */ 
global year_junk=2011 
global rec_junk=$calibration_end-1

global comm_month_starter=$periods_per_year*($which_year-$year_junk)+1
global rec_month_starter=$periods_per_year*($which_year-$rec_junk)+1



/* set calendar years for age-length keys */

/* Age-length key years*/
 global lcalibration_start 2018
 global lcalibration_end 2023	

/* set years for historical effort calibration params*/
 global rec_cal_start=$calibration_end
 global rec_cal_end=$calibration_end
 
 /* Commercial grabber years
The commercial helper is set up to extract the 2016 FISHING YEAR */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-3
 global commercial_grab_end=$calibration_end


/* commercial monthly catch */
do "${code_dir}/presim/commercial_monthly_helper.do"



