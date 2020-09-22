********************************************************************************
*
*	Do-file:			rp_c_dynamic_poisson.do
*
*	Written by:			Fizz
*
*	Data used:			cr_create_analysis_dataset.dta (cohort data)
*						infected_coefs_dm.dta (burden of infection over time)
*
*	Data created:		test.dta  
*
*	Other output:		Log file:  rp_c_dynamic_poisson.log
*
********************************************************************************
*
*	Purpose:			To give this analysis approach (dynamic poisson models)
*						a test run. 
*
********************************************************************************



* Open a log file
capture log close
log using "output/rp_c_dynamic_poisson", text replace


* Add relevant files to adopath
adopath ++ "`c(pwd)'/analysis/ado"

* Run do-file just in case
do "analysis/ado/daypois.ado"





***************************
*  Create daily datasets  *
***************************

use "data/cr_daily_landmark_covid.dta", clear

		
* Standard Poisson model (approximately)
gen cons = 1
daypois onscoviddeath										///
		male i.agegroup respiratory							///
		i.asthmacat cardiac i.diabcat 						///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv cons, 											///
		timeadj("None")										///
		timevar(foi_q_cons foi_q_day foi_q_daysq) 			///
		weight(sf_wts)  

/* 

* CF:	
poisson onscoviddeath										///
		male i.agegroup respiratory							///
		i.asthmacat cardiac i.diabcat 						///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, robust 

*/



* Today's infection
daypois onscoviddeath										///
		male i.agegroup respiratory							///
		i.asthmacat cardiac i.diabcat 						///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, 												///
		timeadj("Other")									///
		timevar(foi_q_cons) 								///
		weight(sf_wts)  
	
gen logfoi = log(foi_q_cons)

daypois onscoviddeath										///
		male i.agegroup respiratory							///
		i.asthmacat cardiac i.diabcat 						///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, 												///
		timeadj("Other")									///
		timevar(logfoi) 									///
		weight(sf_wts)  

		
* Model including quadratic model of FOI
constraint define 1 _b[b:_cons]=0
daypois onscoviddeath 										///
		male i.agegroup respiratory							///
		io1.asthmacat cardiac i.diabcat 					///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, 												///
		timeadj("Quadratic")								///
		timevar(foi_q_cons foi_q_day foi_q_daysq) 			///
		weight(sf_wts) constraint(1)
	
* Compare with version using other Poisson likelihood
daypois2 onscoviddeath 										///
		male i.agegroup respiratory							///
		io1.asthmacat cardiac i.diabcat 					///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, 												///
		timeadj("Quadratic")								///
		timevar(foi_q_cons foi_q_day foi_q_daysq) 			///
		weight(sf_wts) constraint(1)
		
* Close the log file
log close


