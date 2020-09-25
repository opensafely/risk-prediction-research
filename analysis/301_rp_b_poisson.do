********************************************************************************
*
*	Do-file:		301_rp_b_poisson.do
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



* Open a log file
capture log close
log using "./output/rp_b_poisson", text replace




*****************************
*  Pick up predictor lists  *
*****************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors"
noi di "$parsimonious"





		********************************************************
		*   MODELS NOT INCLUDING MEASURES OF INFECTION BURDEN  *
		********************************************************


************************************************************************
*   Poisson regression:  No shielding, no time-varying infection data  *
************************************************************************


use "data/cr_landmark.dta", clear
 

* Barlow weights used as an offset, alongside the usual offset (exposure time)
gen offset = log(dayout - dayin) + log(sf_wts)



* Model details
*	Model type: Poisson
*	Predictors: As selected by lasso etc.
*	SEs: Robust to account for patients being in multiple sub-studies
*	Sampling: Offset (log-sampling fraction) to incorporate sampling weights

* Fit model
timer clear 1
timer on 1
poisson onscoviddeath $predictors_noshield, robust cluster(patient_id) offset(offset)
poisson onscoviddeath $predictors_preshield,	///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

* Pick up coefficient matrix
matrix b = e(b)

/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath") ///
	dataname("data/model_b_poisson_noshield")








		****************************************************
		*   MODELS INCLUDING MEASURES OF INFECTION BURDEN  *
		****************************************************


* Dataset has 2 lines of data per person already 9(????)))
* Use post-shielding set of predictors (shielding indicator + any interactions) 





/*  Measure of burden of infection:  Force of infection  */

* Measure of force of infection on the previous day
timer clear 1
timer on 1
poisson onscoviddeath $predictors		///
	foi, 											///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic


* Measure of force of infection - quadratic model of last 3 weeks
timer clear 1
timer on 1
poisson onscoviddeath $predictors		///
	foi_q_cons foi_q_day foi_q_daysq,				///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

gen logfoi = log(foi)

* Measure of force of infection on the previous day
timer clear 1
timer on 1
poisson onscoviddeath $predictors		///
	logfoi, 											///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

gen logfoi_q_cons 	= log(foi_q_cons)
gen logfoi_q_day  	= log(foi_q_day)
gen logfoi_q_daysq 	= log(foi_q_daysq)


* Measure of force of infection - quadratic model of last 3 weeks
timer clear 1
timer on 1
poisson onscoviddeath $predictors_preshield		///
	logfoi_q_cons logfoi_q_day logfoi_q_daysq,		///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic



/*  Measure of burden of infection:  A&E attendances  */


timer clear 1
timer on 1
poisson onscoviddeath $predictors						///
	aemean, 											///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic


* Measure of force of infection - quadratic model of last 3 weeks
timer clear 1
timer on 1
poisson onscoviddeath $predictors				///
	ae_q_cons ae_q_day ae_q_daysq,				///
	robust cluster(patient_id) offset(offset)
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



* Measure of force of infection - quadratic model of last 3 weeks
timer clear 1
timer on 1
poisson onscoviddeath $predictors				///
	logae_q_cons logae_q_day logae_q_daysq,		///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic





* Close log file

log close