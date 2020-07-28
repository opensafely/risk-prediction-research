********************************************************************************
*
*	Do-file:			100_pr_variable_selection.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*						cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:		None
*
*	Other output:		output/pr_variable_selection
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
log using "output/100_pr_variable_selection", text replace




***********************************
*  Candidate predictor variables  *
***********************************

***************************            UPDATE            **************************************
* Covariate list needs updating when we add covariates  
***************************            UPDATE            **************************************


/*  List to be forced in  */

global pred_cts_f = "age1 hh_num"

global pred_bin_f = "male"

global pred_cat_f = "region_9"




/*  List to be additionally considered  */


global pred_cts_c = " "

global pred_bin_c = "respiratory cardiac stroke dementia neuro dialysis liver transplant autoimmune hiv suppression hypertension spleen smi af pvd"

global pred_cat_c = "ethnicity_8 imd obese4cat smoke_nomiss bpcat_nomiss bpcat_nomiss asthma diabetes cancerExhaem cancerHaem kidneyfn"






*************************************************
*  Open data to be used for variable selection  *
*************************************************

use "data/cr_casecohort_var_select.dta", clear


* Standardise continous variables
foreach var of varlist hh_num {
	qui summ `var'
	qui replace `var' = (`var' - r(mean))/r(sd)
}


 


************************
*  Variable Selection  *
************************

***************************************************************** 
* Stage 1: 														*
* Selection of non-forced predictors and pairwise interactions  *
* (Performed during pre-shielding period) 						*
*****************************************************************


* Create binary shielding indicator
stset dayout, fail(onscoviddeath) enter(dayin) id(patient_id)  
stsplit shield, at(32)
recode shield 32=1
label define shield 0 "Pre-shielding" 1 "Shielding"
label values shield shield
label var shield "Binary shielding (period) indicator"
recode onscoviddeath .=0

* Create outcome for Poisson model and exposure variable
gen diedcovforpoisson  = _d
gen exposureforpoisson = _t-_t0
gen offset = log(exposureforpoisson) 
*+ log(sf_wts)

timer clear 1
timer on 1
lasso poisson diedcovforpoisson 									///
			(c.(${pred_cts_f}) i.(${pred_bin_f}) i.(${pred_cat_f}) 	///
			age2 age3)												///
																	///
			c.(${pred_cts_c}) i.(${pred_bin_c}) i.(${pred_cat_c})	///
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
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1


* Matrix of coefs from selected model 
mat defin A = r(coef)

* Selected covariates						
local preShieldSelectedVars = e(allvars_sel)
noi di "`preShieldSelectedVars'"


**** TIDY THIS UP ****

local preShieldSelectedVars2 = " " + "`preShieldSelectedVars'"
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " c", " c.c", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " a", " c.a", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " b", " c.b", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " d", " c.d", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " e", " c.e", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " f", " c.f", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " g", " c.g", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " h", " c.h", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " i", " c.i", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " j", " c.j", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " k", " c.k", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " l", " c.l", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " m", " c.m", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " n", " c.n", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " o", " c.o", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " p", " c.p", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " q", " c.q", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " r", " c.r", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " s", " c.s", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " t", " c.t", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " u", " c.u", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " v", " c.v", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " w", " c.w", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " x", " c.x", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " y", " c.y", .)
local preShieldSelectedVars2 = subinstr("`preShieldSelectedVars2'", " z", " c.z", .)


noi di "`preShieldSelectedVars'"
noi di "`preShieldSelectedVars2'"




* Create postfile
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
lasso poisson diedcovforpoisson (`preShieldSelectedVars2' )			///
						 (`preShieldSelectedVars2')##i.shield		///
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
postfile `coefs' str30(variable) coef using "output\cr_selected_model_coefficients.dta", replace

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











*use "data\cr_selected_model_coefficients.dta", replace 
	
	
	






* Close the log file
log close

