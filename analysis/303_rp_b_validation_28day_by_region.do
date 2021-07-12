********************************************************************************
*
*	Do-file:		303_rp_b_validation_28day_by_region.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/
*						model_b_logistic_`tvc'.dta
*						model_b_poisson_`tvc'.dta
*						model_b_weibull_`tvc.dta
*									where tvc=foi, ae, susp
*
*	Data created:	data/approach_b_validation_28day_by_region.dta
*					output/approach_b_validation_28day_by_region.out
*
*	Other output:	Log file:  	output/303_rp_b_validation_28day_by_region.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design B (landmark) models in terms 
*					of their predictive ability.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/303_rp_b_validation_28day_by_region", text replace




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Poisson regression models  */


foreach tvc in foi ae susp {

	use "data/model_b_poisson_`tvc'.dta", clear

	* Pick up baseline survival
	global bs_b_pois_`tvc' = coef[1]
	
	* Pick up IRRs
	qui count
	global nt_b_pois_`tvc' = r(N) - 1
	local t = 	${nt_b_pois_`tvc'} 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global coef`j'_b_pois_`tvc' 		= coef[`k']
		global varexpress`j'_b_pois_`tvc' 	= varexpress[`k']	
	}
}



******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	

	/*  Pick up list of variables in model  */
	
	qui do "analysis/104_pr_variable_selection_landmark_output.do" 

	
	
	/*  Obtain predicted risks from each model  */
	
	foreach tvc in foi ae susp {

		/*  Poisson  */

		gen xb = 0
		local t = ${nt_b_pois_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${coef`j'_b_pois_`tvc'}*${varexpress`j'_b_pois_`tvc'}
		}
		gen pred_b_pois_`tvc' = 1 -  (${bs_b_pois_`tvc'})^exp(xb)
		drop xb

	}

	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) region str30(prediction) str3(period) 	///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_b_`i'_by_region", replace

		foreach var of varlist pred* {
			forvalues r = 1 (1) 7 {
		
				* Overall performance: Brier score
				noi brier onscoviddeath28 `var' if region_7==`r', group(10)
				local brier 	= r(brier) 
				local brier_p 	= r(p) 

				* Discrimination: C-statistic
				local cstat 	= r(roc_area) 
				local cstat_p 	= r(p_roc)
				 
				* Calibration
				noi cc_calib onscoviddeath28  `var' if region_7==`r', data(internal) 

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
				post `measures' ("B") (`r') ("`var'") ("vp`i'") 				///
								(`brier') (`brier_p') 							///
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
		}
	postclose `measures'
}




* Clean up
use "data/approach_b_1_by_region", clear
forvalues i = 2(1)3 { 
	append using "data/approach_b_`i'_by_region" 
	erase "data/approach_b_`i'_by_region.dta" 
}
erase "data/approach_b_1_by_region.dta" 
save "data/approach_b_validation_28day_by_region.dta", replace 




* Export a text version of the output
use "data/approach_b_validation_28day_by_region.dta", clear
outsheet using "output/approach_b_validation_28day_by_region.out", replace




* Close log file
log close

