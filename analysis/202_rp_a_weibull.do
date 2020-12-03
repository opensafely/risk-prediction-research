********************************************************************************
*
*	Do-file:		202_rp_a_weibull.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_weibull.dta
*
*	Other output:	Log file:  	output/202_rp_a_weibull.log
*					Estimates:	output/models/coefs_a_weib.ster
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the weibull
*					model
*  
********************************************************************************


* Open a log file
capture log close
log using "./output/202_rp_a_weibull", text replace



************************************
*  Open dataset for model fitting  *
************************************

use "data/cr_casecohort_models.dta", replace



*******************************
*  Pick up predictor list(s)  *
*******************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$selected_vars"



*********************
*   Weibull Model  *
*********************

capture erase output/models/coefs_a_weib.ster

timer clear 1
timer on 1
streg $selected_vars , dist(weibull) vce(robust)
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_a_weib, replace



***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
local p = exp(_b[/:ln_p])
global base_surv28 = exp(-1*(28^(`p'))*exp(_b[_cons]))
global base_surv100 = exp(-1*(100^(`p'))*exp(_b[_cons]))


* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv28, $base_surv100, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv28"
local names: subinstr local names "c2" "_t:base_surv100"
mat colnames b = `names'

* Remove unneeded parameters from matrix
local np = colsof(b) - 1
matrix b = b[1,1..`np']
matrix list b

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction

get_coefs, coef_matrix(b) eqname("_t:") ///
	dataname("data/model_a_weibull")


log close

