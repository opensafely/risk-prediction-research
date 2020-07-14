********************************************************************************
*
*	Do-file:		004_cr_landmark_substudies.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		output/cr_training.dta (training dataset)
*
*	Data created:	
*					output/cr_tr_landmark_models.dta (training modelling fitting) 
*
*
*	Other output:	Log file:  cr_landmark.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a dataset containing stacked landmark
*					substudies, each of 28 days, to perform model fitting in
*					for the risk prediction models.
*
*	NOTE: 			These landmark substudies remove people with missing 
*					ethnicity information.
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/002_cr_landmark", replace t



***********************
*  Create substudies  *
***********************

* Age-group-stratified sampling fractions
local sf1 = 0.01
local sf2 = 0.02
local sf3 = 0.02
local sf4 = 0.025
local sf5 = 0.05
local sf6 = 0.13


* Set random seed for replicability
set seed 37873


* Create separate landmark substudies
forvalues i = 1 (1) 43 {


	* Open underlying base training cohort (4/5 of original TPP cohort)
	use "data/cr_training_dataset.dta", replace

	* Keep ethnicity complete cases
	drop if ethnicity>=.
		
	* Drop people who have died prior to day i 
	qui drop if (died_date_onscovid - d(1/03/2020) + 1) < `i' 
	qui drop if (died_date_onsother - d(1/03/2020) + 1) < `i' 
	
	
	*********************************
	*  Select substudy case-cohort  *
	*********************************
	
	* Survival time (must be between 1 and 28)
	qui capture drop stime
	qui gen stime = (died_date_onscovid - `cohort_first_date' + 1) ///
			- `i' + 1 if died_date_onscovid < .
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 &  ///
		stime>28
	qui replace stime = 28 if onscoviddeath==0
	noi bysort onscoviddeath: summ stime
	
	* Keep all cases and a random sample of controls (by agegroup)
	qui gen subcohort = 0
	forvalues j = 1 (1) 6 {
		qui replace subcohort = 1 if uniform()<=`sf`j'' & agegroup==`j'
	}
	label var subcohort "Random subcohort"
	tab subcohort onscoviddeath 
	qui keep if subcohort==1 | onscoviddeath==1
	tab subcohort onscoviddeath 


	
	**********************
	*  Barlow Weighting  *
	**********************

	* Expand dataset for cases in subcohort 2 lines for cases in subcohort
	expand 2 if subcohort == 1 & onscoviddeath == 1 

	* Apply weighting scheme
	bysort patient_id: gen row = _n
	
	gen sf_wts = .	
	* Case in subcohort at event
	replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 1 & row == 2
	* Case outside subcohort at event 
	replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 0 
	label var sf_wts "Sampling fraction weights (Barlow)"
	
	* Subcohort weights
	forvalues j = 1 (1) 6 {
		* Non-case in subcohort
		replace sf_wts = 1/`sf`j'' if agegroup==`j' ///
					& onscoviddeath == 0 & subcohort == 1  
		* Case in subcohort before event
		replace sf_wts = 1/`sf`j'' if agegroup==`j' ///
					& onscoviddeath == 1 & subcohort == 1 & row == 1
	}

	
	* Start and stop dates for follow-up
	gen 	dayin  = 0
	gen  	dayout = stime
	replace dayout = 1.5 if dayout==1
	
	replace dayout = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 1
	replace dayin  = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 2
	
	replace onscoviddeath = 0 if onscoviddeath == 1 & subcohort == 1 & row == 1
	drop row
	
	label var dayin  "Day (this row of data) enters risk set (case-cohort)"
	label var dayout "Day (this row of data) exits risk set (case-cohort)"
	
	* Tidy and save dataset
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
	qui drop stime
	qui save time_`i', replace
}
	



****************************************
*  Define covariates in each substudy  *
****************************************

forvalues i = 1 (1) 43 {
	qui use time_`i'.dta, clear
	qui summ time
	local study_first_date = d(1/03/2020) + r(mean) - 1

	* Define covariates as of 1st March 2020
	qui define_covs, dateno(`study_first_date')
	qui save time_`i', replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use time_1.dta, clear
forvalues i = 2 (1) 43 {
	qui append using time_`i'
}

* Delete unneeded datasets
forvalues i = 1 (1) 43 {
	qui erase time_`i'.dta
}




***********************************************
*  Split pre-shielding and shielding periods  *
***********************************************


gen day_since1mar_in  = time + dayin
gen day_since1mar_out = time + dayout

gen datein  = td(1mar2020) + day_since1mar_in  - 1
gen dateout = td(1mar2020) + day_since1mar_out - 1
format datein dateout %td

* Create binary shielding indicator
gen newid = _n
stset day_since1mar_out, fail(onscoviddeath) enter(day_since1mar_in) id(newid)
stsplit shield, at(32)
recode shield 32=1
label define shield 0 "Pre-shielding" 1 "Shielding"
label values shield shield
label var shield "Binary shielding (period) indicator"
recode onscoviddeath .=0

replace dayin = _t0 - time
replace dayout = _t - time
drop datein dateout day_since1mar_in day_since1mar_out newid _*
sort time patient_id dayin 




****************************************
*  Add in time-varying infection data  *
****************************************


* Merge in the summary infection prevalence data
*merge m:1 time using infected_coefs, assert(match using) keep(match) nogen 

* Merge in the infection and immunity data prevalence data
*merge m:1 time using infect_immune, assert(match using) keep(match) nogen ///
*	keepusing(susc infect)




******************
*  Save dataset  *
******************

label data "Training data 28-day landmark substudies (complete case ethnicity) for model fitting"
save "data/cr_tr_landmark_models.dta", replace

* Close log file
log close

