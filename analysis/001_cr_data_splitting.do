********************************************************************************
*
*	Do-file:		001_cr_data_splitting.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		cr_base_cohort.dta (base cohort)
*
*	Data created:	data/cr_training.dta (training dataset)
*					data/cr_evaluation.dta (evaluation dataset)
*
*
*	Other output:	Log file:  cr_data_splitting.log
*
********************************************************************************
*
*	Purpose:		This do-file creates the training and (time-internal) 
*					evaluation datasets.
*  
********************************************************************************

* Open a log file
cap log close
log using "output/001_cr_data_splitting", replace t



*************************
*  End date for cohort  *
*************************

* Last date at which participants are at risk
local cohort_first_date = d(1/03/2020)
local cohort_last_date  = d(9/05/2020)



************************************************
*  Open base cohort and create binary outcome  *
************************************************

* Open TPP base cohort
use "data/cr_base_cohort.dta", replace

* For training and time-internal evaluation: 
*   Outcome = COVID-19 death until 10 May (inclusive)
gen onscoviddeath = (died_date_onscovid) <= `cohort_last_date'
label var onscoviddeath "COVID-19 death (1 March - 10 May)"
drop died_date_onscovid

* Survival time
gen 	stime = days_until_coviddeath if onscoviddeath==1
replace stime = (`cohort_last_date' - `cohort_first_date' + 1) ///
	if onscoviddeath==0
label var stime "Survival time (days from 1 March; end 10 May) for COVID-19 death"

* Death from other causes is not needed for case-cohort analyses
drop died_date_onsother days_until_otherdeath



***************************************************
*  Split base cohort into training and evaluation *
***************************************************

set seed 37873
local splitPropn 0.8 // training dataset 4/5 of base cohort

bysort agegroup onscoviddeath: gen training = uniform() < `splitPropn'

* Check distributions
foreach v of numlist 0 1 { 
	tab agegroup 		if training == `v'
	tab onscoviddeath 	if training == `v'
}

* Create model evaluation dataset
preserve
keep if training == 0
drop training
label data "(Internal) evaluation dataset"
save "data/cr_evaluation_dataset.dta", replace
restore

* Create model training dataset
keep if training == 1 
drop training
label data "(External) evaluation dataset"
save "data/cr_training_dataset.dta", replace

* Close log file
log close

