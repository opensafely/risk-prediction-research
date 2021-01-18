********************************************************************************
*
*	Do-file:		1200_rp_b_poisson_agesex.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_`tvc'_agesex.dta, 
*						where tvc=foi, ae, susp, all, objective
*
*	Other output:	Log file:  	output/1200_rp_b_poisson_agesex.log
*					Estimates:	output/models/coefs_b_pois_`tvc'_agesex.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases, their combination, and the 
*					two objective measures, using only age and sex 
*					as covariates.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/1200_rp_b_poisson_agesex", text replace



****************************
*  TVC-related predictors  *
****************************

global tvc_foi  = "c.logfoi c.foi_q_day c.foi_q_daysq c.foiqd c.foiqds" 
global tvc_ae   = "c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2"
global tvc_susp = "c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2"

global tvc_all  = "c.logfoi c.foi_q_day c.foi_q_daysq c.foiqd c.foiqds c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2 c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2" 
global tvc_objective = "c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2 c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2" 




***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark.dta", clear




********************************
*   Create covariates needed   *
********************************

* Create finer age categories
recode age min/39  = 1	///
			40/49  = 2	///
			50/59  = 3	///
			60/64  = 4	///
			65/69  = 5	///
			70/74  = 6	///
			75/79  = 7	///
			80/84  = 8	///
			85/89  = 9	///
			90/max = 10	///
			, gen(agegroup_fine)

label define agegroup_fine ///
			1 "<40"		///
			2 "40-49"	///
			3 "50-59"	///
			4 "60-64"	///
			5 "65-69"	///
			6 "70-74"	///
			7 "75-79"	///
			8 "80-84"	///
			9 "85-89"	///
			10 "90+"
			
label values agegroup_fine agegroup_fine



*********************
*   Poisson Model   *
*********************

* Loop over the sets of time-varying covariates
foreach tvc in foi ae susp all objective {

	capture erase output/models/coefs_b_pois_`tvc'_agesex.ster

	* Fit model
	timer clear 1
	timer on 1
	streg ${tvc_`tvc'} i.male##i.agegroup_fine, dist(exp) ///
		robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1

	estimates save output/models/coefs_b_pois_`tvc'_agesex, replace



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
		dataname("data/model_b_poisson_`tvc'_agesex")

}


* Close log file
log close
