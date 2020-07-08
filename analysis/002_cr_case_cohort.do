********************************************************************************
*
*	Do-file:		002_cr_case_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		output/cr_training.dta (training dataset)
*
*	Data created:	
*					output/cr_tr_casecohort_var_select.dta (training variable selection)
*					output/cr_tr_casecohort_models.dta (training modelling fitting) 
*
*
*	Other output:	Log file:  cr_case_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file creates two case cohort datasets to perform
*					model fitting in for the risk prediction models.
*
*					The first is for variable selection.
*
*					The second is for model fitting.
*  
********************************************************************************* 

* Open a log file
cap log close
log using "output/002_cr_case_cohort", replace t


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


* Create training case-cohorts
forvalues i = 1/2 {

	* Open underlying base cohort (4/5 of original TPP cohort)
	use "data/cr_training_dataset.dta", replace

	* Identify random subcohort
	gen subcohort = 0
	forvalues j = 1 (1) 6 {
		replace subcohort = 1 if uniform() < `sf`j''
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

	* Apply weighting scheme
	bysort patient_id: gen row = _n
	
	gen sf_wts = .	
	forvalues j = 1 (1) 6 {
		* Noncase in subcohort
		replace sf_wts = 1/`sf`j'' if onscoviddeath == 0 & subcohort == 1 
		* case in subcohort before event
		replace sf_wts = 1/`sf`j'' if onscoviddeath == 1 & subcohort == 1 & row == 1
		* case in subcohort at event
		replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 1 & row == 2
		* case outside subcohort at event 
		replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 0 
	}
	label var sf_wts "Sampling fraction weights (Barlow)"
	
	* Declare as survival data
	stset stime, fail(onscoviddeath) id(patient_id)  
	
	* Modify survival times and outcomes for cases in subcohort
	replace _d = 0    if onscoviddeath == 1 & subcohort == 1 & row == 1
	replace _t = _t-1 if onscoviddeath == 1 & subcohort == 1 & row == 1
	
	replace _t0 = _t-1 if onscoviddeath == 1 & subcohort == 1 & row == 2
	drop row

	
	*******************
	*  Save datasets  *
	*******************
	
	
	if `i' == 1 {
	save "data/cr_casecohort_var_select.dta", replace
			}
	else { 
	save "data/cr_casecohort_models.dta", replace
		 }

}
			

* Close log file
log close

