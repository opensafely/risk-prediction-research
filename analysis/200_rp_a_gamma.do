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
noi di "$selected_vars"

***********************
*   Generalised gamma *
***********************

timer clear 1
timer on 1
streg $selected_vars , dist(ggamma) vce(robust) difficult
estat ic
timer off 1
timer list 1

***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

* Pick up sigma/kappa
global sigma = e(sigma)
global kappa = e(kappa)

di $sigma
di $kappa

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$sigma, $kappa, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:sigma"
local names: subinstr local names "c2" "_t:kappa"
mat colnames b = `names'

* Remove unneeded parameters from matrix
local np = colsof(b) - 2 // remove lnsigma kappa
matrix b = b[1,1..`np']
matrix list b

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
	dataname("data/model_a_ggamma_noshield")


log close






