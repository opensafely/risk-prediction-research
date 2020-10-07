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
*	Other output:		Log file:  output/102_pr_infection_funcform_landmark
*
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
*						cohort design.
*
********************************************************************************




* Open a log file
capture log close
log using "output/102_pr_infection_funcform_landmark", text replace


	
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






**********************
*  Fit models:  FOI  *
**********************

/*  FOI  */

* FOI
poisson onscoviddeath foi [pweight=sf_wts]
estat ic

* Quadratic model
poisson onscoviddeath c.foi##c.foi [pweight=sf_wts]
estat ic

* Cubic model
poisson onscoviddeath c.foi##c.foi##c.foi [pweight=sf_wts]
estat ic

* Quartic model
poisson onscoviddeath c.foi##c.foi##c.foi##c.foi [pweight=sf_wts]
estat ic



/* Log FOI */

poisson onscoviddeath logfoi [pweight=sf_wts]
estat ic


/*  FPs  */

fp <foi>, replace: poisson onscoviddeath <foi> [pweight=sf_wts]

gen poslogfoi = -logfoi
assert poslogfoi>0

fp <poslogfoi>, replace: poisson onscoviddeath <poslogfoi> [pweight=sf_wts]



/* Log FOI with coefficients  */

poisson onscoviddeath logfoi foiqd [pweight=sf_wts]
estat ic

poisson onscoviddeath logfoi foiqds [pweight=sf_wts]
estat ic

poisson onscoviddeath logfoi foiqd foiqds foiqint [pweight=sf_wts]
estat ic

poisson onscoviddeath logfoi foiqd foiqds foiqd2 [pweight=sf_wts]
estat ic

poisson onscoviddeath logfoi foiqd foiqds foiqds2 [pweight=sf_wts]
estat ic

poisson onscoviddeath logfoi foiqd foiqds foiqint foiqd2 foiqds2 [pweight=sf_wts]
estat ic






**********************************
*  Fit models:  A&E attendances  *
**********************************


/*  A&E  */

* A&E
poisson onscoviddeath aepos [pweight=sf_wts]
estat ic

* Quadratic model
poisson onscoviddeath c.aepos##c.aepos [pweight=sf_wts]
estat ic

* Cubic model
poisson onscoviddeath c.aepos##c.aepos##c.aepos [pweight=sf_wts]
estat ic

* Quartic model
poisson onscoviddeath c.aepos##c.aepos##c.aepos##c.aepos [pweight=sf_wts]
estat ic


/* Log A&E */

poisson onscoviddeath logae [pweight=sf_wts]
estat ic



/*  FPs  */


fp <aepos>, replace: poisson onscoviddeath <aepos> [pweight=sf_wts]

qui summ logae
gen poslogae = -logae + r(max)
qui summ poslogae if poslogae>0
replace poslogae = poslogae + r(min)/2
assert poslogae>0


fp <poslogae>, replace: poisson onscoviddeath <poslogae> [pweight=sf_wts]



/* Log A&E with coefficients  */

poisson onscoviddeath logae aeqd [pweight=sf_wts]
estat ic

poisson onscoviddeath logae aeqds [pweight=sf_wts]
estat ic

poisson onscoviddeath logae aeqd aeqds aeqint [pweight=sf_wts]
estat ic

poisson onscoviddeath logae aeqd aeqds aeqd2 [pweight=sf_wts]
estat ic

poisson onscoviddeath logae aeqd aeqds aeqds2 [pweight=sf_wts]
estat ic

poisson onscoviddeath logae aeqd aeqds aeqint aeqd2 aeqds2 [pweight=sf_wts]
estat ic




*************************************
*  Fit models:  GP suspected cases  *
*************************************


/*  GP  */

* GP
poisson onscoviddeath susppos [pweight=sf_wts]
estat ic

* Quadratic model
poisson onscoviddeath c.susppos##c.susppos [pweight=sf_wts]
estat ic

* Cubic model
poisson onscoviddeath c.susppos##c.susppos##c.susppos [pweight=sf_wts]
estat ic

* Quartic model
poisson onscoviddeath c.susppos##c.susppos##c.susppos##c.susppos [pweight=sf_wts]
estat ic


/* Log A&E */

poisson onscoviddeath logsusp [pweight=sf_wts]
estat ic



/*  FPs  */


fp <susppos>, replace: poisson onscoviddeath <susppos> [pweight=sf_wts]

qui summ logsusp
gen poslogsusp = -logsusp + r(max)
qui summ poslogsusp if poslogsusp>0
replace poslogsusp = poslogsusp + r(min)/2
assert poslogsusp>0

fp <poslogsusp>, replace: poisson onscoviddeath <poslogsusp> [pweight=sf_wts]



/* Log A&E with coefficients  */

poisson onscoviddeath logsusp suspqd [pweight=sf_wts]
estat ic

poisson onscoviddeath logsusp suspqds [pweight=sf_wts]
estat ic

poisson onscoviddeath logsusp suspqd suspqds suspqint [pweight=sf_wts]
estat ic

poisson onscoviddeath logsusp suspqd suspqds suspqd2 [pweight=sf_wts]
estat ic

poisson onscoviddeath logsusp suspqd suspqds suspqds2 [pweight=sf_wts]
estat ic

poisson onscoviddeath logsusp suspqd suspqds suspqint suspqd2 suspqds2 [pweight=sf_wts]
estat ic




*********************
*  Lasso selection  *
*********************


gen offset = log(28) + log(sf_wts/200)



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
				, offset(offset) rseed(12378) grid(20) folds(3) 
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
postfile `coefs' str30(variable) coef using "data\cr_selected_foi.dta", replace

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
				, offset(offset) rseed(12378) grid(30) folds(3) 
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
postfile `coefs' str30(variable) coef using "data\cr_selected_ae.dta", replace

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
				, offset(offset) rseed(12378) grid(30) folds(3) 
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
postfile `coefs' str30(variable) coef using "data\cr_selected_susp.dta", replace

local i = 1

foreach v of local selectedtimevars {
	local coef = A[`i',1]
	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'




* Close the log file
log close

