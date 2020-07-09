********************************************************************************
*
*	Do-file:		200_rp_a_gamma.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  203_rp_a_gamma.log
*
********************************************************************************
*
*	Purpose:		This do-file performs generalized gamma survival models (AFT) 
*  
********************************************************************************


* Open a log file
capture log close
log using "./output/200_rp_a_gamma", text replace

use "data/cr_casecohort_models.dta", replace


*******************************
*   Generalized gamma models  *
*******************************

timer clear 1
timer on 1
streg age1 age2 age3 i.male , dist(ggamma) vce(robust)
estat ic 
timer off 1
timer list 1

**********************************************
*   Survival predictions from gamma models   *
**********************************************

gen time = _t 
gen fail = _d 

replace  _d = 0 if time > 28 
replace _t = 28 if time > 28

* Survival at 28 days  
predict surv28_gam , surv 

* Absolute risk at 28 days
gen risk_gam28   = 1-surv28_gam

* Quantiles of predicted 28 day risk

centile risk_gam28, c(10 20 30 40 50 60 70 80 90)





log close






