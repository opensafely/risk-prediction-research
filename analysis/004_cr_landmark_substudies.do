********************************************************************************
*
*	Do-file:		004_cr_landmark_substudies.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta 
*
*	Data created:	data/cr_landmark.dta (data for fitting landmark models) 
*
*
*	Other output:	Log file:  cr_landmark.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a dataset containing stacked landmark
*					substudies, each of 28 days, to perform model fitting in,
*					for the risk prediction models.
*
*	NOTE: 			These landmark substudies remove people with missing 
*					ethnicity information.
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/004_cr_landmark", replace t


* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"



***********************
*  Create substudies  *
***********************

* Age-group-stratified sampling fractions 
local sf1 = 0.01/70
local sf2 = 0.02/70
local sf3 = 0.02/70
local sf4 = 0.025/70
local sf5 = 0.05/70
local sf6 = 0.13/70


* Set random seed for replicability
set seed 37873


* Create separate landmark substudies
forvalues i = 1 (1) 73 {

	* Open underlying base cohort
	use "data/cr_base_cohort.dta", replace

	* Keep ethnicity complete cases
	drop ethnicity_5 ethnicity_16
	drop if ethnicity_8>=.
	
	* Date landmark substudy i starts
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'


	
	*********************************
	*  Select substudy case-cohort  *
	*********************************
	
	* Survival time (must be between 1 and 28)
	qui capture drop stime
	qui gen stime28 = died_date_onscovid - `date_in' + 1 
	assert stime28 >= . if died_date_onscovid >= .	
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 & stime>28
	qui replace stime28 = 28 if onscoviddeath==0
	noi bysort onscoviddeath: summ stime28
	
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
	
	* Create variable containing Barlow weights (~sampling weights)
	gen sf_wts = .	
	label var sf_wts "Sampling fraction weights (Barlow)"

	* Case in subcohort at event
	replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 1 & row == 2
	* Case outside subcohort at event 
	replace sf_wts = 1 if onscoviddeath == 1 & subcohort == 0 
	
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
	gen  	dayout = stime28
	replace dayout = 1.5 if dayout==1
	
	replace dayout = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 1
	replace dayin  = dayout-1 if onscoviddeath == 1 & subcohort == 1 & row == 2
	
	replace onscoviddeath = 0 if onscoviddeath == 1 & subcohort == 1 & row == 1
	drop row
	
	label var dayin  "Day (this row of data) enters risk set (landmark case-cohort)"
	label var dayout "Day (this row of data) exits risk set (landmark case-cohort)"
	
	* Tidy and save dataset
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
	qui drop stime28
	qui save time_`i', replace
}
	



****************************************
*  Define covariates in each substudy  *
****************************************

forvalues i = 1 (1) 73 {
	qui use time_`i'.dta, clear
	local study_first_date = d(1/03/2020) + `i' - 1

	* Define covariates as of 1st March 2020
	qui define_covs, dateno(`study_first_date')
	qui save time_`i', replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use time_1.dta, clear
forvalues i = 2 (1) 73 {
	qui append using time_`i'
}

* Delete unneeded datasets
forvalues i = 1 (1) 73 {
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
label var shield "Binary shielding indicator (pre-post 1 April)"
recode onscoviddeath .=0

replace dayin = _t0 - time
replace dayout = _t - time
drop datein dateout day_since1mar_in day_since1mar_out newid _*




****************************************
*  Add in time-varying infection data  *
****************************************


/*  Force of infection data  */ 

recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)

merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
	keep(match) assert(match using) nogen
drop agegroupfoi 



/*  Objective measure: A&E data   */ 

****  LATER _ CROSS_CHECK STPS
**** LATER 0 ADD ASSERT AS APPROPRIATE 
merge m:1 time stp using "data/ae_coefs", keep(match master) nogen





******************
*  Save dataset  *
******************

order time patient_id
sort time patient_id dayin
label data "28-day landmark substudies (complete case ethnicity) for model fitting"
save "data/cr_landmark.dta", replace

* Close log file
log close

