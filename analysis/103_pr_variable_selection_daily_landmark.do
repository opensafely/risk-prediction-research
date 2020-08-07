********************************************************************************
*
*	Do-file:			103_pr_variable_selection_daily_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*						cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:		None
*
*	Other output:		output/102_pr_variable_selection_daily_landmark
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
log using "output/102_pr_variable_selection_daily_landmark", text replace



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

global pred_cts_f 	 = "age1 "
global pred_cts_fnoi = "age2 age3 tvar1"

global pred_bin_f = "male"

global pred_cat_f = " "



/*  List to be additionally considered  */

*** TO BE UPDATED: NEXT 5 ROWS
*global pred_cts_c 		= "hh_num1"
*global pred_cts_c_noi 	= "hh_num2 hh_num3"

global pred_cts_c 		= " "
global pred_cts_c_noi 	= "tvar2 tvar3 tvar4 tvar5 tvar6"


*** TO BE UPDATED: NEXT 5 ROWS
*global pred_bin_c = "rural hh_children respiratory cf cardiac hypertension af pvd dvt_pe stroke dementia neuro liver transplant dialysis spleen autoimmune hiv suppression ibd smi ld fracture"

global pred_bin_c = "rural hh_children respiratory cf cardiac hypertension af pvd stroke dementia neuro liver transplant dialysis spleen autoimmune hiv suppression ibd smi fracture"
global pred_bin_c_noi 	= " "


global pred_cat_c = "ethnicity_8 imd obesecat smoke_nomiss bpcat_nomiss asthma diabcat cancerExhaem cancerHaem kidneyfn"
global pred_cat_c_noi 	= "region_9"






************************
*  Variable Selection  *
************************


*  Open data to be used for variable selection 
use "data/cr_daily_landmark_covid.dta", clear

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
gen offset = 0
*+ log(sf_wts)


timer clear 1
timer on 1
lasso poisson diedcovforpoisson 									///
			(c.(${pred_cts_f}) i.(${pred_bin_f}) i.(${pred_cat_f}) 	///
			c.(${pred_cts_f_noi}))									///
																	///
			c.(${pred_cts_c}) i.(${pred_bin_c}) i.(${pred_cat_c})	///
			c.(${pred_cts_c_noi}) i.(${pred_bin_c_noi})				///
			i.(${pred_cat_c_noi})									///
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
postfile `coefs' str30(variable) coef using "data\cr_selected_model_coefficients_daily_landmark.dta", replace

local i = 1

foreach v of local preShieldSelectedVars {
	
	local coef = A[`i',1]
	

	post `coefs' ("`v'") (`coef')
    local ++i
}

postclose `coefs'



* Close the log file
log close

