********************************************************************************
*
*	Do-file:		504_rp_a_validation_28day_intext.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH_`r'.dta
*						model_a_roy_`r'.dta
*						model_a_weibull_`r'.dta
*						model_a_ggamma_`r'.dta
*					(for r=1,2,...,8; 7 leave-one-out regions & time)
*
*	Data created:	data/approach_a_validation_28day_intext.dta
*					output/approach_a_validation_28day_intext.out
*
*	Other output:	Log file:  	output/504_rp_a_validation_28day_intext.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models for the internal-
*					external validation (leaving a region/time period out).
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************



* Open a log file
capture log close
log using "./output/504_rp_a_validation_28day_intext", text replace


* Ensure cc_calib is available
qui do "analysis/ado/cc_calib.ado"




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************

forvalues r = 1 (1) 8 {

	/*  Cox model  */

	use "data/model_a_coxPH_`r'", clear
	drop if term == "base_surv100" // remove base_surv100

	* Pick up baseline survival
	global bs_a_cox_`r' = coef[1]

	* Pick up HRs
	qui count
	global nt_a_cox_`r' = r(N) - 1
	local t = ${nt_a_cox_`r'}
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global coef`j'_a_cox_`r' 		= coef[`k']
		global varexpress`j'_a_cox_`r' 	= varexpress[`k']
	}


	/*  Royston Parmar model */

	use "data/model_a_roy_`r'", clear
	drop if term == "base_surv100"  | term == "_cons" // remove base_surv100

	* Pick up baseline survival
	global bs_a_roy_`r' = coef[1]

	qui count
	global nt_a_roy_`r' = r(N) - 1
	local t = ${nt_a_roy_`r'}
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global coef`j'_a_roy_`r' 		= coef[`k']
		global varexpress`j'_a_roy_`r' 	= varexpress[`k']
	}


	/*  Weibull model  */

	use "data/model_a_weibull_`r'", clear
	drop if term == "base_surv100" | term == "_cons" 

	* Pick up baseline survival
	global bs_a_weibull_`r' = coef[1]

	* Pick up HRs
	qui count
	global nt_a_weibull_`r' = r(N) - 1
	local t = ${nt_a_weibull_`r'}
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global coef`j'_a_weibull_`r' 		= coef[`k']
		global varexpress`j'_a_weibull_`r' 	= varexpress[`k']
	}


	/*  Generalised gamma model  */

	use "data/model_a_ggamma_`r'", clear
	global sigma_`r' = coef[1]
	global kappa_`r' = coef[2]

	di ${sigma_`r'}
	di ${kappa_`r'}
	drop if _n <=2 // ie drop sigma / kappa values

	qui count
	global nt_a_ggamma_`r' = r(N)
	local t = ${nt_a_ggamma_`r'}
	forvalues j = 1 (1) `t' {
		global coef`j'_a_ggamma_`r' 		= coef[`j']
		global varexpress`j'_a_ggamma_`r' 	= varexpress[`j']	
	}
}





**************************************************************
*  Use the model to make predictions in the validation data  *
**************************************************************

* Cycle over three validation datasets
forvalues i = 1/3 {
	
	* Open the validation data
	use "data/cr_cohort_vp`i'.dta", clear
	
	* Delete 100-day outcome to avoid potential confusion
	drop onscoviddeath
	
	* Pick up list of variables in model
	qui do "analysis/107_pr_variable_selection_intext_output.do" 

	
	* Cycle over regions/time periods
	forvalues r = 1 (1) 8 {
		if !(`r'==8 & `i'<3) {


			* Define the bn terms for Royston parmar model
			global bn_terms = "${bn_terms_`r'}"
			noi di "$bn_terms"
			capture drop _*
			
			foreach var of global bn_terms {
				* Remove bn
				local term = subinstr("`var'", "bn", "", .)
				* remove "." from name
				local term = subinstr("`term'", ".", "", .)
				* Check if its an interaction term and remove # if needed 
				local term = subinstr("`term'", "#", "", .)
				* add _
				local term = "__" + "`term'" 
				local term = substr("`term'", 1, 15)
				fvrevar `var', stub(`term')
			}

		
			/*   Cox model  */

			gen xb = 0
			local t = ${nt_a_cox_`r'}
			forvalues j = 1 (1) `t' {
				replace xb = xb + ${coef`j'_a_cox_`r'}*${varexpress`j'_a_cox_`r'}	
			}
			gen pred_a_cox_`r' = 1 -  (${bs_a_cox_`r'})^exp(xb)
			drop xb


			
			/* Royston-Parmar */

			gen xb = 0
			local t = ${nt_a_roy_`r'}
			forvalues j = 1 (1) `t' {
				* If coefficient is NOT the constant term
				if `j' != ${nt_a_roy_`r'} {
					replace xb = xb + ${coef`j'_a_roy_`r'}*${varexpress`j'_a_roy_`r'}
				}

			}
			gen pred_a_roy_`r' = 1 -  (${bs_a_roy_`r'})^exp(xb)
			drop xb


			
			/*  Weibull */

			gen xb = 0
			local t = ${nt_a_weibull_`r'} 
			forvalues j = 1 (1) `t' {

				* If coefficient is NOT the constant term
				if `j' != ${nt_a_weibull_`r'} {
				replace xb = xb + ${coef`j'_a_weibull_`r'}*${varexpress`j'_a_weibull_`r'}
				}
			}
			gen pred_a_weibull_`r' = 1 -  (${bs_a_weibull_`r'})^exp(xb)
			drop xb
			 
			 
			 
			/* Gamma */ 

			gen xb = 0
			local t = ${nt_a_ggamma_`r'}
			forvalues j = 1 (1) `t' {

				* If coefficient is NOT the constant term
				if `j' != `t' {
					replace xb = xb + ${coef`j'_a_ggamma_`r'}*${varexpress`j'_a_ggamma_`r'}
				}
				* Add on the constant term	
				if `j' == `t' {
					replace xb = xb + ${coef`j'_a_ggamma_`r'}
				}	
			}
			gen sign = cond(${kappa_`r'} < 0,-1,1) 
			gen gamma = abs(${kappa_`r'})^(-2)
			gen z = sign*(ln(28) - xb)/${sigma_`r'}

			if ${kappa_`r'} == 0 {
				global surv_a_gamma = 1 - normal(z)
			}
			else {
				* s(t) = pred if k < 1
				gen surv_a_gamma = gammap(gamma, gamma*exp(abs(${kappa_`r'}) *z))
				* Replace s(t) = 1-pred if k > 1 
				replace surv_a_gamma = cond(sign == 1 , 1 - surv_a_gamma, surv_a_gamma)
			}

			gen pred_a_gamma_`r' = 1 - surv_a_gamma
			drop xb sign gamma z surv_a_gamma
			

		
			* Only make predictions for left-out region
			if `r'<8 {
				replace pred_a_cox_`r' 		= . if region_7!=`r'
				replace pred_a_roy_`r' 		= . if region_7!=`r'
				replace pred_a_weibull_`r'  = . if region_7!=`r'
				replace pred_a_gamma_`r'  	= . if region_7!=`r'
			}
		}
	
	}


	
		
	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str10(approach) str30(prediction) str8(period) loo		///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_a_`i'_intext", replace

				
		forvalues r = 1 (1) 8 {
			if (`r'<8 | `i'==3) {
				foreach model in cox roy weibull gamma {
				
					* Note which loop is being done
					noi di "DOING model  `model'  for region  `r'"
					
					* Pick up relevant prediction
					local var = "pred_a_`model'_`r'"
					
					* Overall performance: Brier score
					noi di "DOING Brier score model  `model'  for region  `r'"
					noi brier onscoviddeath28 `var' 	///
						if region_7==`r' | `r'==8, 		///
						group(10)
					local brier 	= r(brier) 
					local brier_p 	= r(p) 
					noi di "FINISHED Brier score model `model'  for region  `r'"

					* Discrimination: C-statistic
					local cstat 	= r(roc_area) 
					local cstat_p 	= r(p_roc)
					 
					* Calibration					
					noi di "DOING cc_calib model  `model'  for region  `r'"
					noi cc_calib onscoviddeath28  `var' ///
						if region_7==`r' | `r'==8, 		///
						data(internal) 
					noi di "FINISHED Brier score model `model'  for region  `r'"

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
					post `measures' ("A-intext") ("`var'") ("vp`i'") (`r')			///
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

					* Delete variables created by cc_calib (above)
					foreach var in obs_events exp_events 	///
								pbar n chi_term group_gof {
						capture drop `var'
					}
				}
			}
		}
	postclose `measures'
}



* Clean up
use "data/approach_a_1_intext", clear
forvalues i = 2(1)3 { 
	append using "data/approach_a_`i'_intext" 
	erase "data/approach_a_`i'_intext.dta" 
}
erase "data/approach_a_1_intext.dta" 

label define loo 	1 "Region 1 omitted"	///
					2 "Region 2 omitted"	///
					3 "Region 3 omitted"	///
					4 "Region 4 omitted"	///
					5 "Region 5 omitted"	///
					6 "Region 6 omitted"	///
					7 "Region 7 omitted"	///
					8 "Later time omitted"	
label values loo loo

save "data/approach_a_validation_28day_intext.dta", replace 

* Export a text version of the output
use "data/approach_a_validation_28day_intext.dta", clear
outsheet using "output/approach_a_validation_28day_intext.out", replace



* Close log file
log close







