********************************************************************************
*
*	Do-file:		303_rp_b_validation_28day.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/approach_b_1
*
*	Other output:	Log file:  	output/303_rp_b_validation_28day.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design B (landmark) models in terms 
*					of their predictive ability.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/303_rp_b_validation_28day", text replace




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Logistic regression models  */

foreach tvc of foi ae susp {

	use "data/model_b_logistic_`tvc'.dta", clear

	qui count
	global nt_b_logit_`tvc' = r(N)
	forvalues j = 1 (1) ${nt_b_logit_`tvc'} {
		global coef`j'_b_logit_`tvc' 		= coef[`j']
		global varexpress`j'_b_logit_`tvc' 	= varexpress[`j']	
	}
}




/*  Poisson regression models  */


foreach tvc of foi ae susp {

	use "data/model_b_poisson_`tvc'.dta", clear

	qui count
	global nt_b_pois_`tvc' = r(N)
	forvalues j = 1 (1) ${nt_b_pois_`tvc'} {
		global coef`j'_b_pois_`tvc' 		= coef[`j']
		global varexpress`j'_b_pois_`tvc' 	= varexpress[`j']	
	}
}




/*  Weibull regression models  */


foreach tvc of foi ae susp {

	use "data/model_b_weibull_`tvc'.dta", clear
 
	* Pick up baseline survival
	global bs_b_weib_`tvc' = coef[1]

	* Pick up HRs
	qui count
	global nt_b_weib_nos = r(N) - 1
	forvalues j = 1 (1) ${nt_b_weib_`tvc'} {
		local k = `j' + 1
		global coef`j'_b_weib_`tvc' 		= coef[`k']
		global varexpress`j'_b_weib_`tvc' 	= varexpress[`k']
	}
}








*******************************
*  Open validation dataset 1  *
*******************************



use "data/cr_cohort_vp1.dta", clear
gen constant = 1

* Predict under conditions of no shielding (Validation period 1 was pre-shield)
gen shield   = 0



/*   Logistic regression  */

*** Model without shielding, no infectious disease measures
gen xb = 0
forvalues j = 1 (1) $nt_b_logit_nos {
	replace xb = xb + ${coef`j'_b_logit_nos}*${varexpress`j'_b_logit_nos}
}
gen pred_b_logit_nos = exp(xb)/(1 + exp(xb))
drop xb




*** Model with shielding, infectious disease measure = force of infection




*** Model with shielding, infectious disease measure = ???







/*   Poisson regression  */


*** Model without shielding, no infectious disease measures
gen xb = 0
forvalues j = 1 (1) $nt_b_pois_nos {
	replace xb = xb + ${coef`j'_b_pois_nos}*${varexpress`j'_b_pois_nos}
}
replace xb = xb + log(28)
gen pred_b_pois_nos = 1 -  exp(-exp(xb))
drop xb




*** Model with shielding, infectious disease measure = force of infection




*** Model with shielding, infectious disease measure = ???







/*   Poisson regression USING STREG  */


*** Model without shielding, no infectious disease measures
gen xb = 0
forvalues j = 1 (1) $nt_b_pois2_nos {
	replace xb = xb + ${coef`j'_b_pois2_nos}*${varexpress`j'_b_pois2_nos}
}
gen pred_b_pois2_nos = 1 -  (${bs_b_pois2_nos})^exp(xb)
drop xb





/*   Weibull regression  */


*** Model without shielding, no infectious disease measures
gen xb = 0
forvalues j = 1 (1) $nt_b_weib_nos {
	replace xb = xb + ${coef`j'_b_weib_nos}*${varexpress`j'_b_weib_nos}
}
gen pred_b_weib_nos = 1 -  (${bs_b_weib_nos})^exp(xb)
drop xb









 
**************************
*   Validation measures  *
**************************


tempname measures
postfile `measures' str5(approach) str30(prediction)						///
	brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
	calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
	calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
	using "data/approach_b_1", replace

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



