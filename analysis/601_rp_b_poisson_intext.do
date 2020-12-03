********************************************************************************
*
*	Do-file:		601_rp_b_poisson_intext.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_`tvc'_`r'.dta, where tvc=foi, ae, susp
*									and r = 1, 2, 3, ..., 8
*
*	Other output:	Log file:  			output/601_rp_b_poisson_intext_`tvc'.log
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases, for the internal-external
*					validation (leaving out one region at a time, then 
* 					omitting the later time period). 
*
********************************************************************************



* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/601_rp_b_poisson_intext_`tvc'", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"


* Cycle over regions & time
forvalues r = 1 (1) 8 {
	


		
	************************************
	*  Open dataset for model fitting  *
	************************************

		
	* Open landmark data
	use "data/cr_landmark.dta", clear
	
	
	* Delete one region 
	if `r'<8 {
		drop if region_7==`r'
	}
	if `r'==8 { // Analyse only data in period: 1 March-11 May (first 45 landmark sub-studies)
		drop if time>45
	}

	


	*********************
	*   Poisson Model   *
	*********************


	* Fit model
	timer clear 1
	timer on 1
	streg ${selected_vars_landmark_`tvc'}, dist(exp) ///
		robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1





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
		dataname("data/model_b_poisson_`tvc'_`r'")

}


* Close log file
log close
