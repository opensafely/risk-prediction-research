********************************************************************************
*
*	Do-file:			701_rp_cii_covid_validation_intext.do
*
*	Written by:			Fizz
*
*	Data used:			data/cr_daily_landmark_covid.dta
*
*	Data created:		data/model_cii_covid_`tvc'_`r'.dta
*							where tvc = foi, ae or susp.
*
*	Other output:		Log file:  	701_rp_cii_covid_validation_intext_`tvc'_`r'.log
*						Estimates:	coefs_cii_`tvc'_`r'.ster
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
log using "./output/701_rp_cii_covid_validation_intext_`tvc'", text replace



*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"




* Cycle over regions & time
forvalues r = 1 (1) 8 {



	***************
	*  Open data  *
	***************

	* Open daily landmark data for COVID-19 death
	use "data/cr_daily_landmark_covid.dta", clear


		* Delete one region 
		if `r'<8 {
			drop if region_7==`r'
		}
		if `r'==8 { // Analyse only data in period: 1 March-11 May 
			drop if time>71
		}


	*********************
	*   Poisson Model   *
	*********************

	capture erase output/models/coefs_cii_`tvc'_`r'.ster

	* Fit model
	timer clear 1
	timer on 1
	poisson onscoviddeath ${selected_vars_landmark_`tvc'}	///
		[pweight=sf_wts], 									///
		robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1

	estimates save output/models/coefs_cii_`tvc'_`r', replace



	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************


	* Pick up coefficient matrix
	matrix b = e(b)


	/*  Save coefficients to Stata dataset  */

	qui do "analysis/0000_pick_up_coefficients.do"
	get_coefs, coef_matrix(b) eqname("onscoviddeath:")  ///
		dataname("data/model_cii_covid_`tvc'_`r'")

}

* Close log file
log close
