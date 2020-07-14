********************************************************************************
*
*	Do-file:		201_rp_a_roy.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  201_rp_a_roy.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Royston-Parmar
*					flexible hazard modelling. 
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************

*The following statistical models will be fitted, with time since 1st March  
*In each case the model will be fitted without taking shielding into consideration, and then splitting time at 31st March/1st April and including shielding period and any interactions identified by the lasso in the models.  
* robust std errs


* Open a log file
capture log close
log using "./output/rp_a_parametric_survival_models_roy", text replace

************************************************
*   Fit on model development and evaluation datasets *
************************************************

use "data/cr_casecohort_models.dta", replace

*********************************
*   Set data on ons covid death *
*********************************
*
stset stime_onscoviddeath, fail(onscoviddeath) 				///
  id(patient_id) enter(enter_date) origin(enter_date) // adds need to be added here

*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************

drop if ethnicity>=.


* Create numerical region variable // move to cr_create
encode region, gen(region_new)
drop region
rename region_new region



*********************
*   Royston-Parmar  *
*********************


rename reduced_kidney_function_cat red_kidney_cat
rename chronic_respiratory_disease respiratory_disease
rename chronic_cardiac_disease cardiac_disease
rename other_immunosuppression immunosuppression


* Create dummy variables for categorical predictors 
foreach var of varlist obese4cat smoke_nomiss imd  		///
	asthmacat diabcat cancer_exhaem_cat cancer_haem_cat ///
	red_kidney_cat	region					///
	{
		egen ord_`var' = group(`var')
		qui summ ord_`var'
		local max=r(max)
		forvalues i = 1 (1) `max' {
			gen `var'_`i' = (`var'==`i')
		}	
		drop ord_`var'
		drop `var'_1
}


timer clear 1
timer on 1
stpm2  age1 age2 age3 male 					///
			 ,						///
			scale(hazard) df(5) eform
estat ic
timer off 1
timer list 1



gen time1 = 28 
predict s_time, survival timevar(time1) 
hist s_time

gen time2= 70
predict s_time1 , survival timevar(time2)
*****************************************************
*   Survival predictions from Royston-Parmar model  *
*****************************************************

gen time28 = 28

* calculate 01mar + 60
* pred =. if dead <=

gen time60 = 60 + 28

 
gen time80 = 80


* Survival at t
predict surv_royp, surv timevar(_t)

* Survival at 30 days
predict surv28_royp, surv timevar(time28)

* Survival at 60 days
predict surv60_royp, surv timevar(time60)

* Survival at 80 days
predict surv80_royp, surv timevar(time80)


* Absolute risk at 30, 60 and 80 days
gen risk_royp   = 1-surv_royp
gen risk30_royp = 1-surv30_royp
gen risk60_royp = 1-surv60_royp
gen risk80_royp = 1-surv80_royp



/*  Quantiles of predicted 30, 60 and 80 day risk   */

centile risk30_royp, c(10 20 30 40 50 60 70 80 90)
centile risk60_royp, c(10 20 30 40 50 60 70 80 90)
centile risk80_royp, c(10 20 30 40 50 60 70 80 90)








log close

