********************************************************************************
*
*	Do-file:		204_rp_a_validation_28day_whole_cohort.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH_whole_cohort.dta
*
*	Data created:	data/approach_a_validation_28day_whole_cohort.dta
*					output/approach_a_validation_28day_whole_cohort.out
*
*	Other output:	Log file:  	output/204_rp_a_validation_28day_whole_cohort.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models, using the Cox model
*					estimated in the full cohort (rather than a case-cohort 
*					design).
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


* Read in output from each model

* Open a log file
capture log close
log using "./output/204_rp_a_validation_28day_whole_cohort", text replace


* Ensure cc_calib is available
do "analysis/ado/cc_calib.ado"




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************

/*  Cox model  */

use "data/model_a_coxPH_whole_cohort", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_a_cox_nos = coef[1]

* Pick up HRs
qui count
global nt_a_cox_nos = r(N) - 1
forvalues j = 1 (1) $nt_a_cox_nos {
	local k = `j' + 1
	global coef`j'_a_cox_nos = coef[`k']
	global varexpress`j'_a_cox_nos = varexpress[`k']
}




******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	
	* Pick up list of variables in model
	do "analysis/101_pr_variable_selection_output.do"
	noi di "$bn_terms"
	
	/*   Cox model   */

	gen xb = 0
	forvalues j = 1 (1) $nt_a_cox_nos {
		replace xb = xb + ${coef`j'_a_cox_nos}*${varexpress`j'_a_cox_nos}	
	}
	gen pred_a_cox_nos = 1 -  (${bs_a_cox_nos})^exp(xb)
	drop xb

	
	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_a_`i'", replace

		foreach var of varlist pred* {
			
			* Overall performance: Brier score
			noi brier onscoviddeath28 `var', group(10)
			local brier 	= r(brier) 
			local brier_p 	= r(p) 

			* Discrimination: C-statistic
			local cstat 	= r(roc_area) 
			local cstat_p 	= r(p_roc)
			 
			* Calibration
			noi cc_calib onscoviddeath28  `var', data(internal) 

			* Hosmer-Lemeshow
			local hl 		= r(chi)  
			local hl_p 		= r(p_chi)
			
			* Mean calibration
			local mean_obs  = r(mean_obs)
			local mean_pred = r(mean_pred)
			
			* Calibration intercept and slope
			local calib_inter 		= r(calib_inter)
			local calib_inter_se 	= r(calib_inter_se)
			local calib_inter_cl 	= r(calib_inter_cl)
			local calib_inter_cu 	= r(calib_inter_cu)
			local calib_inter_p  	= r(calib_inter_p)
			
			local calib_slope 		= r(calib_slope)
			local calib_slope_se 	= r(calib_slope_se)
			local calib_slope_cl 	= r(calib_slope_cl)
			local calib_slope_cu 	= r(calib_slope_cu)
			local calib_slope_p  	= r(calib_slope_p)
			
			
			* Save measures
			post `measures' ("A") ("`var'") ("vp`i'") (`brier') (`brier_p') ///
							(`cstat') (`cstat_p') 							///
							(`hl') (`hl_p') 								///
							(`mean_obs') (`mean_pred') 						///
							(`calib_inter') (`calib_inter_se') 				///
							(`calib_inter_cl') 								/// 
							(`calib_inter_cu') (`calib_inter_p') 			///
							(`calib_slope') (`calib_slope_se') 				///
							(`calib_slope_cl') 								///
							(`calib_slope_cu') (`calib_slope_p')

		}
	postclose `measures'
}




* Clean up
use "data/approach_a_1", clear
forvalues i = 2(1)3 { 
	append using "data/approach_a_`i'" 
	erase "data/approach_a_`i'.dta" 
}
erase "data/approach_a_1.dta" 
save "data/approach_a_validation_28day_whole_cohort.dta", replace 



* Export a text version of the output
use "data/approach_a_validation_28day_whole_cohort.dta", clear
outsheet using "output/approach_a_validation_28day_whole_cohort.out", replace




* Close log file
log close






