********************************************************************************
*
*	Do-file:		1300_rp_b_logistic_combined.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_logistic_`tvc'.dta, where tvc=all, objective
*
*	Other output:	Log file:  	output/1300_rp_b_logistic_`tvc'.log
*
********************************************************************************
*
*	Purpose:		This do-file fits logistic regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different combinations of time-varying measures of disease:
*					all three (force of infection estimates, A&E attendances 
*					for COVID, and suspected GP COVID cases) or the two 
*					objective measures (A&E & GP). 
*
********************************************************************************



* Specify the time-varying measures: all (foi, ae and susp) or objective (ae & susp)
local tvc `1' 
noi di "`tvc'"
assert inlist("`tvc'", "all", "objective")


* Open a log file
capture log close
log using "./output/1300_rp_b_logistic_`tvc'", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 

global foi_covs 	= "${selected_vars_landmark_foi}"
global ae_covs 		= "${selected_vars_landmark_ae}"
global susp_covs 	= "${selected_vars_landmark_susp}"

global all_covs: list global(foi_covs) | global(ae_covs) 
global all_covs: list global(all_covs) | global(susp_covs)

global objective_covs: list global(ae_covs) | global(susp_covs)


noi di `tvc'
noi di "${`tvc'_covs}"




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


* Fit model
timer clear 1
timer on 1
noi logistic onscoviddeath ${`tvc'_covs}		///
	[pweight=sf_wts], 							///
	robust cluster(patient_id) 
timer off 1
timer list 1
estat ic



* Pick up coefficient matrix
matrix b = e(b)


/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath:") ///
	dataname("data/model_b_logistic_`tvc'")




* Close log file
log close




