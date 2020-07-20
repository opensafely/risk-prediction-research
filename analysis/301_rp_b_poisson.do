********************************************************************************
*
*	Do-file:		rp_b_poisson.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_tr_landmark_models.dta
*
*	Data created:	?????
*
*	Other output:	Log file:  			rp_b_poisson.log
*					Model estimates: 	rp_b_poisson.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death. 
*
********************************************************************************



* Open a log file
capture log close
log using "./output/rp_b_poisson", text replace
cap erase ./output/models/rp_b_poisson.ster


do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors"


***************
*  Open data  *
***************


use "data/cr_tr_landmark_models.dta", clear




*************************
*   Poisson regression  *
*************************


* Barlow weights used as an offset, alongside the usual offset (exposure time)
gen offset = log(dayout - dayin) + log(sf_wts)

* Fit model
timer clear 1
timer on 1
poisson onscoviddeath $predictors, robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

* Save estimates
*estimates
*estimates save ./output/models/rp_b_poisson_regression_models.ster, replace
*poisson, irr
 
 

 

************************************
*   Predict 28 day COVID-19 death  *
************************************







* Close log file
log close

