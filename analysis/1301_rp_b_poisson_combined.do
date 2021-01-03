********************************************************************************
*
*	Do-file:		1301_rp_b_poisson_combined.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_`tvc'.dta, where tvc=all, objective
*
*	Other output:	Log file:  	output/1301_rp_b_poisson_`tvc'.log
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different combinations of time-varying measures of disease:
*					all three (force of infection estimates, A&E attendances 
*					for COVID, and suspected GP COVID cases) or the two 
*					objective measures (A&E & GP). 
*
********************************************************************************


* Specify the time-varying measures: all (foi, ae and susp) or objective (ae & susp)
local tvc `1' 
noi di "`tvc'"
assert inlist("`tvc'", "all", "objective")



* Open a log file
capture log close
log using "./output/1301_rp_b_poisson_`tvc'", text replace



*******************************
*  Pick up predictor list(s)  *
*******************************

qui do "analysis/104_pr_variable_selection_landmark_output.do" 

global foi_covs 	= "${selected_vars_landmark_foi}"
global ae_covs 		= "${selected_vars_landmark_ae}"
global susp_covs 	= "${selected_vars_landmark_susp}"

global all_covs: list global(foi_covs) | global(ae_covs) 
global all_covs: list global(all_covs) | global(susp_covs)

global objective_covs: global(ae_covs) | global(susp_covs)


noi di `tvc'
noi di "${`tvc'_covs}"




***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark.dta", clear




*********************
*   Poisson Model   *
*********************


* Fit model
timer clear 1
timer on 1
streg  ${`tvc'_covs}, dist(exp) ///
	robust cluster(patient_id) 
estat ic
timer off 1
timer list 1




***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************


* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
global base_surv28 = exp(-28*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv28, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv28"
mat colnames b = `names'


/*  Save coefficients to Stata dataset  */

qui do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
	dataname("data/model_b_poisson_`tvc'")



* Close log file
log close
