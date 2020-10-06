********************************************************************************
*
*	Do-file:			100_pr_variable_selection_output.do
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



* Open a log file
cap log close
log using "output/100_pr_variable_selection_output", replace t





*****************************************************
*  Approach A:  Model selected via lasso procedure  *
*****************************************************

use "data\cr_selected_model_coefficients.dta", clear

qui count
local nparam = r(N)


global selected_vars = ""

forvalues i = 1 (1) `nparam' {
    local term = variable[`i']
	noi di "`term'"
	global selected_vars = "$selected_vars" + " " + "`term'"
}

noi di "Approach A, Model selected (lasso): " 
noi di "$selected_vars"




