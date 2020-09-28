********************************************************************************
*
*	Do-file:		203_rp_a_weibull.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  203_rp_a_weibull.log
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

use "data/cr_casecohort_models.dta", replace

*******************************
*  TO BE UPDATED/REMOVED *
*******************************
* Centre age and then create splines of centred age
qui summ age
gen agec = (age - r(mean))/r(sd)


*******************************
*  Pick up predictor list(s)  *
*******************************


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_noshield"

*********************
*   Weibull Model  *
*********************

timer clear 1
timer on 1
streg $predictors_noshield , dist(weibull) vce(robust)
estat ic
timer off 1
timer list 1

***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
local p = exp(_b[/:ln_p])
global base_surv = exp(-1*(28^(`p'))*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv"
mat colnames b = `names'

* Remove unneeded parameters from matrix
local np = colsof(b) - 1
matrix b = b[1,1..`np']
matrix list b

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction

get_coefs, coef_matrix(b) eqname("_t") cons_no ///
	dataname("data/model_a_weibull_noshield")


log close

