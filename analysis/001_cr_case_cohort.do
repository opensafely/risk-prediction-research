********************************************************************************
*
*	Do-file:		001_cr_case_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta (base cohort)
*
*	Data created:	output/cr_casecohort_var_select.dta 
*								(case-cohort: variable selection)
*					output/cr_casecohort_models.dta 
*								(case-cohort: modelling fitting) 
*
*	Other output:	Log file:  001_cr_case_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file creates two case-cohort datasets to perform
*					model fitting in for the risk prediction models.
*
*						- The first is for variable selection.
*						- The second is for model fitting.
*
*	NOTES: 			1) Both cohorts remove people with missing ethnicity
*					   information.
*
*					2) Stata do-file called internally:
*							analysis/0000_cr_define_covariates.do
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/001_cr_case_cohort", replace t


* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"



************************
*  Sampling fractions  *
************************

* Age-group-stratified sampling fractions
local sf1 = 0.01
local sf2 = 0.02
local sf3 = 0.02
local sf4 = 0.025
local sf5 = 0.05
local sf6 = 0.13



*******************************
*  Select case-cohort sample  *
*******************************


* Set random seed for replicability
set seed 37873


* Open underlying base cohort 
use "data/cr_base_cohort.dta", replace

* Keep ethnicity complete cases
drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.
	
	
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



*******************************
*  Sampling fraction weights  *
*******************************

gen sf_inv = .	


* Case: weight = 1
replace sf_inv = 1 if onscoviddeath == 1 

* Non-cases: weight = 1/SF (age-group specific)
forvalues j = 1 (1) 6 {
	replace sf_inv = 1/`sf`j'' if agegroup==`j' & onscoviddeath == 0 
}
label var sf_inv "Inverse of sampling fraction"




*********************************
*  Extract relevant covariates  *
*********************************

* Define covariates as of 1st March 2020
define_covs, date(1/03/2020)




****************************************************
*  Save case-cohort sample 1:  variable selection  *
****************************************************

* Start and stop dates for follow-up
gen 	dayin  = 0
gen  	dayout = stime

label var dayin  "Day enters risk set (case-cohort)"
label var dayout "Day exits risk set (case-cohort)"


* Declare as survival data
stset dayout, fail(onscoviddeath) enter(dayin) id(patient_id)  


* Create outcome for Poisson model and exposure variable
gen diedcovforpoisson  = _d
gen exposureforpoisson = _t-_t0
gen offset = log(exposureforpoisson) + log(sf_inv)

label var diedcovforpoisson  "ONS COVID-19 death for case-cohort variable selection"
label var exposureforpoisson "Days at risk for case-cohort variable selection"
label var offset			 "Offset (log scale; days at risk AND sampling fraction) for case-cohort variable selection"

* Order variables
sort patient_id dayin
order patient_id onscoviddeath subcohort dayin dayout stime ///
		diedcovforpoisson exposureforpoisson offset
drop _*


* Save dataset
label data "Case-cohort sample (complete case ethnicity) for variable selection"
save "data/cr_casecohort_var_select.dta", replace


	
	
**********************
*  Barlow Weighting  *
**********************


/*  Split at-risk time into two for subcohort cases (event and prior to)  */

* Expand dataset for cases in subcohort 2 lines for cases in subcohort
expand 2 if subcohort == 1 & onscoviddeath == 1 
bysort patient_id: gen row = _n



/*  Prior to event, subcohort cases have weight 1/SF (not 1 as above) */

* Change sampling fraction weights for subcohort cases (prior to being a case)
gen sf_wts = sf_inv
drop sf_inv

forvalues j = 1 (1) 6 {
	replace sf_wts = 1/`sf`j'' if agegroup==`j' /// 
			& onscoviddeath == 1 & subcohort == 1 & row == 1
}
label var sf_wts "Sampling fraction weights (Barlow)"



/*  Divide at risk time between periods for subcohort cases   */

* People who fail in first day - add half a day to failure time to avoid 
*   accidentally omitting from analysis due to zero at-risk time
replace dayout = 1.5 if dayout==1

*   Non-subcohort cases enter risk set day before event
replace dayin  = dayout-1 if onscoviddeath == 1 & subcohort == 0 

*	Subcohort cases in risk set from beginning to day of event with weight
*   1/sf, and then from day before event to event with weight 1
replace dayout = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 1
replace dayin  = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 2

label var dayin  "Day (this row of data) enters risk set (case-cohort)"
label var dayout "Day (this row of data) exits risk set (case-cohort)"



/*  Event time occurs in later period for subcohort cases   */

* 	Subcohort cases - event does not happen in first line of data
replace onscoviddeath = 0 if onscoviddeath == 1 & subcohort == 1 & row == 1
drop row





***********************************************
*  Save case-cohort sample 2:  Model Fitting  *
***********************************************


* Tidy data
sort patient_id dayin
order sf_wts, after(offset)
drop offset

* Create row ID (subcohort cases have 2 rows; patient_id is not a unique row ID)
gen newid = _n
label var newid "Row ID"

* Declare as survival data (with Barlow weights)
stset dayout [pweight=sf_wts], fail(onscoviddeath) enter(dayin) id(newid)  


* Save data
label data "Case-cohort sample (complete case ethnicity) for model fitting"
note: Stset treats rows as if from different people; SEs will be incorrect
save "data/cr_casecohort_models.dta", replace




* Close log file
log close

