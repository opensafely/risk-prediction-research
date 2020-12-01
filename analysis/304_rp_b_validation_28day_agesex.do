********************************************************************************
*
*	Do-file:		304_rp_b_validation_28day_agesex.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/approach_b_validation_28day_agesex.dta
*					output/approach_b_validation_28day_agesex.out
*
*	Other output:	Log file:  	output/304_rp_b_validation_28day_agesex.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design B (landmark) models within  
*					groups defined by age and sex.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/304_rp_b_validation_28day_agesex", text replace




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Logistic regression models  */

foreach tvc in foi ae susp {

	use "data/model_b_logistic_`tvc'.dta", clear

	qui count
	global nt_b_logit_`tvc' = r(N)
	local t = 	${nt_b_logit_`tvc'} 
	forvalues j = 1 (1) `t' {
		global coef`j'_b_logit_`tvc' 		= coef[`j']
		global varexpress`j'_b_logit_`tvc' 	= varexpress[`j']	
	}
}




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




/*  Weibull regression models  */


foreach tvc in foi ae susp {

	use "data/model_b_weibull_`tvc'.dta", clear
 
	* Pick up baseline survival
	global bs_b_weib_`tvc' = coef[1]

	* Pick up HRs
	qui count
	global nt_b_weib_`tvc' = r(N) - 1
	local t = 	${nt_b_weib_`tvc'} 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global coef`j'_b_weib_`tvc' 		= coef[`k']
		global varexpress`j'_b_weib_`tvc' 	= varexpress[`k']
	}
}







******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	
	* Delete 100-day outcome to avoid potential confusion
	drop onscoviddeath
	
	

	/*  Create time-varying variables needed  */

	* Variables needed for force of infection data

	assert foi>0
	gen logfoi = log(foi)
	gen foiqd  =  foi_q_day/foi_q_cons
	gen foiqds =  foi_q_daysq/foi_q_cons


	* Variables needed for A&E attendance data
	gen aepos = aerate
	qui summ aerate if aerate>0 
	replace aepos = 0.06279008 if aepos==0

	gen logae		= log(aepos)
	gen aeqd		= ae_q_day/ae_q_cons
	gen aeqds 		= ae_q_daysq/ae_q_cons

	replace aeqd  = 0 if ae_q_cons==0
	replace aeqds = 0 if ae_q_cons==0

	gen aeqint 		= aeqd*aeqds
	gen aeqd2		= aeqd^2
	gen aeqds2		= aeqds^2


	* Variables needed for GP suspected case data

	gen susppos = susp_rate
	qui summ susp_rate if susp_rate>0 
	assert susppos > 0 
	
	* Create time variables to be fed into the variable selection process
	gen logsusp	 	= log(susppos)
	gen suspqd	 	= susp_q_day/susp_q_cons
	gen suspqds 	= susp_q_daysq/susp_q_cons

	replace suspqd  = 0 if susp_q_cons==0
	replace suspqds = 0 if susp_q_cons==0

	gen suspqint   	= suspqd*suspqds
	gen suspqd2 	= suspqd^2
	gen suspqds2	= suspqds^2

	
	/*  Pick up list of variables in model  */
	
	qui do "analysis/104_pr_variable_selection_landmark_output.do" 

	
	
	/*  Obtain predicted risks from each model  */
	
	foreach tvc in foi ae susp {

		/*  Logistic  */

		gen constant = 1
		gen xb = 0
		local t = ${nt_b_logit_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${coef`j'_b_logit_`tvc'}*${varexpress`j'_b_logit_`tvc'}
		}
		gen pred_b_logit_`tvc' = exp(xb)/(1 + exp(xb))   
		drop xb cons


		/*  Poisson  */

		gen xb = 0
		local t = ${nt_b_pois_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${coef`j'_b_pois_`tvc'}*${varexpress`j'_b_pois_`tvc'}
		}
		gen pred_b_pois_`tvc' = 1 -  (${bs_b_pois_`tvc'})^exp(xb)
		drop xb


		/*  Weibull */

		gen xb = 0
		local t = ${nt_b_weib_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${coef`j'_b_weib_`tvc'}*${varexpress`j'_b_weib_`tvc'}
		}
		gen pred_b_weib_`tvc' = 1 -  (${bs_b_weib_`tvc'})^exp(xb)
		drop xb
		

	}

	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		age sex																	///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_b_`i'_agesex", replace

		forvalues j = 0 (1) 1 {		// Sex
			forvalues k = 1 (1) 6 { 	// Age-group
				foreach var of varlist pred* {
			
				* Overall performance: Brier score
				noi brier onscoviddeath28 `var'	///
					if agegroup==`j' & male==`j', group(10)
				local brier 	= r(brier) 
				local brier_p 	= r(p) 

				* Discrimination: C-statistic
				local cstat 	= r(roc_area) 
				local cstat_p 	= r(p_roc)
				 
				* Calibration
				noi cc_calib onscoviddeath28  `var'	///
					if agegroup==`j' & male==`j', data(internal) 

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
				post `measures' ("B") ("`var'") ("vp`i'") 						///
								(`k') (`j') 									///
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
		}
	postclose `measures'
}




* Clean up
use "data/approach_b_1_agesex", clear
forvalues i = 2(1)3 { 
	append using "data/approach_b_`i'_agesex" 
	erase "data/approach_b_`i'_agesex.dta" 
}
erase "data/approach_b_1_agesex.dta" 

capture label drop agegroup
label define agegroup 	1 "18-<40"	///
						2 "40-<50"	///
						3 "50-<60"	///
						4 "60-<70"	///
						5 "70-<80"	///
						6 "80+"
label values agegroup agegroup

save "data/approach_b_validation_28day_agesex.dta", replace 




* Export a text version of the output
use "data/approach_b_validation_28day_agesex.dta", clear
outsheet using "output/approach_b_validation_28day_agesex.out", replace




* Close log file
log close

