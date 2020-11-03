********************************************************************************
*
*	Do-file:			104_pr_variable_selection_landmark_output.do
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



local foi_title  = "force of infection data"
local ae_title   = "A&E attendance data"
local susp_title = "GP suspected case data"


foreach tvc in foi ae susp {

	preserve
	use "data/cr_selected_model_coefficients_landmark_`tvc'.dta", replace

	qui count
	local nparam = r(N)


	global selected_vars_tvc = ""

	forvalues i = 1 (1) `nparam' {
		local term = variable[`i']
		global selected_vars = "$selected_vars" + " " + "`term'"
	}

	noi di "Approach B, Model selected (lasso) for models using ``tvc'_title': " 
	noi di "$selected_vars_landmark_`tvc'"
	restore

}

