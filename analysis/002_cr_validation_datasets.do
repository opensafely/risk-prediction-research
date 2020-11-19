********************************************************************************
*
*	Do-file:		002_cr_validation_datasets.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						cr_base_cohort.dta
*						foi_coefs.dta
*						ae_coefs.dta
*						susp_coefs.dta
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
*	NOTES: 			1) Stata do-file called internally:
*							analysis/0000_cr_define_covariates.do
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/002_cr_validation_datasets", replace t


* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"



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

	
	/* Complete case for ethnicity   */ 
	
	drop ethnicity_5 ethnicity_16
	drop if ethnicity_8>=.
	
	
	/* Apply eligibility criteria for validation period i  */ 

	*  To be at risk of 28-day Covid-19 death you must be alive at start date 	
	drop if died_date_onscovid < `vp_start'
	drop if died_date_onsother < `vp_start'
		
	
	/*  Extract relevant covariates  */
	
	* Define covariates as of the start date of the validation period
	define_covs, dateno(`vp_start')

	
	/*  Obtain observed 28-day mortality  */
	
	gen onscoviddeath28 = (days_until_coviddeath <=28)
	label var onscoviddeath28 "Observed 28-day COVID-19 death, validation period `i'"
	
	
	
	
	
	************************************************
	*  Add in time-varying measures of infection   *
	************************************************

	gen time = `vp_start' - d(1/03/2020) + 1

	* Age grouping used in FOI data
	recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 		///
		gen(agegroupfoi)
		
	* Merge in the force of infection data
	merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
		assert(match using) keep(match) nogen 
	drop agegroupfoi
	drop foi_c_cons foi_c_day foi_c_daysq foi_c_daycu

	* Merge in the A&E STP count data
	merge m:1 time stp_combined using "data/ae_coefs", ///
		assert(match using) keep(match) nogen
	drop ae_c_cons ae_c_day ae_c_daysq ae_c_daycu


	* Merge in the GP suspected COVID case data
	merge m:1 time stp_combined using "data/susp_coefs", ///
		assert(match using) keep(match) nogen
	drop susp_c_cons susp_c_day susp_c_daysq susp_c_daycu
	drop time


	

	*******************
	*  Save datasets  *
	*******************

	sort patient_id
	label data "Cohort (complete case ethnicity) for validation period `i'"
	save "data/cr_cohort_vp`i'.dta", replace
	 

}


* Close log file
log close

