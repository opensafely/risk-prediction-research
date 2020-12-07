********************************************************************************
*
*	Do-file:			401_rp_cii_covid.do
*
*	Written by:			Fizz
*
*	Data used:			data/cr_daily_landmark_covid.dta
*
*	Data created:		data/model_cii_poisson_`tvc'.dta
*							where tvc = foi, ae or susp.
*
*	Other output:		Log file:  	401_rp_cii_covid_`tvc'.log
*						Estimates:	coefs_cii_`tvc'.ster
*
********************************************************************************
*
*	Purpose:			To fit daily Poisson regression models for COVID-19 
*						death, incorporating measures of the burden of disease,
*						specifically, the force of infection, A&E attendances, 
*						and suspected COVID-19 cases in primary care.
*
********************************************************************************



* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/401_rp_cii_covid_`tvc'", text replace



*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"






***************
*  Open data  *
***************

* Open daily landmark data for COVID-19 death
use "data/cr_daily_landmark_covid.dta", clear




*********************
*   Poisson Model   *
*********************

capture erase output/models/coefs_cii_`tvc'.ster

* Fit model
timer clear 1
timer on 1
poisson onscoviddeath ${selected_vars_landmark_`tvc'}	///
	[pweight=sf_wts], 									///
	robust cluster(patient_id) 
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_cii_`tvc', replace



***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************


* Pick up coefficient matrix
matrix b = e(b)


/*  Save coefficients to Stata dataset  */

qui do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath:")  ///
	dataname("data/model_cii_`tvc'")



* Close log file
log close
