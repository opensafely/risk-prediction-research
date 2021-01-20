********************************************************************************
*
*	Do-file:		1401_rp_b_validation_28day_tvcsens.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/approach_b_1_tvcsens.dta
*					output/approach_b_validation_28day_tvcsens.out
*
*	Other output:	Log file:  	output/1401_rp_b_validation_28day_tvcsens.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design B (landmark) models in terms 
*					of their predictive ability for the sensitivity analysis
*					in which (i) time-varying covariates are fixed at baseline
*					(i.e. diabetes, etc. not updated), and (ii) time-varying
*					measures of the burden of disease are omitted.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/1401_rp_b_validation_28day_tvcsens", text replace




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Poisson regression models  */

foreach form in fixed none {
	foreach tvc in foi ae susp {

		use "data/model_b_poisson_`tvc'_tvc`form'.dta", clear

		* Pick up baseline survival
		global bs_b_pois_`tvc'_`form' = coef[1]
		
		* Pick up IRRs
		qui count
		global nt_b_pois_`tvc'_`form' = r(N) - 1
		local t = 	${nt_b_pois_`tvc'_`form'} 
		forvalues j = 1 (1) `t' {
			local k = `j' + 1
			global ce`j'_b_pois_`tvc'_`form' 	= coef[`k']
			global ve`j'_b_pois_`tvc'_`form' 	= varexpress[`k']	
		}
	}
}






******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	


	
	/*  Obtain predicted risks from each model  */
	
	foreach form in fixed none {
		foreach tvc in foi ae susp {
			gen xb = 0
			local t = ${nt_b_pois_`tvc'_`form'}
			forvalues j = 1 (1) `t' {
				replace xb = xb + ${ce`j'_b_pois_`tvc'_`form'}*${ve`j'_b_pois_`tvc'_`form'}
			}
			gen pred_b_pois_`tvc'_`form' = 1 -  (${bs_b_pois_`tvc'_`form'})^exp(xb)
			drop xb
		}
	}
	

	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_b_`i'_tvcsens", replace

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
			post `measures' ("B") ("`var'") ("vp`i'") (`brier') (`brier_p') ///
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
use "data/approach_b_1_tvcsens", clear
forvalues i = 2(1)3 { 
	append using "data/approach_b_`i'_tvcsens" 
	erase "data/approach_b_`i'_tvcsens.dta" 
}
erase "data/approach_b_1_tvcsens.dta" 
save "data/approach_b_validation_28day_tvcsens.dta", replace 




* Export a text version of the output
use "data/approach_b_validation_28day_tvcsens.dta", clear
outsheet using "output/approach_b_validation_28day_tvcsens.out", replace




* Close log file
log close

