********************************************************************************
*
*	Do-file:			Multimorbidity_variable_selection.do
*
*	Written by:			Fizz
*
*	Data used:			cr_create_analysis_dataset.dta
*						cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:		None
*
*	Other output:		output/Multimorbidity_variable_selection
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
log using "output/Multimorbidity_variable_selection", text replace


******************************************
*  Select random sample for exploration  *
******************************************

use "cr_create_analysis_dataset.dta", clear

* Set seed for reproducibility
set seed 8842

* Upweight non-white ethnicities (by x5)
recode ethnicity 1=5 2/max=1, gen(f)
replace f = 1 if onscoviddeath==1
expand f

* Keep cases and randomly sample controls (with upweighting)
sample 15000, by(onscoviddeath) count

* Remove any people selected twice (due to quick and dirty upweighting above)
duplicates drop



***********************************************
*  Recode variables for consistent baselines  *
***********************************************

* Binary variables
for var male htdiag_or_highbp chronic_respiratory_disease 	///	
		chronic_cardiac_disease chronic_liver_disease 		///
		stroke_dementia other_neuro organ_transplant spleen ///
		ra_sle_psoriasis other_immunosuppression: replace X = X+1

* Agegroup
* Make agegroup 3 (50-70) the "baseline", i.e. value 1
* Change other value codes for presentation purposes
recode agegroup 1=18 2=40 3=1 4=60 5=70 6=80
label values agegroup



***********************************
*  Force main effects into model  *
***********************************

* Lambda selected via cross-validation
timer clear 1
timer on 1
lasso logit onscoviddeath (i.(agegroup 								///
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
							other_immunosuppression))				///
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
							other_immunosuppression)##i.(agegroup 	///
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
							other_immunosuppression)
*, selection(plugin) - ADD IF SLOW
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1

			

			

*********************
*  Poisson version  *
*********************

		
use "cr_create_analysis_dataset_STSET_onscoviddeath.dta", clear

set seed 123478	
keep if _d==1| uniform()<0.003
stsplit timeband, at(30 60)

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
							, exp(exposureforpoisson)
*, selection(plugin) - ADD IF SLOW
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1		   

						

*********************************
*  Not forcing main effects in  *
*********************************
						
			
/*
						
						
* All pairwise interactions (full model with cross-validation, 50 times slower)
timer clear 1
timer on 1
lasso logit onscoviddeath i.(agegroup 								///
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
							other_immunosuppression)##i.(agegroup 	///
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
							other_immunosuppression) 			
lassocoef, display(coef, postselection)
timer off 1
timer list 1


*/


* Close the log file
log close

