********************************************************************************
*
*	Do-file:			102_pr_infection_funcform_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		data/
*							funcform_temp.dta
*
*
*	Other output:		Log file:  output/
*									102_pr_infection_funcform_landmark_ic
*								    102_pr_infection_funcform_landmark_lasso

********************************************************************************
*
*	Purpose:			This do-file graphs a number of models for COVID-19 
*						related death, without covariates, to select the 
*						functional form over time, using the FOI, A&E data and
*						the GP suspected case data. 
*
********************************************************************************



use funcform_temp, clear

* Crude
poisson onscoviddeath i.agegroupfoi i.time	///
	[fweight=fweight]
predict yhat_crude


* FOI
poisson onscoviddeath 	i.agegroupfoi logfoi 					///
						c.foi_q_day c.foi_q_daysq 				///
						foiqd foiqds							///
						[fweight=fweight]
predict yhat_foi


* A&E attendances
poisson onscoviddeath 	i.agegroupfoi 							///
						logae c.ae_q_day c.ae_q_daysq 			///
						aeqd aeqds aeqds2						///			
						[fweight=fweight]
predict yhat_ae

* Suspected cases
poisson onscoviddeath 	i.agegroupfoi 							///
						logsusp c.susp_q_day c.susp_q_daysq 	///
						suspqd suspqds suspqds2					///
						[fweight=fweight]
predict yhat_susp


		
keep if agegroupfoi==7 & region==2
keep onscoviddeath fweight yhat* time

expand fweight
gen rsample = uniform()<1/10000

summ yhat*

twoway 	(scatter yhat_crude time) 	///
		(scatter yhat_foi time) 	///
		(scatter yhat_ae time)	 	///
		(scatter yhat_susp time) 	///
		, legend(order(1 2 3 4) label(1 "Crude") label(2 "FOI") label(3 "AE") label(4 "Susp"))
		




