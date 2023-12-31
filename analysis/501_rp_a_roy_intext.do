********************************************************************************
*
*	Do-file:		501_rp_a_roy_intext.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_roy_`r'.dta, for r=1,2,...,8  
*
*	Other output:	Log file:  output/501_rp_a_roy_intext.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the 
*					Royston-Parmar flexible hazard modelling for the
*					leave-one-out internal external validation process.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************




* Open a log file
capture log close
log using "./output/501_rp_a_roy_intext", text replace


***************************************
*  Ensure correct files for RP model  *
***************************************

capture do "analysis/ado/s/stpm2_matacode.mata"


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




	****************************
	*  Pick up predictor list  *
	****************************

	qui do "analysis/101_pr_variable_selection_output.do" 
	noi di "${selected_vars_nobn_`r'}"
	noi di "$bn_terms_`r'"



	*************************************************
	*  Transform selected_vars for Roy Parmar model *
	*************************************************

	foreach var of global bn_terms_`r' {
		* Remove bn
		local term = subinstr("`var'", "bn", "", .)
		* remove "." from name
		local term = subinstr("`term'", ".", "", .)
		* Check if its an interaction term and remove # if needed 
		local term = subinstr("`term'", "#", "", .)
		* add _
		local term = "__" + "`term'" 
		local term = substr("`term'", 1, 15)
		fvrevar `var', stub(`term')
	}



	********************
	*   Royston Model  *
	********************
	* df(5) -> 4 knots at centile positions 20 40 60 80

	timer clear 1
	timer on 1
	stpm2 ${selected_vars_nobn_`r'} __* , df(5) scale(hazard) vce(robust)
	estat ic
	timer off 1
	timer list 1


	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************

	* Pick up coefficient matrix
	matrix b = e(b)
	mat list b

	local cols = (colsof(b) + 1)/2
	local cols2 = `cols' +3
	mat c = b[1,`cols2'..colsof(b)]
	mat list c

	*  Calculate baseline survivals
	* 28 day
	gen time = 28
	predict s0, survival timevar(time) zeros 
	summ s0 
	global base_surv28 = `r(min)' 
	drop time s0

	* 100 day
	gen time = 100
	predict s0, survival timevar(time) zeros 
	summ s0 
	global base_surv100 = `r(min)' 
	drop time s0

	* Add baseline survival to matrix (and add a matrix column name)
	matrix c = [$base_surv28, $base_surv100, c]
	local names: colfullnames c
	local names: subinstr local names "c1" "xb0:base_surv28"
	local names: subinstr local names "c2" "xb0:base_surv100"
	mat colnames c = `names'

	*  Save coefficients to Stata dataset  
	qui do "analysis/0000_pick_up_coefficients.do"

	* Save coeficients needed for prediction models
	get_coefs, coef_matrix(c) eqname("xb0:") ///
		dataname("data/model_a_roy_`r'")
		
	* Remove unnecessary coefficients	
	use "data/model_a_roy_`r'", clear
	drop if strpos(term,"_s0_")>0
	save "data/model_a_roy_`r'", replace 


}

* Save log file
log close

	