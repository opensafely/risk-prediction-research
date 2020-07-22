********************************************************************************
*
*	Do-file:		rp_b_poisson.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_noshield.dta
*					data/model_b_poisson_shield_foi.dta
*					data/model_b_poisson_shield_???.dta
*
*	Other output:	Log file:  			rp_b_poisson.log
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death. 
*
********************************************************************************



**** ALTERNATIVE VERSION OF POISSON USING STREG



* Open a log file
capture log close
log using "./output/rp_b_poisson", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_preshield"




********************************************************
*   Models not including measures of infection burden  *
********************************************************


use "data/cr_landmark.dta", clear
sort patient_id time
gen newid = _n

stset dayout, fail(onscoviddeath) enter(dayin) id(newid)

* Barlow weights used as an offset, alongside the usual offset (exposure time)
gen offset = log(sf_wts)



* Model details
*	Model type: Poisson
*	Predictors: As selected by lasso etc.
*	SEs: Robust to account for patients being in multiple sub-studies       
*	Sampling: Offset (log-sampling fraction) to incorporate sampling weights

* Fit model
timer clear 1
timer on 1
streg $predictors_preshield,	/// 
	dist(exp) robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic




/*  Put coefficients and survival in a matrix  */ 

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
global base_surv = exp(-28*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv"
mat colnames b = `names'



/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("_t") cons_no ///
	dataname("data/model_b_poisson2_noshield")


	



****************************************************
*   Models including measures of infection burden  *
****************************************************

* WITH SHIELDING
* Use 1 April cut-off for shielding 
* Dataset has 2 lines of data per person already
* Use post-shielding set of predictors (shielding indicator + any interactions) 




/*  Measure of burden of infection:  Force of infection  */




/*  Measure of burden of infection:  (?????)  */





* Close log file
log close
