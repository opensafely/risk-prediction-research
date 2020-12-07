********************************************************************************
*
*	Do-file:		007_cr_daily_landmark_covid_substudies.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta 
*
*	Data created:	data/cr_daily_landmark_covid.dta 
*
*	Other output:	Log file:  007_cr_daily_landmark_covid_substudies.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a dataset containing stacked landmark
*					substudies, each of a single day, to perform model fitting in,
*					for daily prediction models for COVID-19-related death.
*
*	NOTES: 			1) These landmark substudies remove people with missing 
*					ethnicity information.
*
*					2) Stata programmes called internally:
*							"analysis/0000_cr_define_covariates.do"
*
********************************************************************************




* Open a log file
cap log close
log using "output/007_cr_daily_landmark_covid_substudies", replace t



* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"


***********************
*  Create substudies  *
***********************

* Age-group-stratified sampling fractions 
local sf1 = 0.01/100
local sf2 = 0.02/100
local sf3 = 0.02/100
local sf4 = 0.025/100
local sf5 = 0.05/100
local sf6 = 0.13/100



* Set random seed for replicability
set seed 37873


* Create separate landmark substudies
forvalues i = 1 (1) 100 {


	* Open underlying base cohort
	use "data/cr_base_cohort.dta", replace

	* Keep ethnicity complete cases
	drop ethnicity_5 ethnicity_16
	drop if ethnicity_8>=.
	
	* Drop unnecessary variables
	drop bp_sys_date_measured bp_dias_date_measured
	
	* Date of daily landmark substudy 
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'


	
	**********************************
	*  Select case-control substudy  *
	**********************************
	
	* Outcome for this substudy: COVID-19 death today
	qui drop onscoviddeath
	qui gen onscoviddeath = (died_date_onscovid)==`date_in'
	label var onscoviddeath "COVID-19 related death on this day"
	capture drop stime*
	
	* Select ... all COVID deaths
	qui gen keep = onscoviddeath
	
	* ... and a sample of controls, randomly selected by agegroup
	forvalues j = 1 (1) 6 {
		qui replace keep = 1 if uniform()<=`sf`j'' & agegroup==`j'
	}
	qui keep if keep==1 
	qui drop keep


	
	********************
	*  Sample weights  *
	********************
	
	* Create variable containing sampling weights
	gen sf_wts = .	
	label var sf_wts "Sampling fraction weights"

	* Case 
	replace sf_wts = 1 if onscoviddeath == 1 
	
	* Non-case weights
	forvalues j = 1 (1) 6 {
		replace sf_wts = 1/`sf`j'' if agegroup==`j' ///
					& onscoviddeath == 0 
	}

	* Tidy and save dataset
	qui gen time = `i'
	qui label var time "Day of landmark substudy"
	qui save "daily_covid_time_`i'", replace
}
	



****************************************
*  Define covariates in each substudy  *
****************************************

forvalues i = 1 (1) 100 {
	qui use "daily_covid_time_`i'.dta", clear
	qui summ time
	local study_first_date = d(1/03/2020) + `i' - 1

	* Define covariates as of 1st March 2020
	qui define_covs, dateno(`study_first_date')
	qui save "daily_covid_time_`i'.dta", replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use "daily_covid_time_1.dta", clear
forvalues i = 2 (1) 100 {
	qui append using "daily_covid_time_`i'.dta"
}

* Delete unneeded datasets
forvalues i = 1 (1) 100 {
	qui erase "daily_covid_time_`i'.dta"
}

* Delete unneeded variables
drop days_until_coviddeath days_until_otherdeath



****************************************
*  Add in time-varying infection data  *
****************************************

recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)


* Merge in the force of infection data
merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
	assert(match using) keep(match) nogen 
drop agegroupfoi

* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen

* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen






******************
*  Save dataset  *
******************

order time patient_id
sort time patient_id 
label data "Single-day landmark substudies for COVID-19 death (complete case ethnicity)"
save "data/cr_daily_landmark_covid.dta", replace

* Close log file
log close

