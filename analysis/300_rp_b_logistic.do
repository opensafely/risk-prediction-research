********************************************************************************
*
*	Do-file:		300_rp_b_logistic_regression_models.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_logistic_noshield.dta
*					data/model_b_logistic_shield_foi.dta
*					data/model_b_logistic_shield_???.dta
*
*	Other output:	Log file:  	rp_b_logistic.log
*
********************************************************************************
*
*	Purpose:		This do-file fits logistic regression models to the landmark
*					substudies to predict 28-day COVID-19 death. 
*
********************************************************************************




* Open a log file
capture log close
log using "./output/rp_b_logistic", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_preshield"




****************************************
*  Set up data for logistic modelling  *
****************************************


use "data/cr_landmark.dta", clear

* The dataset has multiple rows:
* 	Shielding 
*		two rows for pre and post
*		 - same weight in each
*		 - outcome in last row
* 	Cases in subchohort 
*		one extra row
* 		all but last row, not case, weight=1/sf
* 		last row, case, weight=1

* We want to have 
*	a binary outcome (case in 28 days vs not)
* 	sampling frations:  1/sf for non-cases; 1 for cases

* So... 
* Take maximum of outcome across rows within the same landmark substudy
* Take minimum of weight across rows in same landmark substudy (= 1 for cases)

bysort patient_id time: egen weight	= min(sf_wts)
bysort patient_id time: egen case	= max(onscoviddeath)

drop sf_wts onscoviddeath 
rename case onscoviddeath
rename weight sf_wts

* Drop variables related to time within the landmark substudy
drop days_until_coviddeath days_until_otherdeath shield dayin dayout

* Keep one row per patient per landmark substudy
duplicates drop
isid patient_id time 
bysort onscoviddeath: summ sf_wts

* Create offset term (log of the sampling fraction)
gen offset = log(sf_wts)


* Create term to indicate "sielded" time periods
recode time 1/17=0 18/73=1, gen(shield)
label var shield "Shielded time periods (shielding assumed to have effect)" 

 
 

********************************************************
*   Models not including measures of infection burden  *
********************************************************

* Model details
*	Model type: Logistic
*	Predictors: As selected by lasso etc.
*	SEs: Robust to account for patients being in multiple sub-studies
*	Sampling: Offset (log-sampling fraction) to incorporate sampling weights

* Fit model
timer clear 1
timer on 1
logistic onscoviddeath $predictors_preshield, 	///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic


* Pick up coefficient matrix
matrix b = e(b)


/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath") ///
	dataname("data/model_b_logistic_noshield")




****************************************************
*   Models including measures of infection burden  *
****************************************************

* WITH SHIELDING
* Substudies 1-17 considered “pre-shielding” and 18-73 “shielding” 
*  (as identified by "shield" variable created above)
* Use post-shielding set of predictors (shielding indicator + any interactions) 




/*  Measure of burden of infection:  Force of infection  */




/*  Measure of burden of infection:  (?????)  */






* Close log file
log close




