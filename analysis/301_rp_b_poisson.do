********************************************************************************
*
*	Do-file:		301_rp_b_poisson.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_`tvc'.dta, where tvc=foi, ae, susp
*
*	Other output:	Log file:  	output/301_rp_b_poisson_`tvc'.log
*					Estimates:	output/models/coefs_b_pois_`tvc'.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases. 
*
********************************************************************************


* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/301_rp_b_poisson_`tvc'", text replace



*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"






***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark.dta", clear




*********************
*   Poisson Model   *
*********************

capture erase output/models/coefs_b_pois_`tvc'.ster

* Fit model
timer clear 1
timer on 1
streg ${selected_vars_landmark_`tvc'}, dist(exp) ///
	robust cluster(patient_id) 
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_b_pois_`tvc', replace



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
