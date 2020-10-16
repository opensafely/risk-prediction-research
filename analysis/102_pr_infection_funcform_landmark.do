********************************************************************************
*
*	Do-file:			102_pr_infection_funcform_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		data/
*							cr_selected_foi.dta
*							cr_selected_ae.dta
*							cr_selected_susp.dta
*
*
*	Other output:		Log file:  output/
*									102_pr_infection_funcform_landmark_ic
*								    102_pr_infection_funcform_landmark_lasso

********************************************************************************
*
*	Purpose:			This do-file fits a number of models for COVID-19 
*						related death, without covariates, to select the 
*						functional form over time, using the FOI, A&E data and
*						the GP suspected case data. 
*
*						It also runs a simple lasso model on a sample of 
*						data (all cases, random sample of controls) to perform 
*						automatic variable selection.
*
*	Note:				This do-file uses Barlow weights (incorporated as an
*						offset in the Poisson model) to account for the case-
*						cohort design in the first half.
*
*						For the lasso, a cohort sample (frequency-weighted) is
*						taken. 
*
********************************************************************************




						*****************************
						*  COMARE MODELS USING AIC  *
						*****************************
						
						
* Open a log file
capture log close
log using "output/102_pr_infection_funcform_landmark_ic", text replace


	
*****************************************
*  Prepare data for variable selection  *
*****************************************

use "data/cr_landmark", clear


/*  FOI  */

* Create time variables to be fed into the variable selection process
gen logfoi		= log(foi)
gen foiqd		= foi_q_day/foi_q_cons
gen foiqds		= foi_q_daysq/foi_q_cons
gen foiqint		= foiqd*foiqds
gen foiqd2		= foiqd^2
gen foiqds2		= foiqds^2

recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)

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

drop agegroupfoi




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






**********************
*  Fit models:  FOI  *
**********************


/*  FOI  */

* FOI
poisson onscoviddeath agec foi [pweight=sf_wts]
estat ic

* Quadratic model
poisson onscoviddeath agec c.foi##c.foi [pweight=sf_wts]
estat ic

* Cubic model
poisson onscoviddeath agec c.foi##c.foi##c.foi [pweight=sf_wts]
estat ic

* Quartic model
poisson onscoviddeath agec c.foi##c.foi##c.foi##c.foi [pweight=sf_wts]
estat ic



/*  Lagged FOI  */


* 7 day lag
poisson onscoviddeath agec foilag7 [pweight=sf_wts]
estat ic

* 10 day lag
poisson onscoviddeath agec foilag10 [pweight=sf_wts]
estat ic

* 12 day lag
poisson onscoviddeath agec foilag12 [pweight=sf_wts]
estat ic



/* Log FOI */

poisson onscoviddeath agec logfoi [pweight=sf_wts]
estat ic




/*  Log Lagged FOI  */


* 7 day lag
poisson onscoviddeath agec logfoilag7 [pweight=sf_wts]
estat ic

* 10 day lag
poisson onscoviddeath agec logfoilag10 [pweight=sf_wts]
estat ic

* 12 day lag
poisson onscoviddeath agec logfoilag12 [pweight=sf_wts]
estat ic



/*  FPs  */

fp <foi>, replace: poisson onscoviddeath agec <foi> [pweight=sf_wts]

gen poslogfoi = -logfoi
assert poslogfoi>0

fp <poslogfoi>, replace: poisson onscoviddeath agec <poslogfoi> [pweight=sf_wts]



/* Log FOI with coefficients  */

poisson onscoviddeath agec logfoi foiqd [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logfoi foiqds [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logfoi foiqd foiqds foiqint [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logfoi foiqd foiqds foiqd2 [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logfoi foiqd foiqds foiqds2 [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logfoi foiqd foiqds foiqint foiqd2 foiqds2 [pweight=sf_wts]
estat ic






**********************************
*  Fit models:  A&E attendances  *
**********************************


/*  A&E  */

* A&E
poisson onscoviddeath agec aepos [pweight=sf_wts]
estat ic

* Quadratic model
poisson onscoviddeath agec c.aepos##c.aepos [pweight=sf_wts]
estat ic

* Cubic model
poisson onscoviddeath agec c.aepos##c.aepos##c.aepos [pweight=sf_wts]
estat ic

* Quartic model
poisson onscoviddeath agec c.aepos##c.aepos##c.aepos##c.aepos [pweight=sf_wts]
estat ic


/* Log A&E */

poisson onscoviddeath agec logae [pweight=sf_wts]
estat ic



/*  FPs  */


fp <aepos>, replace: poisson onscoviddeath agec <aepos> [pweight=sf_wts]

qui summ logae
gen poslogae = -logae + r(max)
qui summ poslogae if poslogae>0
replace poslogae = poslogae + r(min)/2
assert poslogae>0


fp <poslogae>, replace: poisson onscoviddeath agec <poslogae> [pweight=sf_wts]



/* Log A&E with coefficients  */

poisson onscoviddeath agec logae aeqd [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logae aeqds [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logae aeqd aeqds aeqint [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logae aeqd aeqds aeqd2 [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logae aeqd aeqds aeqds2 [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logae aeqd aeqds aeqint aeqd2 aeqds2 [pweight=sf_wts]
estat ic




*************************************
*  Fit models:  GP suspected cases  *
*************************************


/*  GP  */

* GP
poisson onscoviddeath agec susppos [pweight=sf_wts]
estat ic

* Quadratic model
poisson onscoviddeath agec c.susppos##c.susppos [pweight=sf_wts]
estat ic

* Cubic model
poisson onscoviddeath agec c.susppos##c.susppos##c.susppos [pweight=sf_wts]
estat ic

* Quartic model
poisson onscoviddeath agec c.susppos##c.susppos##c.susppos##c.susppos [pweight=sf_wts]
estat ic


/* Log A&E */

poisson onscoviddeath agec logsusp [pweight=sf_wts]
estat ic



/*  FPs  */


fp <susppos>, replace: poisson onscoviddeath agec <susppos> [pweight=sf_wts]

qui summ logsusp
gen poslogsusp = -logsusp + r(max)
qui summ poslogsusp if poslogsusp>0
replace poslogsusp = poslogsusp + r(min)/2
assert poslogsusp>0

fp <poslogsusp>, replace: poisson onscoviddeath agec <poslogsusp> [pweight=sf_wts]



/* Log A&E with coefficients  */

poisson onscoviddeath agec logsusp suspqd [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logsusp suspqds [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logsusp suspqd suspqds suspqint [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logsusp suspqd suspqds suspqd2 [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logsusp suspqd suspqds suspqds2 [pweight=sf_wts]
estat ic

poisson onscoviddeath agec logsusp suspqd suspqds suspqint suspqd2 suspqds2 [pweight=sf_wts]
estat ic



* Close the log file
log close




/*



						*********************
						*  LASSO SELECTION  *
						*********************


* Open a log file
capture log close
log using "output/102_pr_infection_funcform_landmark_lasso", text replace


* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"


	

*************************************************
*  Select 4% random sample from cohort dataset  *
*************************************************

	
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




save funcform_temp, replace

			


************************
*  Variable Selection  *
************************


/*  Lasso for FOI  */

timer clear 1
timer on 1
lasso poisson onscoviddeath (i.agegroupfoi) 	///
							foi					///
							logfoi				///	
							foiqd				///
							foi_q_day			///
							foi_q_daysq			///
							foiqds				///
							foiqint				///
							foiqd2				///
							foiqds2				///
							foilag7				///
							logfoilag7			///
							foilag10			///
							logfoilag10			///
							foilag12			///
							logfoilag12			///
						[fweight=fweight]		///
				,  rseed(12378) grid(20) folds(3) ///
				selection(plugin) serule
timer off 1
timer list 1




* Matrix of coefs from selected model 
lassocoef, display(coef, postselection eform)
mat defin A = r(coef)

* Selected covariates						
local selectedtimevars = e(allvars_sel)
noi di "`selectedtimevars'"



* Save coefficients of post-lasso 
tempname coefs
postfile `coefs' str30(variable) coef using "data\cr_selected_foi_cohort.dta", replace

local i = 1

foreach v of local selectedtimevars {
	local coef = A[`i',1]
	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'





/*  Lasso for A&E  */

timer clear 1
timer on 1
lasso poisson onscoviddeath (i.agegroupfoi) 	///
							aerate				///
							logae				///	
							aeqd				///
							ae_q_day			///
							ae_q_daysq			///
							aeqds				///
							aeqint				///
							aeqd2				///
							aeqds2				///
						[fweight=fweight]		///
				,  rseed(12378) grid(20) folds(3) ///
				selection(plugin) serule
timer off 1
timer list 1


* Matrix of coefs from selected model 
lassocoef, display(coef, postselection eform)
mat defin A = r(coef)

* Selected covariates						
local selectedtimevars = e(allvars_sel)
noi di "`selectedtimevars'"



* Save coefficients of post-lasso 
tempname coefs
postfile `coefs' str30(variable) coef using "data\cr_selected_ae_cohort.dta", replace

local i = 1

foreach v of local selectedtimevars {
	local coef = A[`i',1]
	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'





/*  Lasso for GP  */

timer clear 1
timer on 1
lasso poisson onscoviddeath (i.agegroupfoi) 	///
							susp_rate			///
							logsusp				///	
							suspqd				///
							susp_q_day			///
							susp_q_daysq		///
							suspqds				///
							suspqint			///
							suspqd2				///
							suspqds2			///
						[fweight=fweight]		///
				,  rseed(12378) grid(20) folds(3) ///
				selection(plugin) serule
timer off 1
timer list 1


* Matrix of coefs from selected model 
lassocoef, display(coef, postselection eform)
mat defin A = r(coef)

* Selected covariates						
local selectedtimevars = e(allvars_sel)
noi di "`selectedtimevars'"



* Save coefficients of post-lasso 
tempname coefs
postfile `coefs' str30(variable) coef using "data\cr_selected_susp_cohort.dta", replace

local i = 1

foreach v of local selectedtimevars {
	local coef = A[`i',1]
	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'




* Close the log file
log close


*/


