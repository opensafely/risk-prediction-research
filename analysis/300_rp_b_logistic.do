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


/*  Create time-varying variables needed  */

* Variables needed for force of infection data

gen logfoi = log(foi)
gen foiqd  =  foi_q_day/foi_q_cons
gen foiqds =  foi_q_daysq/foi_q_cons


* Variables needed for A&E attendance data
gen aepos = aerate
qui summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons

replace aeqd  = 0 if ae_q_cons==0
replace aeqds = 0 if ae_q_cons==0

gen aeqint 		= aeqd*aeqds
gen aeqd2		= aeqd^2
gen aeqds2		= aeqds^2


* Variables needed for GP suspected case data

gen susppos = susp_rate
qui summ susp_rate if susp_rate>0 
replace susppos = susppos + r(min)/2 if susppos==0

* Create time variables to be fed into the variable selection process
gen logsusp	 	= log(susppos)
gen suspqd	 	= susp_q_day/susp_q_cons
gen suspqds 	= susp_q_daysq/susp_q_cons

replace suspqd  = 0 if susp_q_cons==0
replace suspqds = 0 if susp_q_cons==0

gen suspqint   	= suspqd*suspqds
gen suspqd2 	= suspqd^2
gen suspqds2	= suspqds^2





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
*	Sampling: Offset (log-sampling fraction) to incorporate sampling weights

* Fit model
timer clear 1
timer on 1
noi logistic onscoviddeath ${selected_vars_landmark_`tvc'}		///
	[pweight=sf_wts], 											///
	robust cluster(patient_id) offset(offset)
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




