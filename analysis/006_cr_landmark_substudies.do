********************************************************************************
*
*	Do-file:		006_cr_landmark_substudies.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_base_cohort.dta (cohort data)
*					data/foi_coefs.dta      (force of infection data)
*					data/ae_coefs.dta       (A&E COVID attendance data)
*					data/susp_coefs.dta     (GP suspected COVID data)
*
*	Data created:	data/cr_landmark.dta 
*								(landmark: modelling fitting) 
*					cr_landmark_noupdate
*								(landmark: covariates fixed at baseline) 
*
*
*	Other output:	Log file:  006_cr_landmark_substudies.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a dataset containing stacked landmark
*					substudies, each of 28 days, to perform model fitting in,
*					for the risk prediction models.
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
log using "output/006_cr_landmark_substudies", replace t


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

	* Open underlying base training cohort (4/5 of original TPP cohort)
	use "data/cr_base_cohort.dta", replace

	* Keep ethnicity complete cases
	drop ethnicity_5 ethnicity_16
	drop if ethnicity_8>=.
	
	* Drop unnecessary variables
	drop bp_sys_date_measured bp_dias_date_measured
	
	* Date landmark substudy i starts
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'


	
	*************************************************************
	*  Event indicator and survival time for the 28 day period  *
	*************************************************************
	
	* Date this landmark started: d(1/03/2020) + `i' - 1
	* Days until death:  died_date_onscovid - {d(1/03/2020) + `i' - 1} + 1
	
	* Survival time (must be between 1 and 28)
	qui capture drop stime
	qui gen stime28 = (died_date_onscovid - (d(1/03/2020) + `i' - 1) + 1) ///
			if died_date_onscovid < .
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 & stime28>28
	qui replace stime28 = 28 if onscoviddeath==0
	noi bysort onscoviddeath: summ stime28

	
	
	*********************************
	*  Select substudy case-cohort  *
	*********************************
	
	* Keep all cases and a random sample of controls (by agegroup)
	qui gen subcohort = 0
	forvalues j = 1 (1) 6 {
		qui replace subcohort = 1 if uniform()<=`sf`j'' & agegroup==`j'
	}
	label var subcohort "Random subcohort"
	tab subcohort onscoviddeath 
	qui keep if subcohort==1 | onscoviddeath==1
	tab subcohort onscoviddeath 


	

	*******************************
	*  Sampling fraction weights  *
	*******************************

	gen sf_inv = .	
	label var sf_inv "Inverse of sampling fraction"

	* Case: weight = 1
	replace sf_inv = 1 if onscoviddeath == 1 

	* Non-cases: weight = 1/SF (age-group specific)
	forvalues j = 1 (1) 6 {
		replace sf_inv = 1/`sf`j'' if agegroup==`j' & onscoviddeath == 0 
	}


	* Start and stop dates for follow-up
	gen 	dayin  = 0
	gen  	dayout = stime28
	qui drop stime28
	
	label var dayin  "Day enters risk set (landmark case-cohort)"
	label var dayout "Day exits risk set (landmark case-cohort)"
	
	* Tidy and save dataset
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
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
drop foi_c_cons foi_c_day foi_c_daysq foi_c_daycu


* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen
drop ae_c_cons ae_c_day ae_c_daysq ae_c_daycu


* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen
drop susp_c_cons susp_c_day susp_c_daysq susp_c_daycu




/*  Create time-varying variables needed  */

* Variables needed for force of infection data

gen logfoi = log(foi)
gen foiqd  =  foi_q_day/foi_q_cons
gen foiqds =  foi_q_daysq/foi_q_cons


* Variables needed for A&E attendance data
gen aepos = aerate
noi summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons

replace aeqd  = 0 if ae_q_cons==0
replace aeqds = 0 if ae_q_cons==0

gen aeqint 		= aeqd*aeqds
gen aeqd2		= aeqd^2
gen aeqds2		= aeqds^2


* Variables needed for GP suspected case data

gen susppos = susp_rate
noi summ susp_rate if susp_rate>0 
replace susppos = susppos + r(min)/2 if susppos==0

* Create time variables to be fed into the variable selection process
gen logsusp	 	= log(susppos)
gen suspqd	 	= susp_q_day/susp_q_cons
gen suspqds 	= susp_q_daysq/susp_q_cons

replace suspqd  = 0 if susp_q_cons==0
replace suspqds = 0 if susp_q_cons==0

gen suspqint   	= suspqd*suspqds
gen suspqd2 	= suspqd^2
gen suspqds2	= suspqds^2


* Label time-varying variables
label var logfoi	"Log of the estimated force of infection" 
label var foiqd  	"Standardised quadratic term, day, FOI"
label var foiqds	"Standardised quadratic term, day-squared, FOI"
	
label var aepos		"A&E COVID-19 rate (no zeros)"
label var logae		"Log of the A&E COVID-19 rate" 
label var aeqd		"Standardised quadratic term, day, A&E"
label var aeqds 	"Standardised quadratic term, day-squared, A&E"
label var aeqint 	"Standardised quadratic term, interaction, A&E"
label var aeqd2		"Standardised quadratic term, day^2, A&E"
label var aeqds2	"Standardised quadratic term, day-squared^2, A&E"	

label var susppos	"Primary care (GP) suspected COVID-19 rate (no zeros)"
label var logsusp	"Log of the primary care (GP) suspected COVID-19 rate" 
label var suspqd	"Standardised quadratic term, day, GP"
label var suspqds 	"Standardised quadratic term, day-squared, GP"
label var suspqint  "Standardised quadratic term, interaction, GP"
label var suspqd2 	"Standardised quadratic term, day^2, GP"
label var suspqds2	"Standardised quadratic term, day-squared^2, GP"




**********************
*  Barlow Weighting  *
**********************


/*  Split at-risk time into two for subcohort cases (event and prior to)  */

isid patient_id time

* Expand dataset for cases in subcohort 2 lines for cases in subcohort
expand 2 if subcohort == 1 & onscoviddeath == 1 
bysort patient_id time: gen row = _n



/*  Prior to event, subcohort cases have weight 1/SF (not 1 as above) */

* Change sampling fraction weights for subcohort cases (prior to being a case)
gen sf_wts = sf_inv
label var sf_wts "Sampling fraction weights (Barlow)"
drop sf_inv

forvalues j = 1 (1) 6 {
	replace sf_wts = 1/`sf`j'' if agegroup==`j' /// 
			& onscoviddeath == 1 & subcohort == 1 & row == 1
}



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



*******************
*  Save dataset  *
*******************


* Declare as survival data
sort time patient_id dayin
gen newid = _n
label var newid "Row ID"
stset dayout [pweight=sf_wts], fail(onscoviddeath) enter(dayin) id(newid)  

order time patient_id onscoviddeath subcohort sf_wts dayin dayout
sort time patient_id

label data "28-day landmark substudies (complete case ethnicity) for model fitting"
note: Stset treats rows as if from different people; SEs will be incorrect
save "data/cr_landmark.dta", replace







				*******************************
				*   NOT UPDATING COVARIATES	  *	
				*******************************



* Open a log file
cap log close
log using "output/006_cr_landmark_substudies", replace t


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

	* Open underlying base training cohort (4/5 of original TPP cohort)
	use "data/cr_base_cohort.dta", replace

	* Keep ethnicity complete cases
	drop ethnicity_5 ethnicity_16
	drop if ethnicity_8>=.
	
	* Drop unnecessary variables
	drop bp_sys_date_measured bp_dias_date_measured
	
	* Date landmark substudy i starts
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'


	
	*************************************************************
	*  Event indicator and survival time for the 28 day period  *
	*************************************************************
	
	* Date this landmark started: d(1/03/2020) + `i' - 1
	* Days until death:  died_date_onscovid - {d(1/03/2020) + `i' - 1} + 1
	
	* Survival time (must be between 1 and 28)
	qui capture drop stime
	qui gen stime28 = (died_date_onscovid - (d(1/03/2020) + `i' - 1) + 1) ///
			if died_date_onscovid < .
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 & stime28>28
	qui replace stime28 = 28 if onscoviddeath==0
	noi bysort onscoviddeath: summ stime28

	
	
	*********************************
	*  Select substudy case-cohort  *
	*********************************
	
	* Keep all cases and a random sample of controls (by agegroup)
	qui gen subcohort = 0
	forvalues j = 1 (1) 6 {
		qui replace subcohort = 1 if uniform()<=`sf`j'' & agegroup==`j'
	}
	label var subcohort "Random subcohort"
	tab subcohort onscoviddeath 
	qui keep if subcohort==1 | onscoviddeath==1
	tab subcohort onscoviddeath 


	

	*******************************
	*  Sampling fraction weights  *
	*******************************

	gen sf_inv = .	
	label var sf_inv "Inverse of sampling fraction"

	* Case: weight = 1
	replace sf_inv = 1 if onscoviddeath == 1 

	* Non-cases: weight = 1/SF (age-group specific)
	forvalues j = 1 (1) 6 {
		replace sf_inv = 1/`sf`j'' if agegroup==`j' & onscoviddeath == 0 
	}


	* Start and stop dates for follow-up
	gen 	dayin  = 0
	gen  	dayout = stime28
	qui drop stime28
	
	label var dayin  "Day enters risk set (landmark case-cohort)"
	label var dayout "Day exits risk set (landmark case-cohort)"
	
	* Tidy and save dataset
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
	qui save time_`i', replace
}



****************************************
*  Define covariates in each substudy  *
****************************************

forvalues i = 1 (1) 73 {
	qui use time_`i'.dta, clear
	local study_first_date = d(1/03/2020) 

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
drop foi_c_cons foi_c_day foi_c_daysq foi_c_daycu


* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen
drop ae_c_cons ae_c_day ae_c_daysq ae_c_daycu


* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen
drop susp_c_cons susp_c_day susp_c_daysq susp_c_daycu





/*  Create time-varying variables needed  */

* Variables needed for force of infection data

gen logfoi = log(foi)
gen foiqd  =  foi_q_day/foi_q_cons
gen foiqds =  foi_q_daysq/foi_q_cons


* Variables needed for A&E attendance data
gen aepos = aerate
noi summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons

replace aeqd  = 0 if ae_q_cons==0
replace aeqds = 0 if ae_q_cons==0

gen aeqint 		= aeqd*aeqds
gen aeqd2		= aeqd^2
gen aeqds2		= aeqds^2


* Variables needed for GP suspected case data

gen susppos = susp_rate
noi summ susp_rate if susp_rate>0 
replace susppos = susppos + r(min)/2 if susppos==0

* Create time variables to be fed into the variable selection process
gen logsusp	 	= log(susppos)
gen suspqd	 	= susp_q_day/susp_q_cons
gen suspqds 	= susp_q_daysq/susp_q_cons

replace suspqd  = 0 if susp_q_cons==0
replace suspqds = 0 if susp_q_cons==0

gen suspqint   	= suspqd*suspqds
gen suspqd2 	= suspqd^2
gen suspqds2	= suspqds^2


* Label time-varying variables
label var logfoi	"Log of the estimated force of infection" 
label var foiqd  	"Standardised quadratic term, day, FOI"
label var foiqds	"Standardised quadratic term, day-squared, FOI"
	
label var aepos		"A&E COVID-19 rate (no zeros)"
label var logae		"Log of the A&E COVID-19 rate" 
label var aeqd		"Standardised quadratic term, day, A&E"
label var aeqds 	"Standardised quadratic term, day-squared, A&E"
label var aeqint 	"Standardised quadratic term, interaction, A&E"
label var aeqd2		"Standardised quadratic term, day^2, A&E"
label var aeqds2	"Standardised quadratic term, day-squared^2, A&E"	

label var susppos	"Primary care (GP) suspected COVID-19 rate (no zeros)"
label var logsusp	"Log of the primary care (GP) suspected COVID-19 rate" 
label var suspqd	"Standardised quadratic term, day, GP"
label var suspqds 	"Standardised quadratic term, day-squared, GP"
label var suspqint  "Standardised quadratic term, interaction, GP"
label var suspqd2 	"Standardised quadratic term, day^2, GP"
label var suspqds2	"Standardised quadratic term, day-squared^2, GP"



**********************
*  Barlow Weighting  *
**********************


/*  Split at-risk time into two for subcohort cases (event and prior to)  */

isid patient_id time

* Expand dataset for cases in subcohort 2 lines for cases in subcohort
expand 2 if subcohort == 1 & onscoviddeath == 1 
bysort patient_id time: gen row = _n



/*  Prior to event, subcohort cases have weight 1/SF (not 1 as above) */

* Change sampling fraction weights for subcohort cases (prior to being a case)
gen sf_wts = sf_inv
label var sf_wts "Sampling fraction weights (Barlow)"
drop sf_inv

forvalues j = 1 (1) 6 {
	replace sf_wts = 1/`sf`j'' if agegroup==`j' /// 
			& onscoviddeath == 1 & subcohort == 1 & row == 1
}



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



*******************
*  Save dataset  *
*******************


* Declare as survival data
sort time patient_id dayin
gen newid = _n
label var newid "Row ID"
stset dayout [pweight=sf_wts], fail(onscoviddeath) enter(dayin) id(newid)  

order time patient_id onscoviddeath subcohort sf_wts dayin dayout
sort time patient_id

label data "28-day landmark substudies (complete case ethnicity) for model fitting"
note: Stset treats rows as if from different people; SEs will be incorrect
save "data/cr_landmark_noupdate.dta", replace




* Close log file
log close

