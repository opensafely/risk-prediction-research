********************************************************************************
*
*	Do-file:			400_rp_ci.do
*
*	Written by:			Fizz
*
*	Data used:			data/
*							cr_landmark.dta
*							foi_coefs.dta
*							ae_coefs.dta
*							susp_coefs.dta
*
*	Data created:		data/model_ci_`tvc'.dta
*							where tvc = foi, ae or susp.
*
*	Other output:		Log file:  	400_rp_ci_`tvc'.log
*						Estimates:	coefs_ci_`tvc'.ster
*
********************************************************************************
*
*	Purpose:			To fit Poisson models to the landmark datasets, allowing
*						the measures of the burden of disease to update weekly
*						through the month. Three measures are used: the force
*						of infection, A&E attendances and GP suspected COVID-19
*						cases.
*
********************************************************************************



* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/400_rp_ci_`tvc'", text replace



*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"



***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark.dta", clear

* Drop time varying variables
drop 	foi logfoi foi_q_cons foi_q_day foi_q_daysq foiqd foiqds 	///
		aerate aepos logae ae_q_cons ae_q_day ae_q_daysq aeqd 		///
		aeqds aeqint aeqd2 aeqds2 susp_rate_init susppos logsusp 	///
		susp_q_cons susp_q_day susp_q_daysq suspqd suspqds 			///
		suspqint suspqd2 suspqds2

* Split into the different weeks
stsplit timeband, at(0 (7) 28)
recode timeband 0=1 7=2 14=3 21=4, gen(week)
drop timeband

* Create time variable which updates through the period
gen 	timeupdate = time 
replace timeupdate = time + 7  if week==2
replace timeupdate = time + 14 if week==3
replace timeupdate = time + 21 if week==4
drop time
rename timeupdate time



****************************************
*  Add in time-varying infection data  *
****************************************


if "`tvc'"=="foi" {
	recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
			50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
			gen(agegroupfoi)
			
	* Merge in the force of infection data
	merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
		assert(match using) keep(match) nogen 
	drop agegroupfoi
}
else if "`tvc'"=="ae" {
	* Merge in the A&E STP count data
	merge m:1 time stp_combined using "data/ae_coefs", ///
		assert(match using) keep(match) nogen
} 
else if "`tvc'"=="susp" {
	* Merge in the GP suspected COVID case data
	merge m:1 time stp_combined using "data/susp_coefs", ///
		assert(match using) keep(match) nogen
}



*********************
*   Poisson Model   *
*********************

capture erase output/models/coefs_ci_`tvc'.ster

* Fit model
timer clear 1
timer on 1
streg ${selected_vars_landmark_`tvc'}, dist(exp) ///
	robust cluster(patient_id) 
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_ci_`tvc', replace



***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************


* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
global base_surv7 = exp(-7*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv7, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv7"
mat colnames b = `names'


/*  Save coefficients to Stata dataset  */

qui do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
	dataname("data/model_ci_`tvc'")



* Close log file
log close
