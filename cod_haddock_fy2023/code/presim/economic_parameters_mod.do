
/* These are some Economic parameters */
/* We need to change these based on the Holzer and McConnell parameters */
/* This is the Probability Mass Function of shore, boat, party/head, and charter  See section WTP */

scalar shore=0.20
scalar boat=0.20
scalar party=0.20
scalar charter=0.40

/* This is the Probability Mass Function of Trip lengthSee section WTP */
scalar hour4=0.5
scalar hour8= 0.4
scalar hour12=0.1

/* These are scalars for the marginal and total costs of various types trips */
/* TC is total cost per trip, c is "pseudo-"marginal cost of trip length */
scalar c_chart=30
scalar c_party=11
scalar tc_boat=165
scalar tc_shore=105

/* logit coefficients
Model 2 from Holzer and McConnell */
global pi_cod_keep 0.3127457 
global pi_cod_release 0
global pi_hadd_keep 0.3653523 
global pi_hadd_release 0 
global pi_cost "-0.0015785"
global pi_trip_length 0.0911496
global pi_trip_length2 0



/* mixed logit coefficients
Table 9 from Carr-Harris and Steinback */
global pi_cod_keep 0.957
global pi_cod_release 0.168
global pi_hadd_keep 0.703
global pi_hadd_release 0.083 
global pi_cost "-0.015"
global pi_trip_length 0
global pi_trip_length2 0

/*Ignoring the standard deviation parameters.  Ignoring the opt out parameters. And trip length is NS, so, i will just enter them both as zeros. */










/* Econ parameters: 
how many fish can be caught on a trip 
maximum age */
global cod_upper_bound 40
global haddock_upper_bound 40


global calibration_end 2022
global this_year=year(date("$S_DATE","DMY"))
global this_year=2022


/* don't change this line .  You are storing a bigger matrix of commercial catch and rec regulations. these couple of lines just exclude the 'old' years, prior to the calibration years */ 
global year_junk=2011 

/* Think carefully when you change this line. */ 
global rec_junk=$calibration_end-2

global comm_month_starter=$periods_per_year*($which_year-$year_junk)+1
global rec_month_starter=$periods_per_year*($which_year-$rec_junk)+1


/* set years for age-length keys */

/* Age-length key years*/
 global lcalibration_start 2017
 global lcalibration_end 2022

/* set years for historical effort calibration params*/
 global rec_cal_start=2022
 global rec_cal_end=2022
 
 /* Commercial grabber years
The commercial helper is set up to extract earlier FISHING YEARS */
 global commercial_calibrate_start=$calibration_end
 global commercial_calibrate_end=$calibration_end

 global commercial_grab_start=$calibration_end-2
 global commercial_grab_end=$calibration_end




/* Retention of sub-legal fish */
/* cod_relax: window below the minimum size that anglers might retain sublegal fish */
/* cod_sublegal_keep: probability that an angler will retain a sublegal cod in that size window*/

/* Retention of sub-legal fish */
/* This is coded in 2 parts -- We assume that fish that are "close" to the minimum size have a higher probability of being retained */
/* cod_relax: This defines "small" and "tiny" (along with the minimium size) */
/* cod_sublegal_keep: probability that an angler will retain a sublegal cod that is "small"*/
/* cod_sublegal_keep2: probability that an angler will retain a sublegal cod that is "tiny" */

/* Cod sub-legals in waves 1,2 */
global cod_relax_mjj=2
/* Cod sub-legals after wave 2 */

global cod_relax_main=2
global cod_sublegal_low=.005
global cod_sublegal_hi=.20+$cod_sublegal_low



/* hadd_relax: This defines "small" and "tiny" (along with the minimium size) */
/* haddock_sublegal_keep: probability that an angler will retain a sublegal haddock that is "small"*/
/* haddock_sublegal_keep: probability that an angler will retain a sublegal haddock that is "tiny"*/

/* haddock sub-legals in waves 1,2 */

global hadd_relax_mjj=0
/* haddock sub-legals after wave 2 */
global hadd_relax_main=2

global haddock_sublegal_low=0.01
global haddock_sublegal_hi=0.05+$haddock_sublegal_low



/* discard of legal sized fish. Don't think this does anything */
global dl_cod=0
global dl_hadd=0




/* Ignoring the Possession Limit */
/* For GOM Cod, approximately 1.5% of trips which kept cod kept more than the 10 fish possession limit */
/* These 11th and higher fish caught on these trips were responsible for 5.5% of all kept cod (by numbers).*/
/* In order to address this, i'll set 2 globals which are the probability which an angler will `comply with the bag limit'  */

global pcbag_comply=.90
global phbag_comply=.99


global pcbag_non=1-$pcbag_comply
global phbag_non=1-$phbag_comply
