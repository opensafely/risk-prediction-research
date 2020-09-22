********************************************************************************
*
*	Do-file:		002_cr_case_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		output/cr_training.dta (training dataset)
*
*	Data created:	
*					output/cr_tr_casecohort_var_select.dta (training variable selection)
*					output/cr_tr_casecohort_models.dta (training modelling fitting) 
*
*
*	Other output:	Log file:  cr_case_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file creates two case cohort datasets to perform
*					model fitting in for the risk prediction models.
*
*					The first is for variable selection.
*
*					The second is for model fitting.
*
*	NOTE: 			Both cohorts remove people with missing ethnicity information.
*  
********************************************************************************* 





*************************
*  Validation Cohort 1  *
*************************

* Open underlying base cohort (4/5 of original TPP cohort)
use "data/cr_training_dataset.dta", replace

* Keep ethnicity complete cases
drop if ethnicity>=.



*  Extract relevant covariates  *


* Define covariates as of 1st March 2020
define_covs, date(1/03/2020)

*  Start and end dates  *

* Start date 1 March 2020
* End date 28 Mar 2020 (inclusive)

assert died_date_onscovid>=d(1/03/2020)
capture drop onscoviddeath stime
gen onscoviddeath = inrange(died_date_onscovid - d(1/03/2020) + 1, 1, 28)

gen stime = died_date_onscovid - d(1/03/2020) + 1
replace stime = 28 if onscoviddeath==0

* Observed risk
gen obs = (onscoviddeath==1)
label var obs "Observed risk"
save "data/validate1", replace




*************************
*  Validation Cohort 2 *
*************************


* Open underlying base cohort (4/5 of original TPP cohort)
use "data/cr_training_dataset.dta", replace

* Keep ethnicity complete cases
drop if ethnicity>=.


*  Extract relevant covariates  *


* Define covariates as of 1st March 2020
define_covs, date(1/04/2020)

*  Start and end dates  *

* Start date 1 April 2020
* End date 28 April 2020 (inclusive)

drop if died_date_onscovid<d(1/04/2020)
drop if died_date_onsother<d(1/04/2020)

capture drop onscoviddeath stime
gen onscoviddeath = inrange(died_date_onscovid - d(1/04/2020) + 1, 1, 28)

gen stime = died_date_onscovid - d(1/04/2020) + 1
replace stime = 28 if onscoviddeath==0

* Observed risk
gen obs = (onscoviddeath==1)
label var obs "Observed risk"
save "data/validate2", replace




