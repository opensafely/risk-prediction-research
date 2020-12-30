********************************************************************************
*
*	Do-file:		903_rp_a_coxPH_all2.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_coxPH_all2.dta
*
*	Other output:	Log file:  	output/903_rp_a_coxPH_all2.log
*					Estimates:	output/models/coefs_a_cox_all2.ster
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model with all potential covariates (i.e. not using any 
*					form of variable selection).
*
********************************************************************************


* Open a log file
capture log close
log using "./output/903_rp_a_coxPH_all2", text replace




************************************
*  Open dataset for model fitting  *
************************************

use "data/cr_casecohort_models.dta", replace


	


*******************
*   CoxPH Model   *
*******************
		
capture erase output/models/coefs_a_cox_all2.ster

timer clear 1
timer on 1
stcox 		c.agec i.male											///
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
				, vce(robust)
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_a_cox_all2, replace




***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
predict basesurv, basesurv
summ basesurv if _t <= 28 
global base_surv28 = r(min) // baseline survival decreases over time

summ basesurv if _t <= 100 
global base_surv100 = r(min) 

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv28 , $base_surv100 , b]
local names: colfullnames b
local names: subinstr local names "c1" "base_surv28"
local names: subinstr local names "c2" "base_surv100"
mat colnames b = `names'

*  Save coefficients to Stata dataset  
qui do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("")  ///
	dataname("data/model_a_coxPH_all2")



log close

