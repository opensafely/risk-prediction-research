********************************************************************************
*
*	Do-file:		203_rp_a_coxPH.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  203_rp_a_coxPH.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model 
*  
********************************************************************************

***** Are the variables centred... represents a `average` person????

* Open a log file
capture log close
log using "./output/203_rp_a_coxPH", text replace

use "data/cr_casecohort_models.dta", replace

*********************************
*   Set data on ons covid death *
*********************************
*
stset stime_onscoviddeath, fail(onscoviddeath) 				///
  id(patient_id) enter(enter_date) origin(enter_date)

  
* Testing
replace enter_date = td(29feb2020)
replace  _t0 = 0
replace _t = 100 // difference between 29Feb and 7Jun
replace  _t = ceil(rnormal(35, 8)) if onscoviddeath == 1 
replace _d = 1 if onscoviddeath == 1
replace _d = 0 if onscoviddeath == 0


*******************
*   CoxPH Model   *
*******************

timer clear 1
timer on 1
stcox  age1 age2 age3 male , vce(robust)
estat ic
timer off 1
timer list 1

******************************************
*   Survival predictions from Cox model  *
******************************************

* Predict xb and baseline survival 
predict  xb, xb
predict basesurv, basesurv

line basesurv _t, sort

* Calculating 28 day risk
sum basesurv if _t < 28 
local base28 = r(min) // baseline survival decreases over time

* Calculate risk 
gen risk28_cox = 1 - `base28'^exp(xb)

centile risk28_cox, c(10 20 30 40 50 60 70 80 90)






log close

