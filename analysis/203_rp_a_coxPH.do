********************************************************************************
*
*	Do-file:		203_rp_a_coxPH.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  203_rp_a_coxPH.log
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

use "data/cr_casecohort_models.dta", replace

*******************************
*  Pick up predictor list(s)  *
*******************************


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_preshield"
noi di "$predictors"


*******************
*   CoxPH Model   *
*******************

timer clear 1
timer on 1
stcox $predictors_preshield , vce(robust)
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
summ basesurv if _t <= 28 // update to 28 days
global base_surv = r(min) // baseline survival decreases over time

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "base_surv"
mat colnames b = `names'

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("") cons_no ///
	dataname("data/model_a_coxPH_noshield")



log close

