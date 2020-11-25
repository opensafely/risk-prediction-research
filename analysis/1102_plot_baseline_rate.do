********************************************************************************
*
*	Do-file:			1102_plot_baseline_rate.do
*
*	Written by:			Fizz & John
*
*	Data used:			data/
*							cr_base_cohort.dta
*							foi_coefs.dta
*							ae_coefs.dta
*							susp_coefs.dta
*
*	Data created:		None
*
*	Other output:		Graphs on screen

********************************************************************************
*
*	Purpose:			This do-file graphs the estimated baseline rate using
*						the three different time-varying measures of infection
*						burden: force of infection, A&E attendances and GP
*						suspected cases. 
*
********************************************************************************





*******************************
*  Create landmark datasets   *
*******************************


* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"


	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace


/* Complete case for ethnicity  */ 

drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.



/* Just keep required variables  */ 

keep patient_id died_date_onscovid died_date_onsother onscoviddeath ///
	age stp_combined region_7
noi count
noi tab onscoviddeath

save "cohort_temp", replace


* Create separate landmark substudies (with only age, region and STP)
forvalues i = 1 (1) 73 {

	use "cohort_temp", clear

	* Date landmark substudy i starts
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'

	
	/*  Event indicator for the 28 day period  */
	
	* Date this landmark started: d(1/03/2020) + `i' - 1
	* Days until death:  died_date_onscovid - {d(1/03/2020) + `i' - 1} + 1
	
	* Survival time (must be between 1 and 28)
	qui gen stime28 = (died_date_onscovid - (d(1/03/2020) + `i' - 1) + 1) ///
			if died_date_onscovid < .
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 & stime28>28
	qui drop stime28 died_date_*
	
	
	
	/* Collapse by age, sex, STP and region  */
	
	recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 	///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)
	drop age
	
	collapse (count) patient_id, by(agegroupfoi region_7 ///
								stp_combined onscoviddeath)

								
	
	/* Tidy and save dataset  */
	
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
	qui save time_`i', replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use time_1.dta, clear
forvalues i = 2 (1) 73 {
	qui append using time_`i'
}

* Delete unneeded datasets
forvalues i = 1 (1) 73 {
	qui erase time_`i'.dta
}

erase "cohort_temp.dta"





*******************
*  Collapse data  *
*******************

collapse (sum) patient_id, 			///
	by(agegroupfoi region_7 		///
	stp_combined onscoviddeath time)

rename patient_id fweight



****************************************
*  Add in time-varying infection data  *
****************************************


* Merge in the force of infection data
merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
	assert(match using) keep(match) nogen 
drop foi_c_cons foi_c_day foi_c_daysq foi_c_daycu


* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen
drop ae_c_cons ae_c_day ae_c_daysq ae_c_daycu


* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen
drop susp_c_cons susp_c_day susp_c_daysq susp_c_daycu






******************************************
*  Create time-varying variables needed  *
******************************************


/*  FOI  */

* Create time variables to be fed into the variable selection process
gen logfoi		= log(foi)
gen foiqd		= foi_q_day/foi_q_cons
gen foiqds		= foi_q_daysq/foi_q_cons
gen foiqint		= foiqd*foiqds
gen foiqd2		= foiqd^2
gen foiqds2		= foiqds^2


* Create lagged measures of FOI
bysort agegroupfoi region_7 (time): gen foilag7 = foi[_n-7]
replace foilag7 = 0 if foilag7>=.

bysort agegroupfoi region_7 (time): gen foilag10= foi[_n-10]
replace foilag10 = 0 if foilag10>=.

bysort agegroupfoi region_7 (time): gen foilag12 = foi[_n-12]
replace foilag12 = 0 if foilag12>=.

* Take logged lagged measures
qui summ foi if foi>0
gen logfoilag7  = log(max(foilag7, r(min)/2))
gen logfoilag10 = log(max(foilag10, r(min)/2))
gen logfoilag12 = log(max(foilag12, r(min)/2))





/*  A&E attendances  */

gen aepos = aerate
qui summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

* Create time variables to be fed into the variable selection process
gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons

replace aeqd  = 0 if ae_q_cons==0
replace aeqds = 0 if ae_q_cons==0

gen aeqint 		= aeqd*aeqds
gen aeqd2		= aeqd^2
gen aeqds2		= aeqds^2




/*  GP suspected cases  */


gen susppos = susp_rate
qui summ susp_rate if susp_rate>0 
replace susppos = susppos + r(min)/2 if susppos==0

* Create time variables to be fed into the variable selection process
gen logsusp	 	= log(susppos)
gen suspqd	 	= susp_q_day/susp_q_cons
gen suspqds 	= susp_q_daysq/susp_q_cons

replace suspqd  = 0 if susp_q_cons==0
replace suspqds = 0 if susp_q_cons==0

gen suspqint   	= suspqd*suspqds
gen suspqd2 	= suspqd^2
gen suspqds2	= suspqds^2




*save funcform_temp, replace





**********************************
*  Draw graphs of baseline rate  *
**********************************



*use funcform_temp, clear

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
		




