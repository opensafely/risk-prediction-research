********************************************************************************
*
*	Do-file:		cr_create_data_splitting.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		cr_create_analysis_dataset.dta (base cohort)
*
*	Data created:	output/cr_create_training_dataset.dta (training dataset)
*					output/cr_create_evaluation_dataset.dta (evaluation dataset)
*					output/cr_create_casecohort_var_select.dta (variable selection)
*					output/cr_create_casecohort_model_fitting.dta (modelling fitting) 
*
*
*	Other output:	Log file:  cr_create_data_splitting.log
*
********************************************************************************
*
*	Purpose:		This do-file creates the training and evaluation datasets
*  
********************************************************************************

* Open a log file
cap log close
log using "output/cr_create_data_splitting", replace t

use "data/cr_create_analysis_dataset.dta", replace

***************************************************
*  Split base cohort into training and evaluation *
***************************************************

set seed 37873
local splitPropn 0.8 // training dataset 4/5 of base cohort

bysort agegroup onscoviddeath: gen training = uniform() < `splitPropn'

* Check distributions
foreach v of numlist 0 1 { 
tab agegroup if training == `v'
tab onscoviddeath if training == `v'
}

* Create model evaluation dataset
preserve
keep if training == 0
drop training
save "data/cr_create_evaluation_dataset.dta", replace
restore

* Create model training dataset
keep if training == 1 
drop training
save "data/cr_create_training_dataset.dta", replace


********************************************
*  Create case cohorts using training data *
********************************************

********************************************************
* Create variable selection and model fitting datasets *
********************************************************
use "data/cr_create_training_dataset.dta", replace

* Ratio:  1:50 real 1:3 dummy
local ratio 3
* Obtain sampling fraction for controls (50 x number covid cases)
qui count
local N = r(N)
qui count if onscoviddeath == 1
local nCont = r(N)*`ratio'
di `nCont'
	
* Obtain sampling fraction (1 for cases)
qui gen randomOrder = uniform()

* Create variable selection dataset
preserve
sort onscoviddeath randomOrder
gen sampleFlag = 1 if _n<=`nCont'
gen sf_weight = 1/(`nCont'/`N') if sampleFlag == 1
	
* Also keep all cases 
replace sampleFlag = 1 if onscoviddeath == 1
recode sf_weight . = 1
	
* Delete everyone not randomly selected and not a case
keep if sampleFlag == 1

tab onscoviddeath
* Save variable selection case cohort
save "data/cr_create_casecohort_var_select.dta", replace
restore

* Create model fitting dataset
replace randomOrder = uniform()
sort onscoviddeath randomOrder 
gen sampleFlag = 1 if _n<=`nCont'
gen sf_weight = 1/(`nCont'/`N') if sampleFlag == 1
	
* Also keep all cases 
replace sampleFlag = 1 if onscoviddeath == 1
recode sf_weight . = 1
	
* Delete everyone not randomly selected and not a case
keep if sampleFlag == 1

tab onscoviddeath
* Save model fitting case cohort
save "data/cr_create_casecohort_model_fitting.dta", replace

*
log close
