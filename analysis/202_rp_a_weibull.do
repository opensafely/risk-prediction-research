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
*	Purpose:		This do-file performs survival analysis using the weibull
*					model
*  
********************************************************************************

* Open a log file
capture log close
log using "./output/202_rp_a_weibull", text replace

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

**************
*   Weibull  *
**************

timer clear 1
timer on 1
streg age1 age2 age3 i.male , dist(weibull) vce(robust)
estat ic 
timer off 1
timer list 1


**********************************************
*   Survival predictions from Weibull model  *
**********************************************

* Allows you to change the risk predicted
gen time = _t 
gen fail = _d 

replace  _d = 0 if time > 28 
replace _t = 28 if time > 28

* Survival at 28 days  
predict surv28_weib , surv 

* Absolute risk at 28 days
gen risk_weib28   = 1-surv28_weib

* Quantiles of predicted 28 day risk

centile risk_weib28, c(10 20 30 40 50 60 70 80 90)









log close

