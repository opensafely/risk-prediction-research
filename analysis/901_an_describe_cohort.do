********************************************************************************
*
*	Do-file:		901_an_describe_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta
*
*	Data created:	
*					output/cr_cohort_vp1.dta (validation period 1)
*					output/cr_cohort_vp2.dta (validation period 2) 
*					output/cr_cohort_vp3.dta (validation period 3) 
*
*	Other output:	Log file:  901_an_describe_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file describes the data in the base cohort.
*
*	NOTES: 			1) Stata do-file called internally:
*							analysis/0000_cr_define_covariates.do
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/901_an_describe_cohort", replace t


* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"



****************************************
*  Open cohort and extract covariates  *
****************************************
	
	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace

	
/* Complete case for ethnicity   */ 

tab ethnicity_8
tab ethnicity_8, m
drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.
	


/*  Extract relevant covariates  */
	
* Define covariates as of the start date of the validation period
local start = d(01/03/2020)
define_covs, dateno(`start')

	



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
	
summ died_date_onscovid died_date_onsother, d
tab onscoviddeath, m
summ stime
summ days_until_coviddeath days_until_otherdeath



* Close log file
log close

