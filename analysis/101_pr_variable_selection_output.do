
********************************************************************************
*
*	Do-file:			101_pr_variable_selection_output.do
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
use "data/cr_selected_model_coefficients.dta", clear

qui count
local nparam = r(N)


global selected_vars 		= ""
global selected_vars_nobn 	= ""
global bn_terms 			= "" 

forvalues i = 1 (1) `nparam' {
    local term = variable[`i']
	global selected_vars = "$selected_vars" + " " + "`term'"

	* Separate out bits with bn in the name
	if strpos("`term'", "bn") > 1 {
		global bn_terms = "$bn_terms" + " " + "`term'"
	}
	else{
		global selected_vars_nobn = "$selected_vars_nobn" + " " + "`term'"
	}	
}

noi di "Approach A, Model selected (lasso): " 
noi di "$selected_vars"

noi di "Separated out for Roy-Parmar model fitting:"
noi di "$selected_vars_nobn"
noi di "$bn_terms"
restore


