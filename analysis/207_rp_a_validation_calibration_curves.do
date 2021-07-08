********************************************************************************
*
*	Do-file:		207_rp_a_validation_calibration_curves.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH.dta
*						model_a_roy.dta
*						model_a_weibull.dta
*						model_a_ggamma.dta
*
*	Data created:	data/approach_a_validation.dta
*					output/approach_a_validation_28day.out
*
*	Other output:	Log file:  	output/207_rp_a_validation_calibration_curves.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


* Read in output from each model

* Open a log file
capture log close
log using "./output/207_rp_a_validation_calibration_curves", text replace


* Ensure cc_calib is available
do "analysis/ado/cc_calib.ado"
do "analysis/ado/calibrationbelt.ado"




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Cox model  */

use "data/model_a_coxPH", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_a_cox_nos = coef[1]

* Pick up HRs
qui count
global nt_a_cox_nos = r(N) - 1
forvalues j = 1 (1) $nt_a_cox_nos {
	local k = `j' + 1
	global coef`j'_a_cox_nos = coef[`k']
	global varexpress`j'_a_cox_nos = varexpress[`k']
}




******************************
*  Open validation datasets  *
******************************


*forvalues i = 1/3 {
local i = 1
	use "data/cr_cohort_vp`i'.dta", clear
	
	* Pick up list of variables in model
	do "analysis/101_pr_variable_selection_output.do"
	noi di "$bn_terms"
	
	/*   Cox model   */

	gen xb = 0
	forvalues j = 1 (1) $nt_a_cox_nos {
		replace xb = xb + ${coef`j'_a_cox_nos}*${varexpress`j'_a_cox_nos}	
	}
	gen pred_a_cox_nos = 1 -  (${bs_a_cox_nos})^exp(xb)
	drop xb


	
	**************************
	*   Validation measures  *
	**************************

	calibrationbelt onscoviddeath28 pred_a_cox_nos, devel("internal")

}





* Close log file
log close




