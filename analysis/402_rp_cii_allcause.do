********************************************************************************
*
*	Do-file:			402_rp_cii_allcause.do
*
*	Written by:			Fizz
*
*	Data used:			data/cr_daily_landmark_noncovid.dta
*
*	Data created:		data/model_cii_poisson_`tvc'.dta
*							where tvc = foi, ae or susp.
*
*	Other output:		Log file:  	402_rp_cii_allcause.log
*						Estimates:	coefs_cii_allcause.ster
*
********************************************************************************
*
*	Purpose:			To fit daily Poisson regression models for COVID-19 
*						death, incorporating measures of the burden of disease,
*						specifically, the force of infection, A&E attendances, 
*						and suspected COVID-19 cases in primary care.
*
********************************************************************************


* Open a log file
capture log close
log using "./output/402_rp_cii_allcause", text replace



****************************
*  Pick up predictor list  *
****************************

qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"

* Remove all variables relating to the burden of COVID-19 infection
global foivars  = "foi logfoi foi_q_cons foi_q_day foi_q_daysq foiqd foiqds"
global aevars   = "aerate aepos logae ae_q_cons ae_q_day ae_q_daysq aeqd aeqds aeqint aeqd2 aeqds2"
global suspvars = "susp_rate_init susppos logsusp susp_q_cons susp_q_day susp_q_daysq suspqd suspqds suspqint suspqd2 suspqds2"

global selecvars = "${selected_vars_landmark_`tvc'}"
global noncovidvars: list global(selecvars)    - global(foivars) 
global noncovidvars: list global(noncovidvars) - global(aevars) 
global noncovidvars: list global(noncovidvars) - global(suspvars)




***************
*  Open data  *
***************

* Open landmark data
use "data/cr_daily_landmark_noncovid.dta", clear




*********************
*   Poisson Model   *
*********************

capture erase output/models/coefs_cii_allcause.ster

* Fit model
timer clear 1
timer on 1
poisson onsotherdeath $noncovidvars			///
	[pweight=sf_wts], 						///
	robust cluster(patient_id) 
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_cii_allcause, replace



***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************


* Pick up coefficient matrix
matrix b = e(b)


/*  Save coefficients to Stata dataset  */

qui do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onsotherdeath:")  ///
	dataname("data/model_cii_allcause")



* Close log file
log close
