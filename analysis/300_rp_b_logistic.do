********************************************************************************
*
*	Do-file:		300_rp_b_logistic.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_logistic_`tvc'.dta, where tvc=foi, ae, susp
*
*	Other output:	Log file:  	output/300_rp_b_logistic_`tvc'.log
*					Estimates:	output/models/coefs_b_logit_`tvc'.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits logistic regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases. 
*
********************************************************************************


* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/300_rp_b_logistic_`tvc'", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"




***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark.dta", clear





****************************************
*  Set up data for logistic modelling  *
****************************************


* The dataset has multiple rows:
* 	Cases in subchohort 
*		one extra row
* 		first row, not case, weight=1/sf
* 		last row, case, weight=1

* We want to have 
*	a binary outcome (case in 28 days vs not)
* 	sampling fractions:  1/sf for non-cases; 1 for cases

* So... 
* Take maximum of outcome across rows within the same landmark substudy
* Take minimum of weight across rows in same landmark substudy (= 1 for cases)

bysort patient_id time: egen weight	= min(sf_wts)
bysort patient_id time: egen case	= max(onscoviddeath)

drop sf_wts onscoviddeath 
rename case onscoviddeath
rename weight sf_wts

* Drop variables related to time within the landmark substudy
drop days_until_coviddeath days_until_otherdeath dayin dayout _* ///
	died_date_onsother newid

* Keep one row per patient per landmark substudy
duplicates drop
isid patient_id time 
bysort onscoviddeath: summ sf_wts



***************
*  Fit model  *
***************


* Model details
*	Model type: Logistic
*	Predictors: As selected by lasso etc.
*	SEs: Robust to account for patients being in multiple sub-studies
*	Sampling: Sampling weights

capture erase output/models/coefs_b_logit.ster

* Fit model
timer clear 1
timer on 1
noi logistic onscoviddeath ${selected_vars_landmark_`tvc'}		///
	[pweight=sf_wts], 											///
	robust cluster(patient_id) 
timer off 1
timer list 1
estat ic

estimates save output/models/coefs_b_logit, replace


* Pick up coefficient matrix
matrix b = e(b)


/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath:") ///
	dataname("data/model_b_logistic_`tvc'")






* Close log file
log close




