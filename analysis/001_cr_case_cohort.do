********************************************************************************
*
*	Do-file:		001_cr_case_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		cr_base_cohort.dta (base cohort)
*
*	Data created:	data/cr_casecohort_models.dta (training modelling fitting) 
*
*
*	Other output:	Log file:  001_cr_case_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a case cohort dataset to perform
*					model fitting in for the risk prediction models.
*	
*	NOTES: 			1) This dataset removes people with missing ethnicity 
*					   information.
*
*					2) Stata programmes called internally:
*							"analysis/0000_cr_define_covariates.do"
*
********************************************************************************




* Open a log file
cap log close
log using "output/001_cr_case_cohort", replace t



*************************
*  Create case cohorts  *
*************************

* Age-group-stratified sampling fractions
local sf1 = 0.01
local sf2 = 0.02
local sf3 = 0.02
local sf4 = 0.025
local sf5 = 0.05
local sf6 = 0.13


* Set random seed for replicability
set seed 37873



* Open underlying base cohort 
use "data/cr_base_cohort.dta", replace

* Keep ethnicity complete cases
drop ethnicity_5 ethnicity_16 
drop if ethnicity_8>=.

* Delete unneeded variables
drop bp_sys_date_measured bp_dias_date_measured




**********************
*  Select subcohort  *
**********************

* Identify random subcohort
gen subcohort = 0
forvalues j = 1 (1) 6 {
	replace subcohort = 1 if uniform() < `sf`j'' & agegroup==`j'
}
label var subcohort "Subcohort"

* Keep random subcohort and all cases
tab subcohort onscoviddeath 
keep if subcohort == 1 | onscoviddeath == 1 
tab subcohort onscoviddeath 



**********************
*  Barlow Weighting  *
**********************

* Expand dataset for cases in subcohort 2 lines for cases in subcohort
expand 2 if subcohort == 1 & onscoviddeath == 1 
bysort patient_id: gen row = _n

* Apply weighting scheme
gen sf_wts = .	
* 	Case in subcohort at event
replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 1 & row == 2
* 	Case outside subcohort at event 
replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 0 

* Subcohort
forvalues j = 1 (1) 6 {
	* Noncase in subcohort
	replace sf_wts = 1/`sf`j'' if agegroup==`j' ///
			& onscoviddeath == 0 & subcohort == 1 
	* Case in subcohort before event
	replace sf_wts = 1/`sf`j'' if agegroup==`j' /// 
			& onscoviddeath == 1 & subcohort == 1 & row == 1
}
label var sf_wts "Sampling fraction weights (Barlow)"
	
* Start and stop dates for follow-up
gen 	dayin  = 0
gen  	dayout = stime
replace dayout = 1.5 if dayout==1

*	Non-subcohort cases - at risk from the day before event
replace dayin  = dayout-1 if onscoviddeath == 1 & subcohort == 0 

* 	Subcohort cases - first line prior to event, second for event
replace dayout = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 1
replace dayin  = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 2

* 	Subcohort cases - don't have event in first row (prior to event)
replace onscoviddeath = 0 if onscoviddeath == 1 & subcohort == 1 & row == 1
drop row

label var dayin  "Day (this row of data) enters risk set (case-cohort)"
label var dayout "Day (this row of data) exits risk set (case-cohort)"




*********************************
*  Extract relevant covariates  *
*********************************

* Define covariates as of 1st March 2020
define_covs, date(1/03/2020)



*******************
*  Save dataset  *
*******************

* Declare as survival data (with Barlow weights)
sort patient_id dayin
gen newid = _n
label var newid "Row ID"
stset dayout [pweight=sf_wts], fail(onscoviddeath) enter(dayin) id(newid)  

label data "Case-cohort (complete case ethnicity) for model fitting"
note: Stset treats rows as if from different people; SEs will be incorrect
save "data/cr_casecohort_models.dta", replace


		
* Close log file
log close


