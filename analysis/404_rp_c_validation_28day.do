********************************************************************************
*
*	Do-file:		403_rp_b_validation_28day.do
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
*	Purpose:		This do-file compares Design B (landmark) models in terms 
*					of their predictive ability.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/403_rp_c_validation_28day", text replace




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
	
	* Save coefficients for time-varying measures of infection
	gen temp = 0
	local searchlist = "${tvc_`tvc'}" 
	foreach term in `searchlist' {
		replace temp = 1 if regexm(term, "`term'")
	}
	preserve
	keep if temp==1
	keep term coef
	qui count
	local n = r(N)
	forvalues i = 1 (1) `n' {
		local name`i' = term[`i']
	}
	drop term
	xpose, clear
	forvalues i = 1 (1) `n' {
		rename v`i' coef_`name`i''
	}
	expand 28
	gen t = _n
	save "data/temp_foivars_`tvc'", replace
	restore
	drop if temp==1
	drop temp
	
	
	* Pick up IRRs for all other variables
	qui count
	global nt_c_pois_`tvc' = r(N) 
	local t = "${nt_c_pois_`tvc'}" 
	forvalues j = 1 (1) `t' {
		global ce`j'_c_pois_`tvc' 	= coef[`k']
		global ve`j'_c_pois_`tvc' 	= varexpress[`k']	
	}
}



/*  Daily landmark studies - COVID deaths  */


foreach tvc in foi ae susp {

	use "data/model_cii_covid_`tvc'.dta", clear

	* Pick up baseline survival
	qui summ coef if term=="_cons"
	global cons_covid_`tvc' = r(mean)
	drop if term=="_cons"
	
	* Pick up IRRs
	qui count
	global nt_covid_`tvc' = r(N) 
	local t = "${nt_covid_`tvc'}" 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global ce`j'_covid_`tvc' 	= coef[`k']
		global ve`j'_covid_`tvc' 	= varexpress[`k']	
	}
}



/*  Daily landmark studies - non-COVID deaths  */


foreach tvc in foi ae susp {

	use "data/model_cii_noncovid_`tvc'.dta", clear

	* Pick up baseline survival
	qui summ coef if term=="_cons"
	global cons_noncovid_`tvc' = r(mean)
	drop if term=="_cons"
	
	* Pick up IRRs
	qui count
	global nt_noncovid_`tvc' = r(N) 
	local t = "${nt_covid_`tvc'}" 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global ce`j'_noncovid_`tvc' = coef[`k']
		global ve`j'_noncovid_`tvc' = varexpress[`k']	
	}
}





*******************************************************
*  Pick up required summaries of infection variables  *
*******************************************************

***** PUT IN DIFF FIEL AND ADD WHAT YOU GET UNDER BEST PREDICTION VS STAY SAME...???

local gap_vp1 = d(01/03/2020) - d(01/03/2020)
local gap_vp2 = d(06/04/2020) - d(01/03/2020)
local gap_vp3 = d(12/05/2020) - d(01/03/2020)

local matching_vars_foi  = "region_7 agegroupfoi" 
local matching_vars_ae   = "stp_combined" 
local matching_vars_susp = "stp_combined" 

forvalues i = 1/3 {
	foreach tvc in foi ae susp {
		use "data/`tvc'_coefs", replace
		isid time `matching_vars_`tvc''
		keep time `matching_vars_`tvc'' ${tvc_`tvc'} 
		gen t = time - `gap_vp`i''
		drop time
		keep if inrange(t, 1, 28)
		merge m:1 t using "data/temp_foivars_`tvc'", nogen
		isid t `matching_vars_`tvc''
		
		local tvc = "susp"
		gen xb = 0
		local t = "${tvc_`tvc'}"
		foreach tvcvar in `t'  {
			replace xb = xb + `tvcvar'*coef_`tvcvar'
		}
		gen xb2 = xb
		keep t `matching_vars_`tvc'' xb*
			
		* For weekly models: sum days 1, 8, 15, 22
		* For daily models: sum over days 1-28	
		replace xb2 = 0 if !inlist(t, 1, 8, 15, 22)
		collapse (mean) xb xb2, by(`matching_vars_`tvc'')
		rename xb  daily_sumxb_`tvc'
		rename xb2 weekly_sumxb_`tvc'
		isid `matching_vars_`tvc''
		save "data/temp_sumxb_vp`i'_`tvc'", replace
	}
}

* Delete unneeded data
foreach tvc in foi ae susp {
	erase "data/temp_foivars_`tvc'.dta"
}








******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	
	
	/*  Obtain predicted risks from each model  */
	
	foreach tvc in foi ae susp {

	* Add in summaries of time-varying covariates
	merge 1:m `matching_vars_`tvc'' using "temp_sumxb_vp`i'_`tvc'", nogen


		/*  Time-split 28-day landmark studies  */

		gen xb = 0
		local t = ${nt_b_pois_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${coef`j'_b_pois_`tvc'}*${varexpress`j'_b_pois_`tvc'}
		}
		gen pred_b_pois_`tvc' = 1 -  (${bs_b_pois_`tvc'})^exp(xb)
		drop xb


		/*  Daily landmark studies - non-COVID deaths  */

		
		
		
		
	}

	
	
	/*
	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_b_`i'", replace

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
use "data/approach_b_1", clear
forvalues i = 2(1)3 { 
	append using "data/approach_b_`i'" 
	erase "data/approach_b_`i'.dta" 
}
erase "data/approach_b_1.dta" 
save "data/approach_b_validation_28day.dta", replace 




* Export a text version of the output
use "data/approach_b_validation_28day.dta", clear
outsheet using "output/approach_b_validation_28day.out", replace

*/


* Close log file
log close
