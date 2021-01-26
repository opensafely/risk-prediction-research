********************************************************************************
*
*	Do-file:		404_rp_c_validation_28day.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/
*						model_ci_`tvc'.dta
*						model_cii_covid_`tvc'.dta
*						model_cii_allcause_`tvc'.dta
*									where tvc=foi, ae, susp
*
*	Data created:	data/approach_c_1
*					output/approach_c_validation_28day.out
*
*	Other output:	Log file:  	output/403_rp_c_validation_28day.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design C (landmark, daily and weekly) 
*					models in terms of their predictive ability.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/404_rp_c_validation_28day", text replace

* Ensure program cc_calib is available
qui do "./analysis/ado/cc_calib.ado"


******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


* Variables relating to the burden of COVID-19 infection
global tvc_foi  = "logfoi foi_q_day foi_q_daysq foiqd foiqds" 
global tvc_ae   = "logae ae_q_day ae_q_daysq aeqd aeqds aeqds2"
global tvc_susp = "logsusp susp_q_day susp_q_daysq suspqd suspqds suspqds2"




/*  Time-split 28-day landmark studies  */

foreach tvc in foi ae susp {

	use "data/model_ci_`tvc'.dta", clear
	
	* Pick up baseline survival
	global bs_c_pois_`tvc' = coef[1]
	drop in 1
	
	* Remove coefficients for time-varying measures of infection
	gen temp = 0
	local searchlist = "${tvc_`tvc'}" 
	foreach term in `searchlist' {
		replace temp = 1 if regexm(term, "`term'")
	}
	drop if temp==1
	drop temp
	
	
	* Pick up IRRs for all other variables
	qui count
	global nt_c_pois_`tvc' = r(N) 
	local t = "${nt_c_pois_`tvc'}" 
	forvalues j = 1 (1) `t' {
		global ce`j'_c_pois_`tvc' 	= coef[`j']
		global ve`j'_c_pois_`tvc' 	= varexpress[`j']	
	}
}



/*  Daily landmark studies - COVID deaths  */


foreach tvc in foi ae susp {

	use "data/model_cii_covid_`tvc'.dta", clear

	* Save coefficients for time-varying measures of infection
	gen temp = 0
	local searchlist = "${tvc_`tvc'}" 
	foreach term in `searchlist' {
		replace temp = 1 if regexm(term, "`term'")
	}
	drop if temp==1
	drop temp
	
	* Pick up baseline survival
	qui summ coef if term=="_cons"
	global cons_covid_`tvc' = r(mean)
	drop if term=="_cons"
	
	* Pick up IRRs
	qui count
	global nt_covid_`tvc' = r(N) 
	local t = "${nt_covid_`tvc'}" 
	forvalues j = 1 (1) `t' {
		global ce`j'_covid_`tvc' 	= coef[`j']
		global ve`j'_covid_`tvc' 	= varexpress[`j']	
	}
}



/*  Daily landmark studies - non-COVID deaths  */


foreach tvc in foi ae susp {

	use "data/model_cii_allcause_`tvc'.dta", clear

	* Pick up baseline survival
	qui summ coef if term=="_cons"
	global cons_noncovid_`tvc' = r(mean)
	drop if term=="_cons"
	
	* Pick up IRRs
	qui count
	global nt_noncovid_`tvc' = r(N) 
	local t = "${nt_noncovid_`tvc'}" 
	forvalues j = 1 (1) `t' {
		global ce`j'_noncovid_`tvc' = coef[`j']
		global ve`j'_noncovid_`tvc' = varexpress[`j']	
	}
}





*******************************************************
*  Pick up required summaries of infection variables  *
*******************************************************




******************************
*  Open validation datasets  *
******************************

* Variables within which proxies are measured
local matching_vars_foi  = "region_7 agegroupfoi" 
local matching_vars_ae   = "stp_combined" 
local matching_vars_susp = "stp_combined" 

		
forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	
	
	* Age grouping used in FOI data
	recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
	50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 			///
	gen(agegroupfoi)
		
		
	/*  Obtain predicted risks from each model  */
	
	foreach tvc in foi ae susp {		
		
		/*  Time-split 28-day landmark studies  */

		* Add in summaries of time-varying covariates
		merge m:1 `matching_vars_`tvc'' using "data/sumxb_ci_`tvc'_vp`i'", nogen

		gen xb = 0
		local t = ${nt_c_pois_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${ce`j'_c_pois_`tvc'}*${ve`j'_c_pois_`tvc'}
		}
		* Make predictions under actual, constant-estimation, and best-guess 
		* predictions of burden of infection 
		foreach pred in actual cons pred {
			gen pred_ci_`tvc'_`pred' = 1 - ((${bs_c_pois_`tvc'})^exp(xb))^(exp_`pred')
		}	
		drop xb*		
	

		/*  Daily landmark studies - non-COVID deaths  */

		gen xb_noncovid = ${cons_noncovid_`tvc'}
		local t = ${nt_noncovid_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb_noncovid = xb_noncovid + ///
					${ce`j'_noncovid_`tvc'}*${ve`j'_noncovid_`tvc'}
		}
		gen exp_noncovid = exp(xb_noncovid)
		drop xb_noncovid
		
		* Add in summaries of time-varying covariates
		merge m:1 `matching_vars_`tvc'' using "data/sumxb_cii_`tvc'_vp`i'", nogen

		gen xb = ${cons_covid_`tvc'}
		local t = ${nt_covid_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${ce`j'_covid_`tvc'}*${ve`j'_covid_`tvc'}
		}
		gen exp = exp(xb)
		drop xb
		
		* Make predictions under actual, constant-estimation, and best-guess 
		* predictions of burden of infection 
		foreach pred in actual cons pred {
			gen pred_cii_`tvc'_`pred' = 1 - exp(-28*exp_noncovid)*(exp(exp)^(exp_`pred'))
		}	
		drop exp*	
	}

	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_c_`i'", replace

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
			post `measures' ("C") ("`var'") ("vp`i'") (`brier') (`brier_p') ///
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
use "data/approach_c_1", clear
forvalues i = 2(1)3 { 
	append using "data/approach_c_`i'" 
	erase "data/approach_c_`i'.dta" 
}
erase "data/approach_c_1.dta" 
save "data/approach_c_validation_28day.dta", replace 




* Export a text version of the output
use "data/approach_c_validation_28day.dta", clear
outsheet using "output/approach_c_validation_28day.out", replace




* Close log file
log close
