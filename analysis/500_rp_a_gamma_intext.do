********************************************************************************
*
*	Do-file:		500_rp_a_gamma_intext.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_ggamma_`r'.dta, for r=1,2,...,8  
*
*	Other output:	Log file:  output/200_rp_a_gamma.log
*
********************************************************************************
*
*	Purpose:		This do-file performs generalized gamma survival models (AFT) 
*					for the leave-one-out internal external validation process.
*  
********************************************************************************



* Open a log file
capture log close
log using "./output/200_rp_a_gamma", text replace


* Cycle over regions & time
forvalues r = 1 (1) 8 {
		
		
	************************************
	*  Open dataset for model fitting  *
	************************************

	use "data/cr_casecohort_models.dta", replace

	* Delete one region 
	if `r'<8 {
		drop if region_7==`r'
	}
	if `r'==8 { // Analyse only time period: 1 March-11 May
		
		* Censor all non-cases at 11 May (inc. subcohort cases prior to event)
		local lastday = d(11may2020) - d(1mar2020) + 1
		replace dayout = `lastday' if dayout>`lastday' & onscoviddeath==0
		
		* Censor (delete) cases that occurred after 11 May
		drop if onscoviddeath==1 & dayout > `lastday'
		
		* Re-stset
		sort newid
		stset dayout [pweight=sf_wts], fail(onscoviddeath) enter(dayin) id(newid)  
	}



	*******************************
	*  Pick up predictor list(s)  *
	*******************************

	qui do "analysis/107_pr_variable_selection_intext_output.do" 
	noi di "${selected_vars_`r'}"

	
	
	***********************
	*   Generalised gamma *
	***********************

	timer clear 1
	timer on 1
	streg ${selected_vars_`r'}, dist(ggamma) vce(robust) difficult
	estat ic
	timer off 1
	timer list 1

	
	
	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************

	* Pick up coefficient matrix
	matrix b = e(b)

	* Pick up sigma/kappa
	global sigma = e(sigma)
	global kappa = e(kappa)

	di $sigma
	di $kappa

	* Add baseline survival to matrix (and add a matrix column name)
	matrix b = [$sigma, $kappa, b]
	local names: colfullnames b
	local names: subinstr local names "c1" "_t:sigma"
	local names: subinstr local names "c2" "_t:kappa"
	mat colnames b = `names'

	* Remove unneeded parameters from matrix
	local np = colsof(b) - 2 // remove lnsigma kappa
	matrix b = b[1,1..`np']
	matrix list b

	*  Save coefficients to Stata dataset  
	qui do "analysis/0000_pick_up_coefficients.do"

	* Save coeficients needed for prediction
	get_coefs, coef_matrix(b) eqname("_t:") dataname("data/model_a_ggamma_`r'")


}

* Close log file
log close




