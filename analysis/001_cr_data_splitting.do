********************************************************************************
*
*	Do-file:		001_cr_data_splitting.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		cr_analysis_dataset.dta (base cohort)
*
*	Data created:	data/cr_training.dta (training dataset)
*					data/cr_evaluation.dta (evaluation dataset)
*
*
*	Other output:	Log file:  cr_data_splitting.log
*
********************************************************************************
*
*	Purpose:		This do-file creates the training and evaluation datasets
*  
********************************************************************************

* Open a log file
cap log close
log using "output/001_cr_data_splitting", replace t

use "data/cr_analysis_dataset.dta", replace

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
save "data/cr_evaluation_dataset.dta", replace
restore

* Create model training dataset
keep if training == 1 
drop training
save "data/cr_training_dataset.dta", replace

*
log close
