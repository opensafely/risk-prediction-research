********************************************************************************
*
*	Do-file:			102_pr_infection_funcform_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		None
*
*	Other output:		Log file:  output/102_pr_infection_funcform_landmark
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple lasso model on a sample of 
*						data (all cases, random sample of controls) to variable
*						select from all possible pairwise interactions.
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



* Create time variables to be fed into the variable selection process
gen logfoi	 = log(foi)
gen foiqd	= foi_q_day/foi_q_cons
gen foiqds 	= foi_q_daysq/foi_q_cons
gen foiqint = foiqd*foiqds
gen foiqd2 	= foiqd^2
gen foiqds2	= foiqds^2


gen offset = log(sf_wts/200)


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
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1


/*




* Log FOI
logistic onscoviddeath tvar1 [pweight=sf_wts]
estat ic

* Log FOI
logistic onscoviddeath tvar1 [pweight=sf_wts]
estat ic


foi
logfoi	
foiqd
foi_q_day
foi_q_daysq
foiqds
foiqint
foiqd2
foiqds2






/*  Extract a list of the variables appearing in the final model  */

global outcomevar = "diedcovforpoisson"
global selvars  = "`e(post_sel_vars)'"
global selterms = "`e(allvars_sel)'"
 
* Remove outcome from list of variables involved in selected model
global selvars:  list global(selvars) - global(outcomevar)

* Remove things that are not to be interacted with
global selvars : list global(selvars) - global(pred_cts_f_noi)
global selvars : list global(selvars) - global(pred_cts_c_noi)
global selvars : list global(selvars) - global(pred_cat_c_noi)

* Extract the continous terms
global cts1 : list global(selvars) & global(pred_cts_f)
global cts2 : list global(selvars) & global(pred_cts_c)
global cts  : list global(cts1) | global(cts2)

global bin_cat: list global(selvars) - global(cts)



* Matrix of coefs from selected model 
lassocoef, display(coef, postselection eform)
mat defin A = r(coef)

* Selected covariates						
local preShieldSelectedVars = e(allvars_sel)
noi di "`preShieldSelectedVars'"



* Save coefficients of post-lasso 
tempname coefs
postfile `coefs' str30(variable) coef using "data\cr_selected_model_coefficients.dta", replace

local i = 1

foreach v of local preShieldSelectedVars {
	
	local coef = A[`i',1]
	

	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'







***************************************************************** 
* Stage 2: 														*
* Selection of interactions with shielding 					    *
* (Performed 1st March until 10th May, with time split 			*
*  at the 1st April) 											*
*****************************************************************


timer clear 1
timer on 1
lasso poisson diedcovforpoisson ($selterms)						///
								i.shield 						///
								i.shield##c.(${cts})			///
								i.shield##i.(${bin_cat})		///
								, offset(offset) selection(plugin) 
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1


* Matrix of coefs from selected model 
mat defin B = r(coef)

* Selected covariates						
local postShieldSelectedVars = e(allvars_sel)
noi di "`postShieldSelectedVars'"

* Create postfile
tempname coefs
postfile `coefs' str30(variable) coef using "output\cr_selected_model_coefficients_landmark.dta", replace

local i = 1

foreach v of local postShieldSelectedVars {
	
	local coef = A[`i',1]
	
	post `coefs' ("`v'") (`coef')
    local ++i
}

postclose `coefs'

***! 
*  No predictors will be removed from the first-stage model - needs to be checked
* Final model 'Selected' predictor set





*/


* Close the log file
log close

