********************************************************************************
*
*	Do-file:		203_rp_a_coxPH.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_coxPH_noshield.dta
*
*	Other output:	Log file:  output/203_rp_a_coxPH.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model 
*  
********************************************************************************


* Open a log file
capture log close
log using "./output/203_rp_a_coxPH", text replace




************************************
*  Open dataset for model fitting  *
************************************

use "data/cr_casecohort_models.dta", replace



****************************
*  Pick up predictor list  *
****************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$selected_vars"



*******************
*   CoxPH Model   *
*******************

timer clear 1
timer on 1
stcox $selected_vars , vce(robust)
estat ic
timer off 1
timer list 1



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
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("")  ///
	dataname("data/model_a_coxPH_noshield")



log close

