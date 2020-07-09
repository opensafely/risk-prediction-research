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

global pred_cts = "age1 age2 age3"

global pred_bin = "male respiratory cardiac hypertension stroke dementia neuro  dialysis liver transplant spleen autoimmune hiv suppression"

global pred_cat = "ethnicity_8 obese4cat smoke_nomiss diabetes bpcat_nomiss asthma cancerExhaem cancerHaem kidneyfn"





******************************************
*  Select random sample for exploration  *
******************************************

use "data/cr_casecohort_var_select.dta", clear


***********************************************
*  Recode variables for consistent baselines  *
***********************************************

* Binary variables
* Change other value codes for presentation purposes
for var male respiratory 	///	
		cardiac liver 		///
		stroke dementia neuro transplant spleen ///
		autoimmune suppression: replace X = X+1

* Agegroup
* Make agegroup 3 (50-70) the "baseline", i.e. value 1
recode agegroup 1=18 2=40 3=1 4=60 5=70 6=80
label values agegroup



************************
*  Variable Selection  *
************************

***************************************************************** 
* Stage 1: 														*
* Selection of non-forced predictors and pairwise interactions  *
* (Performed during pre-shielding period) 						*
*****************************************************************


* Create binary shielding indicator
stsplit shield, at(32)
recode shield 32=0
label define shield 0 "Pre-shielding" 1 "Shielding"
label values shiled shield
label var shield "Binary shielding (period) indicator"


* Create outcome for Poisson model and exposure variable
gen diedcovforpoisson  = _d
gen exposureforpoisson = _t-_t0
			

timer clear 1
timer on 1
lasso poisson diedcovforpoisson  (i.(agegroup 						///
							ethnicity 								///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression timeband))		///
							i.(agegroup 							///
							ethnicity 								///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression 				///
							timeband)##i.(agegroup 					///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression 				///
							timeband) 								///
							if shield==1,							///
							exp(exposureforpoisson) selection(plugin) 
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1		   


* Matrix of coefs from selected model 
mat defin A = r(coef)

* Selected covariates						
local preShieldSelectedVars = e(allvars_sel)

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

set seed 123478	
keep if _d==1| uniform()<0.003
stsplit timeband, at(30 60)

gen diedcovforpoisson  = _d
gen exposureforpoisson = _t-_t0
						

timer clear 1
timer on 1
lasso poisson diedcovforpoisson `preShieldSelectedVars'
						(i.(agegroup 						///
							ethnicity 								///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression timeband))		///
							i.(agegroup 							///
							ethnicity 								///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression 				///
							timeband)##i.(agegroup 					///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression 				///
							timeband) 								///
							, exp(exposureforpoisson) selection(plugin) 
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1		   


* Matrix of coefs from selected model 
mat defin B = r(coef)

* Selected covariates						
local postShieldSelectedVars = e(allvars_sel)

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

