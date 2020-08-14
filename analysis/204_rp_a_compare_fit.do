********************************************************************************
*
*	Do-file:		rp_a_compare_fit.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		
*
*	Data created:	None
*
*	Other output:	Log file:  	rp_a_compare_fit.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


use "output\rp_a_weibull_output.dta", replace
* Read in output from each model

* Open a log file
capture log close
log using "./output/rp_a_compare_fit", text replace


******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Cox model  */


*** No shielding
use "data/model_a_coxPH_noshield", clear

qui count
global nt_b_logit_nos = r(N)
forvalues j = 1 (1) $no_terms {
	global coef`j'_b_logit_nos = coef[`j']
	global varexpress`j'_b_logit_nos = varexpress[`j']
	
}

*** Shielding



*******************************
*  Open validation dataset 1  *
*******************************

use "data/cr_cohort_vp1.dta", clear
gen constant = 1

* Predict under conditions of no shielding (Validation period 1 was pre-shield)
gen shield   = 0



/*   Cox model   */









 
**************************
*   Validation measures  *
**************************


tempname measures
postfile `measures' str5(approach) str30(prediction)						///
	brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
	calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
	calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
	using "data/approach_a_1", replace

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
		post `measures' ("B") ("`var'") (`brier') (`brier_p') 		///
						(`cstat') (`cstat_p') 						///
						(`hl') (`hl_p') 							///
						(`mean_obs') (`mean_pred') 					///
						(`calib_inter') (`calib_inter_se') 			///
						(`calib_inter_cl') 							/// 
						(`calib_inter_cu') (`calib_inter_p') 		///
						(`calib_slope') (`calib_slope_se') 			///
						(`calib_slope_cl') 							///
						(`calib_slope_cu') (`calib_slope_p')

	}
postclose `measures'




* Close log file
log close







