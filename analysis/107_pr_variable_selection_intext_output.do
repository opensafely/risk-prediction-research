
********************************************************************************
*
*	Do-file:			107_pr_variable_selection_intext_output.do
*
*	Written by:			Fizz & John
*
*	Data used:			data\cr_selected_model_coefficients.dta
*
*	Data created:		None (selected model held in globals)
*
*	Other output:		Global macros (used in subsequent analysis do-files)
*							$selectedvars (contains predictors for approach A)
*
********************************************************************************
*
*	Purpose:			This do-file takes the predictors selected in the 
*						previous do-file (from a lasso procedure) and stores
*						the predictors in a global macro.
*
********************************************************************************






*****************************************************
*  Approach A:  Model selected via lasso procedure  *
*****************************************************


preserve

forvalues r = 1 (1) 8 {

	if `r'< 8 & `r'!=3 {
	    * Leave-one-out: regional
		use "data/cr_selected_model_coefficients_`r'.dta", clear
	}
	else if `r'==3 {		// Use overall model since lasso did not converge
		use "data/cr_selected_model_coefficients.dta", clear
	}
	else if `r'==8 {
		* Leave-one-out: temporal
		use "data/cr_selected_model_coefficients_time.dta", clear	    
	}
	
	qui count
	local nparam_`r' = r(N)

	global selected_vars_`r' 		= ""
	global selected_vars_nobn_`r' 	= ""
	global bn_terms_`r' 			= "" 

	forvalues i = 1 (1) `nparam_`r'' {
		local term = variable[`i']
		global selected_vars_`r' = "${selected_vars_`r'}" + " " + "`term'"

		* Separate out bits with bn in the name
		if strpos("`term'", "bn") > 1 {
			global bn_terms_`r' = "${bn_terms_`r'}" + " " + "`term'"
		}
		else{
			global selected_vars_nobn_`r' = "${selected_vars_nobn_`r'}" + " " + "`term'"
		}	
	}

	noi di "Approach A, Model selected (lasso), internal-external validation: " 
	if `r'<8 {
	    noi di "Omitting region `r'"
	}
	else if `r'==8 {
	    noi di "Omitting later time period"
	}
	noi di "${selected_vars_`r'}"

	noi di "Separated out for Roy-Parmar model fitting:"
	noi di "${selected_vars_nobn_`r'}"
	noi di "${bn_terms_`r'}"
}

restore


