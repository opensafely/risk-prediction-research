********************************************************************************
*
*	Do-file:		002_cr_validation_datasets.do
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
*	Other output:	Log file:  002_cr_validation_datasets.log
*
********************************************************************************
*
*	Purpose:		This do-file creates three cohort datasets to perform
*					model validation on, one for each validation period.
*
********************************************************************************* 



* Open a log file
cap log close
log using "output/002_cr_validation_datasets", replace t



**************************************
*  Create three validation datasets  *
**************************************

* Loop over the three validation periods
forvalues i = 1/3 {

	if `i' == 1 {
		local vp_start 	= d(01/03/2020)
		local vp_end 	= d(28/03/2020) 
		label var onscoviddeath "COVID-19 death (1 March - 28th March)"
		label var stime "Survival time (days from 1 March; end 28th March) for COVID-19 death"
	}
	if `i' == 2 {
		local vp_start 	= d(06/04/2020)
		local vp_end	= d(03/05/2020) 
		label var onscoviddeath "COVID-19 death (6 April - 3rd May)"
		label var stime "Survival time (days from 6 April; end 3rd May) for COVID-19 death"
	}
	if `i' == 3 {
		local vp_start 	= d(12/05/2020)
		local vp_end 	= d(08/06/2020) 
		label var onscoviddeath "COVID-19 death (12 May - 8th June)"
		label var stime "Survival time (days from 12 May; end 8th June) for COVID-19 death"
	}

	

	*******************************
	*  Create validation dataset  *
	*******************************

	
	/* Open base cohort   */ 
	
	use "data/cr_base_cohort.dta", replace

	
	/* Apply eligibility criteria for validation period i  */ 

	*  To be at risk of 28-day Covid-19 death you must be alive at start date 	
	drop if died_date_onscovid < `vp_start'
	drop if died_date_onsother < `vp_start'
		
	
	/*  Extract relevant covariates  */
	
	* Define covariates as of the start date of the validation period
	define_covs, dateno(`vp_start')

	
	/*  Obtain observed 28-day mortality  */
	
	gen onscoviddeath28 = days_until_coviddeath <=28
	label var onscoviddeath28 "Observed 28-day COVID-19 death, validation period `i'"
	

	*******************
	*  Save datasets  *
	*******************

	sort patient_id
	label data "Cohort (complete case ethnicity) for validation period `i'"
	save "data/cr_cohort_vp`i'.dta", replace
	 

}


* Close log file
log close

