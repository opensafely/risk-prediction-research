********************************************************************************
*
*	Do-file:		603_rp_b_validation_28day_intext.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/approach_b_1_intext.dta
*
*	Other output:	Log file:  	output/603_rp_b_validation_28day_intext.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design B (landmark) models in terms 
*					of their predictive ability.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/603_rp_b_validation_28day_intext", text replace


* Ensure cc_calib is available
qui do "analysis/ado/cc_calib.ado"



******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


forvalues r = 1 (1) 8 {

	/*  Logistic regression models  */

	foreach tvc in foi ae susp {

		use "data/model_b_logistic_`tvc'_`r'.dta", clear

		qui count
		global nt_b_logit_`tvc'_`r' = r(N)
		local t = ${nt_b_logit_`tvc'_`r'} 
		forvalues j = 1 (1) `t' {		
			global coef`j'_b_logit_`tvc'_`r' 		= coef[`j']
			global varexpress`j'_b_logit_`tvc'_`r' 	= varexpress[`j']	
		}
	}




	/*  Poisson regression models  */


	foreach tvc in foi ae susp {

		use "data/model_b_poisson_`tvc'_`r'.dta", clear

		* Pick up baseline survival
		global bs_b_pois_`tvc'_`r' = coef[1]
		
		* Pick up IRRs
		qui count
		global nt_b_pois_`tvc'_`r' = r(N) - 1
		local t = ${nt_b_pois_`tvc'_`r'}
		forvalues j = 1 (1) `t' {	
			local k = `j' + 1
			global coef`j'_b_pois_`tvc'_`r' 		= coef[`k']
			global varexpress`j'_b_pois_`tvc'_`r' 	= varexpress[`k']	
		}
	}




	/*  Weibull regression models  */


	foreach tvc in foi ae susp {

		use "data/model_b_weibull_`tvc'_`r'.dta", clear
	 
		* Pick up baseline survival
		global bs_b_weib_`tvc'_`r' = coef[1]

		* Pick up HRs
		qui count
		global nt_b_weib_`tvc'_`r' = r(N) - 1
		local t = ${nt_b_weib_`tvc'_`r'}
		forvalues j = 1 (1) `t' {	
			local k = `j' + 1
			global coef`j'_b_weib_`tvc'_`r' 		= coef[`k']
			global varexpress`j'_b_weib_`tvc'_`r' 	= varexpress[`k']
		}
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

	
	
		
	* Cycle over regions/time periods
	forvalues r = 1 (1) 8 {
		if !(`r'==8 & `i'<3) {				
					
			
			/*  Obtain predicted risks from each model  */
			
			foreach tvc in foi ae susp {

				/*  Logistic  */

				gen constant = 1
				gen xb = 0
				local t = ${nt_b_logit_`tvc'_`r'} 
				forvalues j = 1 (1) `t' {
					replace xb = xb + ${coef`j'_b_logit_`tvc'_`r'}*${varexpress`j'_b_logit_`tvc'_`r'}
				}
				gen pred_b_logit_`tvc'_`r' = exp(xb)/(1 + exp(xb))   
				drop xb cons


				/*  Poisson  */

				gen xb = 0
				local t = ${nt_b_pois_`tvc'_`r'}
				forvalues j = 1 (1) `t' {
					replace xb = xb + ${coef`j'_b_pois_`tvc'_`r'}*${varexpress`j'_b_pois_`tvc'_`r'}
				}
				gen pred_b_pois_`tvc'_`r' = 1 -  (${bs_b_pois_`tvc'_`r'})^exp(xb)
				drop xb


				/*  Weibull */

				gen xb = 0
				local t = ${nt_b_weib_`tvc'_`r'}
				forvalues j = 1 (1) `t' {
					replace xb = xb + ${coef`j'_b_weib_`tvc'_`r'}*${varexpress`j'_b_weib_`tvc'_`r'}
				}
				gen pred_b_weib_`tvc'_`r' = 1 -  (${bs_b_weib_`tvc'_`r'})^exp(xb)
				drop xb
			
					
				* Only make predictions for left-out region
				if `r'<8 {
					replace pred_b_logit_`tvc'_`r' = . if region_7!=`r'
					replace pred_b_pois_`tvc'_`r'  = . if region_7!=`r'
					replace pred_b_weib_`tvc'_`r'  = . if region_7!=`r'
				}
			}	
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
		using "data/approach_b_`i'_intext", replace

				
		forvalues r = 1 (1) 8 {
			if (`r'<8 | `i'==3) {
				foreach tvc in foi ae susp {
					foreach model in logit pois weib {
							
					* Note which loop is being undertaken
					noi di "DOING model  pred_b_`model'_`tvc'_`r' for region `r'"
				
					* Overall performance: Brier score
					noi di "DOING Brier score for pred_b_`model'_`tvc'_`r' in region  `r'"
					noi brier onscoviddeath28 pred_b_`model'_`tvc'_`r' 	///
						if region_7==`r' | `r'==8, 						///
						group(10)
					local brier 	= r(brier) 
					local brier_p 	= r(p) 

					* Discrimination: C-statistic
					local cstat 	= r(roc_area) 
					local cstat_p 	= r(p_roc)
					noi di "FINISHED Brier score for pred_b_`model'_`tvc'_`r' in region  `r'"
					 
					* Calibration
					noi di "DOING calibration for pred_b_`model'_`tvc'_`r' in region  `r'"
					noi cc_calib onscoviddeath28 pred_b_`model'_`tvc'_`r' 	///
						if region_7==`r' | `r'==8, 	data(internal) 

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
					noi di "FINISHED calibration for pred_b_`model'_`tvc'_`r' in region  `r'"
			
					
					* Save measures
					post `measures' ("B") ("`var'") ("vp`i'") 						///
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
		}
	postclose `measures'
}




* Clean up
use "data/approach_b_1_intext", clear
forvalues i = 2(1)3 { 
	append using "data/approach_b_`i'_intext" 
	erase "data/approach_b_`i'_intext.dta" 
}
erase "data/approach_b_1_intext.dta" 

label define loo 	1 "Region 1 omitted"	///
					2 "Region 2 omitted"	///
					3 "Region 3 omitted"	///
					4 "Region 4 omitted"	///
					5 "Region 5 omitted"	///
					6 "Region 6 omitted"	///
					7 "Region 7 omitted"	///
					8 "Later time omitted"	
label values loo loo

save "data/approach_b_validation_28day_intext.dta", replace 



* Export a text version of the output
use "data/approach_b_validation_28day_intext.dta", clear
outsheet using "output/approach_b_validation_28day_intext.out", replace


* Close log file
log close


