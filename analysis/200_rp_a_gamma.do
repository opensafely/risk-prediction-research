********************************************************************************
*
*	Do-file:		200_rp_a_gamma.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  203_rp_a_gamma.log
*
********************************************************************************
*
*	Purpose:		This do-file performs generalized gamma survival models (AFT) 
*  
********************************************************************************


* Open a log file
capture log close
log using "./output/200_rp_a_gamma", text replace

use "data/cr_casecohort_models.dta", replace

*******************************
*  Pick up predictor list(s)  *
*******************************


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_preshield"
noi di "$predictors"


*********************
*   Weibull Model  *
*********************

*********************
*   Pre-shielding   *
*********************
timer clear 1
timer on 1
streg $predictors_preshield , dist(ggamma) vce(robust)
estat ic
timer off 1
timer list 1

/*  Put coefficients and survival in a matrix  */ 

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival -> UPDATE
local p = exp(_b[/:lnsigma])
global base_surv = exp(-1*(28^(`p'))*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv"
mat colnames b = `names'

* Remove unneeded parameters from matrix
local np = colsof(b) - 2 // remove lnsigma kappa
matrix b = b[1,1..`np']
matrix list b

/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("_t") cons_no ///
	dataname("data/model_a_ggamma_noshield")


	

* matrix b check if colnames have prefix as in _t above

********************************
*   Overall Model Performance  *
********************************



****************
*   Shiedling  *
****************
* Split data to pre/post shielding
use "data/cr_casecohort_models.dta", replace
stsplit shield, at(32) 
recode shield 32=1
label define shield_lab 0 "Pre-shielding" 1 "Shielding"
label values shield shield_lab
label var shield "Binary shielding indicator (pre-post 1 April)"
recode onscoviddeath .=0

timer clear 1
timer on 1
streg $predictors , dist(ggamma) vce(robust)
estat ic
timer off 1
timer list 1

/*  Put coefficients and survival in a matrix  */ 

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival - UPDATE THIS
local p = exp(_b[/:ln_p])
global base_surv = exp(-1*(28^(`p'))*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv"
mat colnames b = `names'

* Remove unneeded parameters from matrix
local np = colsof(b) - 2 // remove lnsigma kappa
matrix b = b[1,1..`np']
matrix list b

/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("_t") cons_no ///
	dataname("data/model_a_ggamma_shield")


*******************************
*   Generalized gamma models  *
*******************************

timer clear 1
timer on 1
streg $predictors_preshield, dist(ggamma) vce(robust)
timer off 1
timer list 1
estat ic 

* coefficients matrix 
matrix b = e(b)
**********************************************

log close






