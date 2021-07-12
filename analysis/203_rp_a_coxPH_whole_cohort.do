********************************************************************************
*
*	Do-file:		203_rp_a_coxPH_whole_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_coxPH_whole_cohort.dta
*
*	Other output:	Log file:  	output/203_rp_a_coxPH_whole_cohort.log
*					Estimates:	output/models/coefs_a_cox_whole_cohort.ster
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model but without adopting a case cohort sample; an analysis
*					suggested by reviewers. 
*  
********************************************************************************


* Open a log file
cap log close
log using "./output/203_rp_a_coxPH_whole_cohort", text replace


* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"



***************************************************
*  Open the cohort dataset and obtain covariates  *
***************************************************

	
/* Open base cohort   */ 

use "data/cr_base_cohort.dta", replace
* drop stime onscoviddeath
	


/* Complete case for ethnicity   */ 

drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.
	
	
/* Apply eligibility criteria for validation period i  */ 

* Remove anyone who died prior to vcohort start
drop if died_date_onsother < d(01/03/2020)
	
	
/*  Extract relevant covariates  */

* Define covariates as of the start date of the validation period
local start = d(01/03/2020)
define_covs, dateno(`start')


/*  Survival settings  */

* Declare as survival data 
stset stime, fail(onscoviddeath) 




****************************
*  Pick up predictor list  *
****************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$selected_vars"



*******************
*   CoxPH Model   *
*******************

capture erase output/models/coefs_a_cox_whole_cohort.ster

timer clear 1
timer on 1
stcox $selected_vars , vce(robust)
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_a_cox_whole_cohort, replace




***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
predict basesurv, basesurv
summ basesurv if _t <= 28 
global base_surv28 = r(min) // baseline survival decreases over time

summ basesurv if _t <= 100 
global base_surv100 = r(min) 

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv28 , $base_surv100 , b]
local names: colfullnames b
local names: subinstr local names "c1" "base_surv28"
local names: subinstr local names "c2" "base_surv100"
mat colnames b = `names'

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("")  ///
	dataname("data/model_a_coxPH_whole_cohort")



log close

