
********************************************************************************
*
*	Do-file:			108_pr_collate_variable_selection_output.do
*
*	Written by:			Fizz & John
*
*	Data used:			data\
*							cr_selected_model_coefficients.dta
*							cr_selected_model_coefficients_`i'.dta
*							cr_selected_model_coefficients_time.dta
*							cr_selected_model_coefficients_landmark_foi.dta
*							cr_selected_model_coefficients_landmark_ae.dta
*							cr_selected_model_coefficients_landmark_susp.dta
*
*	Data created:		data\
*							cr_all_selected_models.dta
*	
*	Other output:		None
*
********************************************************************************
*
*	Purpose:			This do-file collates the predictors selected from each
*						lasso, to compare across approaches.
*
********************************************************************************




************************************************
*  Put list of selected coefficients together  *
************************************************

* Overall approach A
use "data/cr_selected_model_coefficients.dta", clear
gen select = 1
gen poscoef = (coef>0)
drop coef

* Internal-external
forvalues i = 1 (1) 8 {
    if `i'<8 {
		merge 1:1 variable using "data/cr_selected_model_coefficients_`i'.dta"
	}
	if `i'==8 {
		merge 1:1 variable using "data/cr_selected_model_coefficients_time.dta"
	}
	recode _m 2/3=1 1=0, gen(select_geog`i')
	drop _m
	gen poscoef_geog`i' = (coef>0)
	drop coef
	foreach var of varlist select* {
		recode `var' .=0
	}
}
rename select_geog8 select_time
rename poscoef_geog8 poscoef_time

	
* Landmark
foreach tvc in foi ae susp {
	merge 1:1 variable using "data/cr_selected_model_coefficients_landmark_`tvc'.dta"
	recode _m 2/3=1 1=0, gen(select_`tvc')
	drop _m
	gen poscoef_`tvc' = (coef>0)
	drop coef
	foreach var of varlist select* {
		recode `var' .=0
	}
}


* Save data
save "data/cr_all_selected_models.dta", replace 

