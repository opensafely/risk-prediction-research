********************************************************************************
*
*	Do-file:			402_rp_cii_allcause.do
*
*	Written by:			Fizz
*
*	Data used:			data/cr_daily_landmark_noncovid.dta
*
*	Data created:		data/model_cii_allcause_`tvc'.dta
*							where tvc = foi, ae or susp.
*
*	Other output:		Log file:  	402_rp_cii_allcause_`tvc'.log
*						Estimates:	coefs_cii_allcause_`tvc'.ster
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
log using "./output/402_rp_cii_allcause_`tvc'", text replace



****************************
*  Pick up predictor list  *
****************************

qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"

* Remove all variables relating to the burden of COVID-19 infection
global tvc_foi  = "logfoi foi_q_day foi_q_daysq foiqd foiqds" 
global tvc_ae   = "logae ae_q_day ae_q_daysq aeqd aeqds aeqds2"
global tvc_susp = "logsusp susp_q_day susp_q_daysq suspqd suspqds suspqds2"


global selecvars = "${selected_vars_landmark_`tvc'}"
global noncovidvars: list global(selecvars)    - global(tvc_foi) 
global noncovidvars: list global(noncovidvars) - global(tvc_ae) 
global noncovidvars: list global(noncovidvars) - global(tvc_susp)

noi di "Non-COVID-19 variables (TVC: `tvc')"
noi di "$noncovidvars" 

* Remove some variables which cause convergence problems
global problemvars = "2bn.cancerExhaem##c.agec 3bn.cancerExhaem##c.agec 4bn.cancerExhaem##c.agec 1bn.smi##c.agec 1bn.dialysis##c.agec"
global noncovidvars: list global(noncovidvars) - global(problemvars)

noi di "Non-COVID-19 variables (TVC: `tvc')"
noi di "$noncovidvars" 



***************
*  Open data  *
***************

* Open landmark data
use "data/cr_daily_landmark_noncovid.dta", clear




*********************
*   Poisson Model   *
*********************

capture erase output/models/coefs_cii_allcause_`tvc'.ster

* Fit model
timer clear 1
timer on 1
poisson onsotherdeath $noncovidvars			///
	[pweight=sf_wts], 						///
	robust cluster(patient_id) 
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_cii_allcause_`tvc', replace



***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************


* Pick up coefficient matrix
matrix b = e(b)


/*  Save coefficients to Stata dataset  */

qui do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onsotherdeath:")  ///
	dataname("data/model_cii_allcause_`tvc'")



* Close log file
log close
