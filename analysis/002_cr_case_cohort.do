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
*	Purpose:		This do-file creates case cohorts
*  
********************************************************************************* 
* Open a log file
cap log close
log using "output/002_cr_case_cohort", replace t


************************
*  Create case cohorts *
************************
local samplingFrac 0.03 // represents 3%

set seed 37873

* Create training case cohorts
forvalues i = 1/2 {

	use "data/cr_training_dataset.dta", replace

	* Calculate subcohort size
	count 
	local subcohort = ceil(r(N)*`samplingFrac')

	* Generate random orders
	qui gen randomOrder = uniform()
	sort randomOrder

	* Identify random subcohort
	gen subcohort = 1 if _n <= `subcohort'

	* Keep random subcohort and all cases
	keep if subcohort == 1 | onscoviddeath == 1 
	replace subcohort = 0  if subcohort == . 

	tab subcohort onscoviddeath 

	********************
	* Barlow Weighting *
	********************

	* Expand dataset for cases in subcohort 2 lines for cases in subcohort
	expand 2 if subcohort == 1 & onscoviddeath ==1 

	* Apply weighting scheme
	
	bysort patient_id: gen row = _n
	* Noncase in subcohort
	gen sf_wts = 1/`samplingFrac' if onscoviddeath == 0 & subcohort == 1 
	* case in subcohort before event
	replace sf_wts = 1/`samplingFrac' if onscoviddeath == 1 & subcohort == 1 & row == 1
	* case in subcohort at event
	replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 1 & row == 2
	* case outside subcohort at event 
	replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 0 

	drop row

	if `i' == 1 {
	save "data/cr_casecohort_var_select.dta", replace
			}
	else { 
	save "data/cr_casecohort_models.dta", replace
		 }

}
			


log close
