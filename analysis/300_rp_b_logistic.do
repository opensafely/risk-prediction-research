********************************************************************************
*
*	Do-file:		rp_b_logistic_regression_models.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	 
*
*	Other output:	Log file:  			rp_b_logistic.log
*					Model estimates:	rp_b_logistic.ster
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
cap erase ./output/models/rp_b_logistic.ster


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_preshield"


***************
*  Open data  *
***************


use "data/cr_landmark.dta", clear

* For cases - only keep row in which the case occurs
bysort time patient_id (onscoviddeath): keep if _n==_N
isid time patient_id

* Multiple rows
* Shielding - two rows pre and post
* Cases in subchoort - 
* row one first (not case), weight=1/sf
* row 2 (case), weight=1

* We want to use sampling frations:
*  1/sf - non-cases; 1 cases

* So...


**************************
*   Logistic regression  *
**************************

* Incorporate weights (=1 for cases, 1/SF otherwise) as offset term

* Fit model
timer clear 1
timer on 1
logistic onscoviddeath $predictors, robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic




*estimates
*estimates save ./output/models/rp_b_logistic_regression_models.ster, replace
*logit, or
 

* Obtain absolute predictions, correcting the intercept for the control sampling
*predict xb, xb
*replace xb = xb + log($sampling_frac) 
*gen risk28 = exp(xb)/(1 + exp(xb))





