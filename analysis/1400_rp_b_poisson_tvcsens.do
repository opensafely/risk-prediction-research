********************************************************************************
*
*	Do-file:		1400_rp_b_poisson_tvcsens.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark_noupdate.dta
*
*	Data created:	data/model_b_poisson_`tvc'_tvc`form'.dta,
*							where tvc  = foi, ae, susp
*							and   form = fixed or none
*
*	Other output:	Log file:  	output/1400_rp_b_poisson_`tvc'_tvcsens.log
*					Estimates:	output/models/coefs_b_pois_`tvc'_tvc`form'.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases; for the sensitivity analysis
*					in which (i) time-varying covariates are fixed at baseline
*					(i.e. diabetes, etc. not updated), and (ii) time-varying
*					measures of the burden of disease are omitted.
*
********************************************************************************


* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/1400_rp_b_poisson_`tvc'_tvcsens", text replace



*******************************
*  Pick up predictor list(s)  *
*******************************

* Time varying covariates included in models
global tvc_foi  = "c.logfoi c.foi_q_day c.foi_q_daysq c.foiqd c.foiqds" 
global tvc_ae   = "c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2"
global tvc_susp = "c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2"

* Pick up full covariate lists
qui do "analysis/104_pr_variable_selection_landmark_output.do" 
global tvc_fixed = "${selected_vars_landmark_`tvc'}"
noi di "$tvc_fixed"

* Remove the TVC variables
global tvc_none: list global(selected_vars_landmark_`tvc') - global(tvc_`tvc')
noi di "$tvc_none"



***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark_noupdate.dta", clear




*********************
*   Poisson Model   *
*********************

foreach form in fixed none {

	* Fit model with TVCs fixed at baseline / absent
	capture erase output/models/coefs_b_pois_`tvc'_tvc`form'.ster

	timer clear 1
	timer on 1
	streg ${tvc_`form'}, dist(exp) ///
		robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1

	estimates save output/models/coefs_b_pois_`tvc'_tvc`form', replace



	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************


	* Pick up coefficient matrix
	matrix b = e(b)

	*  Calculate baseline survival 
	global base_surv28 = exp(-28*exp(_b[_cons]))

	* Add baseline survival to matrix (and add a matrix column name)
	matrix b = [$base_surv28, b]
	local names: colfullnames b
	local names: subinstr local names "c1" "_t:base_surv28"
	mat colnames b = `names'


	/*  Save coefficients to Stata dataset  */

	qui do "analysis/0000_pick_up_coefficients.do"
	get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
		dataname("data/model_b_poisson_`tvc'_tvc`form'")

}


* Close log file
log close
