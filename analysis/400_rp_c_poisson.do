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





***************************
*  Create daily datasets  *
***************************

use "data/cr_daily_landmark_covid.dta", clear

		
* Fit model	
daypois onscoviddeath										///
		male i.agegroup respiratory							///
		i.asthmacat cardiac i.diabcat 						///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, 												///
		timeadj("None")										///
		timevar(foi_q_cons foi_q_day foi_q_daysq) 			///
		weight(sf_wts)  

/* To mimic std poisson add a const:

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
		
poisson onscoviddeath										///
		male i.agegroup respiratory							///
		i.asthmacat cardiac i.diabcat 						///
		stroke dementia neuro								///
		transplant spleen autoimmune						///
		hiv, robust 

*/


* Fit model	
daypois covid male i.agegroup chronic_respiratory_disease	///
		asthma chronic_cardiac_disease diabetes 			///
		hypertension stroke_dementia other_neuro			///
		organ_transplant spleen ra_sle_psoriasis			///
		other_immunosuppression, 							///
		timeadj("Quadratic")								///
		timevar(foi_q_cons foi_q_day foi_q_daysq) 			///
		weight(sf_wts)  
	

	
* Today's infection
daypois covid male i.agegroup chronic_respiratory_disease	///
		asthma chronic_cardiac_disease diabetes 			///
		hypertension stroke_dementia other_neuro			///
		organ_transplant spleen ra_sle_psoriasis			///
		other_immunosuppression, 							///
		timeadj("Other")								///
		timevar(foi_q_cons) 			///
		weight(sf_wts)  
	
gen logfoi = log(foi_q_cons)

daypois covid male i.agegroup chronic_respiratory_disease	///
		asthma chronic_cardiac_disease diabetes 			///
		hypertension stroke_dementia other_neuro			///
		organ_transplant spleen ra_sle_psoriasis			///
		other_immunosuppression, 							///
		timeadj("Other")								///
		timevar(logfoi) 			///
		weight(sf_wts)  

* Close the log file
log close


