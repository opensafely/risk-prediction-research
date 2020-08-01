********************************************************************************
*
*	Do-file:		006_cr_daily_landmark_noncovid_substudies.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta 
*
*	Data created:	data/cr_daily_landmark_noncovid.dta 
*
*	Other output:	Log file:  005_cr_daily_noncovid_landmark.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a dataset containing stacked landmark
*					substudies, each of a single day, to perform model fitting in,
*					for daily prediction models for NON-COVID-19-related death.
*
*	NOTE: 			These landmark substudies remove people with missing 
*					ethnicity information.
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/005_cr_daily_noncovid_landmark", replace t



***********************
*  Create substudies  *
***********************
***********************************  MUST UPDATE *********************************
* True sampling fractions below. Don't work in dummy data
* Age-group-stratified sampling fractions 
*local sf1 = 0.01/100
*local sf2 = 0.02/100
*local sf3 = 0.02/100
*local sf4 = 0.025/100
*local sf5 = 0.05/100
*local sf6 = 0.13/100
*local sfd = 0.3
local sf1 = 0.2
local sf2 = 0.2
local sf3 = 0.2
local sf4 = 0.2
local sf5 = 0.2
local sf6 = 0.2

local sfd = 1
***********************************  MUST UPDATE *********************************


* Set random seed for replicability
set seed 37873


* Create separate landmark substudies
forvalues i = 1 (1) 100 {


	* Open underlying base cohort
	use "data/cr_base_cohort.dta", replace

	* Keep ethnicity complete cases
	drop ethnicity_5 ethnicity_16
	drop if ethnicity_8>=.
	
	* Date of daily landmark substudy 
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'


	
	**********************************
	*  Select case-control substudy  *
	**********************************
	
	* Outcome for this substudy: non-COVID-19 death today
	qui drop onscoviddeath
	qui gen onsotherdeath = (died_date_onsother)==`date_in'
	label var onsotherdeath "Non-COVID-19 related death on this day"
	capture drop stime*
	
	* Select ... all non-COVID deaths
	qui gen     keep = 0
	qui replace keep = 1 if uniform()<=`sfd' & onsotherdeath==1
	
	* ... and a sample of controls, randomly selected by agegroup
	forvalues j = 1 (1) 6 {
		qui replace keep = 1 if uniform()<=`sf`j'' 		///
								& agegroup==`j' 		///
								& onsotherdeath==0
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
	replace sf_wts = 1 if onsotherdeath == 1 & 
	
	* Non-case weights
	forvalues j = 1 (1) 6 {
		replace sf_wts = 1/`sf`j'' if agegroup==`j' ///
					& onsotherdeath == 0 
	}

	* Tidy and save dataset
	qui gen time = `i'
	qui label var time "Day of landmark substudy"
	qui save "daily_noncovid_time_`i'", replace
}
	



****************************************
*  Define covariates in each substudy  *
****************************************

forvalues i = 1 (1) 100 {
	qui use "daily_noncovid_time_`i'.dta", clear
	qui summ time
	local study_first_date = d(1/03/2020) + `i' - 1

	* Define covariates as of 1st March 2020
	qui define_covs, dateno(`study_first_date')
	qui save "daily_noncovid_time_`i'.dta", replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use "daily_noncovid_time_1.dta", clear
forvalues i = 2 (1) 100 {
	qui append using "daily_noncovid_time_`i'.dta"
}

* Delete unneeded datasets
forvalues i = 1 (1) 100 {
	qui erase "daily_noncovid_time_`i'.dta"
}

* Delete unneeded variables
drop days_until_coviddeath days_until_otherdeath


/*

***** NEED TO DEAL WITH THE SHIELDING SOMEHOW

***********************************************
*  Split pre-shielding and shielding periods  *
***********************************************


*/






******************
*  Save dataset  *
******************

order time patient_id
sort time patient_id 
label data "Single-day landmark substudies for non-COVID-19 death (complete case ethnicity)"
save "data/cr_daily_landmark_noncovid.dta", replace

* Close log file
log close

