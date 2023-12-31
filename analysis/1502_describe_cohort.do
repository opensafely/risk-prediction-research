********************************************************************************
*
*	Do-file:		1502_an_describe_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta
*
*	Data created:	None
*
*	Other output:	Log file:  output/1502_an_describe_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file describes the data in the base cohort and 
*					puts the output in a log file.
*
*	NOTES: 			1) Stata do-file called internally:
*							analysis/0000_cr_define_covariates.do
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/1502_an_describe_cohort", replace text


* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"



****************************************
*  Open cohort and extract covariates  *
****************************************
	
	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace

	
/* Complete case for ethnicity   */ 

tab onscoviddeath
tab ethnicity_8
tab ethnicity_8, m
drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.
tab onscoviddeath


/*  Extract relevant covariates  */
	
* Define covariates as of the start date of the validation period
local start = d(01/03/2020)
qui define_covs, dateno(`start')

	



**********************************
*  Describe predictor variables  *
**********************************


* Area
tab region_7, 		m
tab stp_combined, 	m
tab rural, 			m
tab imd, 			m

* Household 
summ hh_num, 		d
tab hh_num, 		m
tab hh_children, 	m

* Age, sex and ethnicity
summ age, 			d 
tab agegroup, 		m
tab male, 			m
tab ethnicity_8, 	m

* BMI, smoking and blood pressure
summ bmi, 			d
tab bmicat, 		m
tab obesecat, 		m
tab smoke, 			m
tab smoke_nomiss, 	m
tab bpcat, 			m
tab bpcat_nomiss, 	m

* Comorbidities
tab1 	respiratory asthmacat cf 					///
		cardiac diabcat hypertension af dvt_pe pad 	///
		stroke dementia neuro						///
		cancerExhaem cancerHaem						///
		kidneyfn dialysis liver transplant 			///
		spleen autoimmune hiv suppression ibd 		///
		smi ld fracture, m


	

********************************
*  Describe outcome variables  *
********************************
	
summ died_date_onscovid died_date_onsother, d format
tab onscoviddeath, m
summ stime
summ days_until_coviddeath days_until_otherdeath



************************
*  Landmark substudy   *
************************

use "data/cr_casecohort_models.dta", clear
tab onscoviddeath subcohort
tab sf_wts



************************
*  Landmark substudy   *
************************

use "data/cr_landmark.dta", clear
tab onscoviddeath subcohort
tab sf_wts


********************************
*  Describe outcome variables  *
********************************

* Close log file
log close

