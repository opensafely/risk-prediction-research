********************************************************************************
*
*	Do-file:			103_pr_variable_selection_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			data/cr_base_cohort.dta
*
*	Data created:		Selected variables (Stata dataset): 
*							data/cr_selected_model_coefficients_landmark.dta
*
*	Other output:		Log file:  103_pr_variable_selection_landmark.log
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple logistic lasso model on a  
*						random sample of data taken at three times across the 
*						study period, for the purposes of variable selection. 
*
*	NOTES:				Stata do-file called:
*							analysis/0000_cr_define_covariates.do
*
********************************************************************************




/******   IMPORTANT NOTE   ******/

* Put in chosen functional form for timevarying variable
* Check the correct variables forced in below

/******   END IMPORTANT NOTE   ******/


global tvc = "logfoi foiqd foiqds" 
* global tvc = "??? for A&E"
* global tvc = "??? for GP susp cases"





* Open a log file
cap log close
log using "output/103_pr_variable_selection_landmark_TEMP", replace t


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

collapse (count) patient_id, 		///
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



/*  A&E attendances  */

gen aepos = aerate
qui summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

* Create time variables to be fed into the variable selection process
gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons
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
gen suspqint   	= suspqd*suspqds
gen suspqd2 	= suspqd^2
gen suspqds2	= suspqds^2





			


************************
*  Variable Selection  *
************************


/*  Lasso for FOI  */

timer clear 1
timer on 1
lasso poisson onscoviddeath foi					///
							logfoi				///	
							foiqd				///
							foi_q_day			///
							foi_q_daysq			///
							foiqds				///
							foiqint				///
							foiqd2				///
							foiqds2				///
						[fweight=fweight]		///
				,  rseed(12378) grid(20) folds(3) ///
				selection(plugin)
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
lasso poisson onscoviddeath aerate				///
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
				selection(plugin)
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
lasso poisson onscoviddeath susp_rate			///
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
				selection(plugin)
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


		

