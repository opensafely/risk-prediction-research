********************************************************************************
*
*	Do-file:		902_rp_a_coxPH_all.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_coxPH_all.dta
*
*	Other output:	Log file:  	output/900_rp_a_coxPH_all.log
*					Estimates:	output/models/coefs_a_cox_all.ster
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model using all the selected covariates and additionally
*					including excluded categories from categorical variables.
*
********************************************************************************


* Open a log file
capture log close
log using "./output/902_rp_a_coxPH_all", text replace




************************************
*  Open dataset for model fitting  *
************************************

use "data/cr_casecohort_models.dta", replace



****************************
*  Pick up predictor list  *
****************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$selected_vars"


* Program to extract full categories selected
capture program drop all_terms
program define all_terms, rclass
	syntax , selected_vars(string) 

	tokenize ${`selected_vars'}
	
	global new_terms = ""
	local i = 1
	local j = 1
	while "``i''" != "" {
		local term = "``i''"	
		
		* Change hashes to double 
		local term = subinstr("`term'", "#", "##", .)
		
		* Change specific category labels to generic ones
		forvalues k = 0 (1) 9 {
			local term = subinstr("`term'", "`k'bn.", "i.", 2)
		}
		
		global new_terms = "$new_terms" + " " + "`term'"
		local i = `i' + 1
	}
	
	return local new_terms = "$new_terms"
end


* Extract richer covariate list
all_terms, selected_vars(selected_vars)
global new_terms = r(new_terms)
noi di "$new_terms"

	


*******************
*   CoxPH Model   *
*******************
		
capture erase output/models/coefs_a_cox_all.ster

timer clear 1
timer on 1
stcox $new_terms , vce(robust)
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_a_cox_all, replace




***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
predict basesurv, basesurv
summ basesurv if _t <= 28 
global base_surv28 = r(min) // baseline survival decreases over time

summ basesurv if _t <= 100 
global base_surv100 = r(min) 

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv28 , $base_surv100 , b]
local names: colfullnames b
local names: subinstr local names "c1" "base_surv28"
local names: subinstr local names "c2" "base_surv100"
mat colnames b = `names'

*  Save coefficients to Stata dataset  
qui do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("")  ///
	dataname("data/model_a_coxPH_all")



log close

