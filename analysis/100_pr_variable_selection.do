********************************************************************************
*
*	Do-file:			100_pr_variable_selection.do
*
*	Written by:			Fizz & John
*
*	Data used:			data/cr_base_cohort.dta
*
*	Data created:		Selected variables (Stata dataset): 
*							data/cr_selected_model_coefficients.dta
*
*	Other output:		Log file:  100_pr_variable_selection.log
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple Poisson lasso model on a 
*						random sample of the whole cohort to perform 
*						variable selection.
*
*	Note:				Stata do-file called:
*							analysis/0000_cr_define_covariates.do
*
********************************************************************************




* Open a log file
cap log close
log using "output/100_pr_variable_selection", replace t


* Load do-file which extracts covariates 
do "analysis/0000_cr_define_covariates.do"




	

*************************************************
*  Select 4% random sample from cohort dataset  *
*************************************************

	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace

* Take random sample
noi count
noi tab onscoviddeath
set seed 724891
sample 0.04
noi count
noi tab onscoviddeath

	
/* Complete case for ethnicity   */ 

drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.
noi tab onscoviddeath



/*  Extract relevant covariates  */

* Define covariates as of the start date of the validation period
local start = d(01/03/2020)
define_covs, dateno(`start')



	

***********************************************
*  Outcome and offset for variable selection  *
***********************************************
	
* Create outcome for Poisson (variable selection) model and exposure variable
stset stime, fail(onscoviddeath) id(patient_id)  
gen diedcovforpoisson  = _d
gen exposureforpoisson = _t-_t0
gen offset = log(exposureforpoisson) 




************************
*  Variable Selection  *
************************


timer clear 1
timer on 1
lasso poisson diedcovforpoisson 									///
			(c.agec i.male)											///
			i.rural i.imd i.ethnicity_8 							///
			i.obesecat i.smoke_nomiss i.bpcat_nomiss 				///
			i.hypertension i.diabcat i.cardiac 						///
			i.af i.dvt_pe i.pad 									///
			i.stroke i.dementia i.neuro 							///
			i.asthmacat i.cf i.respiratory							///
			i.cancerExhaem i.cancerHaem 							///
			i.liver i.dialysis i.transplant i.kidneyfn 				///
			i.autoimmune i.spleen i.suppression i.hiv i.ibd			///
			i.ld i.smi i.fracture 									///
			i.hh_children c.hh_numc c.hh_num2 c.hh_num3				///
			c.age2 c.age3 											///
			c.agec#i.male	 										///
			c.agec#(i.rural i.imd i.ethnicity_8 					///
				i.obesecat i.smoke_nomiss i.bpcat_nomiss 			///
				i.hypertension i.diabcat i.cardiac 					///
				i.af i.dvt_pe i.pad 								///
				i.stroke i.dementia i.neuro 						///
				i.asthmacat i.cf i.respiratory						///
				i.cancerExhaem i.cancerHaem 						///
				i.liver i.dialysis i.transplant i.kidneyfn 			///
				i.autoimmune i.spleen i.suppression i.hiv i.ibd		///
				i.ld i.smi i.fracture 								///
				i.hh_children)										///
			i.male#(i.rural i.imd i.ethnicity_8 					///
				i.obesecat i.smoke_nomiss i.bpcat_nomiss 			///
				i.hypertension i.diabcat i.cardiac 					///
				i.af i.dvt_pe i.pad 								///
				i.stroke i.dementia i.neuro 						///
				i.asthmacat i.cf i.respiratory						///
				i.cancerExhaem i.cancerHaem 						///
				i.liver i.dialysis i.transplant i.kidneyfn 			///
				i.autoimmune i.spleen i.suppression i.hiv i.ibd		///
				i.ld i.smi i.fracture 								///
				i.hh_children)										///
			 , offset(offset) rseed(7248) grid(20) folds(3)
timer off 1
timer list 1





*****************************
*  Save selected variables  *
*****************************


/*  Save coefficients of post-lasso   */

lassocoef, display(coef, postselection eform)
matrix define A = r(coef)

* Selected coefficients
local  SelectedVars = e(allvars_sel)
noi di "`SelectedVars'"


* Save coefficients of post-lasso 
tempname coefs
postfile `coefs' str30(variable) coef using 	///
	"data\cr_selected_model_coefficients.dta", replace

local i = 1

foreach v of local SelectedVars {
	
	local coef = A[`i',1]

	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'




* Close the log file
log close


		

