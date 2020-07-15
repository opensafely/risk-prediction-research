********************************************************************************
*
*	Do-file:		rp_b_poisson.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_tr_landmark_models.dta
*
*	Data created:	?????
*
*	Other output:	Log file:  			rp_b_poisson.log
*					Model estimates: 	rp_b_poisson.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death. 
*
********************************************************************************



* Open a log file
capture log close
log using "./output/rp_b_poisson", text replace
cap erase ./output/models/rp_b_poisson.ster


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_noshield"


***************
*  Open data  *
***************


use "data/cr_tr_landmark_models.dta", clear




************************************************************************
*   Poisson regression:  No shielding, no time-varying infection data  *
************************************************************************


* Barlow weights used as an offset, alongside the usual offset (exposure time)
gen offset = log(dayout - dayin) + log(sf_wts)

* Fit model
timer clear 1
timer on 1
poisson onscoviddeath $predictors_noshield, robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

* Save estimates
estimates
*estimates save ./output/models/rp_b_poisson_regression_models.ster, replace
*poisson, irr

* Pick up coefficient matrix
matrix b = e(b)
do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath") dataname("data/model_b_poisson")




/*

* OR: 

stset dayout, fail(onscoviddeath) enter(dayin) 

streg onscoviddeath $predictors_noshield,	///
	dist(exponential) 				///
	robust cluster(patient_id) 		///
	offset(offset)
*/
 






*********************************
*   Pick up model coefficients  *
*********************************

use "data/model_b_poisson", clear

qui count
global no_terms = r(N)
forvalues j = 1 (1) $no_terms {
	global coef`j' = coef[`j']
	global varexpress`j' = varexpress[`j']
	
}





****************************
*   Validation dataset 1   *
****************************

use "data/validate1", clear
gen constant = 1

gen xb = 0
forvalues j = 1 (1) $no_terms {
	replace xb = xb + ${coef`j'}*${varexpress`j'}
}
replace xb = xb + log(28)
gen pred = 1 -  exp(-exp(xb))

* Brier Score (& C-statistic)
brier onscoviddeath pred

cc_calib onscoviddeath pred, data(internal) pctile


          

****************************
*   Validation dataset 2   *
****************************

use "data/validate2", clear
gen constant = 1

gen xb = 0
forvalues j = 1 (1) $no_terms {
	replace xb = xb + ${coef`j'}*${varexpress`j'}
}
replace xb = xb + log(28)
gen pred = 1 -  exp(-exp(xb))

* Brier Score (& C-statistic for binary outcomes)
brier onscoviddeath pred

cc_calib onscoviddeath pred, data(internal) pctile



 
************************************
*   Predict 28 day COVID-19 death  *
************************************







* Close log file
*log close


