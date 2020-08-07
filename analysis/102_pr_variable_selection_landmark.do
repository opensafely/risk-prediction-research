********************************************************************************
*
*	Do-file:			102_pr_variable_selection_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		None
*
*	Other output:		output/102_pr_variable_selection_landmark
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
log using "output/102_pr_variable_selection_landmark", text replace



*********************************************************************************
*  UPDATE  
*    Unstar a few lines below adding: DVT_PE, LD, HHNUM*
*
*   THEN DELETE THIS BOX!!!
*********************************************************************************



***********************************
*  Candidate predictor variables  *
***********************************


/*  List to be forced in  */

global pred_cts_f 	  	= "age1 "
global pred_cts_f_noi 	= "tvar1"
global pred_bin_f		= "male"
global pred_cat_f 		= " "



/*  List to be additionally considered  */

*** TO BE UPDATED: NEXT 5 ROWS
*global pred_cts_c 		= "hh_num1"
*global pred_cts_c_noi 	= "hh_num2 hh_num3"

global pred_cts_c 		= " "
global pred_cts_c_noi 	= "age2 age3 tvar2 tvar3 tvar4 tvar5 tvar6"


*** TO BE UPDATED: NEXT 5 ROWS
*global pred_bin_c = "rural hh_children respiratory cf cardiac hypertension af pvd dvt_pe stroke dementia neuro liver transplant dialysis spleen autoimmune hiv suppression ibd smi ld fracture"

global pred_bin_c = "rural hh_children respiratory cf cardiac hypertension af pvd stroke dementia neuro liver transplant dialysis spleen autoimmune hiv suppression ibd smi fracture"


global pred_cat_c = "ethnicity_8 imd obesecat smoke_nomiss bpcat_nomiss asthma diabcat cancerExhaem cancerHaem kidneyfn"
global pred_cat_c_noi 	= "region_9"






************************
*  Variable Selection  *
************************


*  Open data to be used for variable selection 
use "data/cr_landmark.dta", clear

gen tvar1 = log(foi_q_cons)
gen tvar2 = foi_q_day/foi_q_cons
gen tvar3 = foi_q_daysq/foi_q_cons
gen tvar4 = tvar2*tvar3
gen tvar5 = tvar2^2
gen tvar6 = tvar3^2




***************************************************************** 
* Stage 1: 														*
* Selection of non-forced predictors and pairwise interactions  *
* (Performed during pre-shielding period) 						*
*****************************************************************

* Outcome and offset for Poisson regression
gen diedcovforpoisson = onscoviddeath
gen offset = log(dayout - dayin)
*+ log(sf_wts)


timer clear 1
timer on 1
lasso poisson diedcovforpoisson 									///
			(c.(${pred_cts_f}) i.(${pred_bin_f}) i.(${pred_cat_f}) 	///
			c.(${pred_cts_f_noi}))									///
																	///
			c.(${pred_cts_c}) i.(${pred_bin_c}) i.(${pred_cat_c})	///
			c.(${pred_cts_c_noi}) i.(${pred_cat_c_noi})				///
																	///
			c.(${pred_cts_f})##c.(${pred_cts_f})					///
			i.(${pred_bin_f})##c.(${pred_cts_f})					///
			i.(${pred_cat_f})##c.(${pred_cts_f})					///
			i.(${pred_bin_f})##c.(${pred_cat_f})					///
																	///
			c.(${pred_cts_f})##c.(${pred_cts_c})					///
			c.(${pred_cts_f})##i.(${pred_bin_c})					///
			c.(${pred_cts_f})##i.(${pred_cat_c})					///
			i.(${pred_bin_f})##c.(${pred_cts_c})					///
			i.(${pred_bin_f})##i.(${pred_bin_c})					///
			i.(${pred_bin_f})##i.(${pred_cat_c})					///
			i.(${pred_cat_f})##c.(${pred_cts_c})					///
			i.(${pred_cat_f})##i.(${pred_bin_c})					///
			i.(${pred_cat_f})##i.(${pred_cat_c})					///
																	///
			c.(${pred_cts_c})##c.(${pred_cts_c})					///
			i.(${pred_bin_c})##c.(${pred_cts_c})					///	
			i.(${pred_cat_c})##c.(${pred_cts_c})					///
			i.(${pred_bin_c})##i.(${pred_cat_c})					///
																	///
			if shield==0,											///
			offset(offset) selection(plugin) 
timer off 1
timer list 1



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





* Close the log file
log close

