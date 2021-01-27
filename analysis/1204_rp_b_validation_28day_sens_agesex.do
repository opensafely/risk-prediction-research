********************************************************************************
*
*	Do-file:		1204_rp_b_validation_28day_sens_agesex.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/approach_b_1_sens_agesex
*					output/approach_b_validation_28day_sens_agesex.out
*
*	Other output:	Log file:  	output/1203_rp_b_validation_28day_sens_agesex.log
*
********************************************************************************
*
*	Purpose:		This do-file compares Design B (landmark) models in terms 
*					of their predictive ability, for sensitivity analysis models
*					which are simpler than the main models.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/1204_rp_b_validation_28day_agesex", text replace




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************




/*  Age and sex only  */


foreach tvc in foi ae susp all objective {
	
	use "data/model_b_poisson_`tvc'_agesex.dta", clear

	* Pick up baseline survival
	global bs_b_pois_`tvc'_agesex = coef[1]
	
	* Pick up IRRs
	qui count
	global nt_b_pois_`tvc'_agesex = r(N) - 1
	local t = 	${nt_b_pois_`tvc'_agesex} 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global ce`j'_b_pois_`tvc'_agesex 	= coef[`k']
		global ve`j'_b_pois_`tvc'_agesex 	= varexpress[`k']	
	}
}



/*  Age, sex and number of comorbidities   */

foreach tvc in foi ae susp all objective {
	
	use "data/model_b_poisson_`tvc'_comorbid.dta", clear

	* Pick up baseline survival
	global bs_b_pois_`tvc'_comorbid = coef[1]
	
	* Pick up IRRs
	qui count
	global nt_b_pois_`tvc'_comorbid = r(N) - 1
	local t = 	${nt_b_pois_`tvc'_comorbid} 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global ce`j'_b_pois_`tvc'_comorbid 	= coef[`k']
		global ve`j'_b_pois_`tvc'_comorbid	= varexpress[`k']	
	}
}


/*  Full model no variable selection  */

foreach tvc in foi ae susp all objective {
	
	use "data/model_b_poisson_`tvc'_all.dta", clear

	* Pick up baseline survival
	global bs_b_pois_`tvc'_all = coef[1]
	
	* Pick up IRRs
	qui count
	global nt_b_pois_`tvc'_all = r(N) - 1
	local t = 	${nt_b_pois_`tvc'_all} 
	forvalues j = 1 (1) `t' {
		local k = `j' + 1
		global ce`j'_b_pois_`tvc'_all 	= coef[`k']
		global ve`j'_b_pois_`tvc'_all	= varexpress[`k']	
	}
}





******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	

	/*   Create covariates needed   */
	
	*  Re-group age  	
	recode agegroup 1/4=1 5=2 6=3, gen(agegroup_small)
	label define agegroup_small 1 "<70" 2 "70-<80" 3 "80+"
	label values agegroup_small agegroup_small
	
	* Create finer age categories
	recode age min/39  = 1	///
				40/49  = 2	///
				50/59  = 3	///
				60/64  = 4	///
				65/69  = 5	///
				70/74  = 6	///
				75/79  = 7	///
				80/84  = 8	///
				85/89  = 9	///
				90/max = 10	///
				, gen(agegroup_fine)

	label define agegroup_fine ///
				1 "<40"		///
				2 "40-49"	///
				3 "50-59"	///
				4 "60-64"	///
				5 "65-69"	///
				6 "70-74"	///
				7 "75-79"	///
				8 "80-84"	///
				9 "85-89"	///
				10 "90+"
				
	label values agegroup_fine agegroup_fine



	* Create binary indicators
	recode asthmacat 3=1 1/2=0, 		gen(asthma_sev)
	recode diabcat 2/4=1 1=0, 			gen(diabetes)
	recode cancerExhaem 2=1 1 3/4=0, 	gen(recentcanc)
	recode cancerHaem 2/3=1 1 4=0, 		gen(recenthaemcanc)
	recode kidneyfn 2/3=1 1=0, 			gen(poorkidney)
	recode obesecat 1 3/5=1 2=0, 		gen(notnormalbmi)


	* Count comorbidities
	egen num_comorbid = rowtotal(				///
				respiratory cf asthma_sev		///
				cardiac af dvt_pe pad diabetes	///
				recentcanc recenthaemcanc		///
				liver stroke dementia neuro		///
				poorkidney dialysis transplant	///
				spleen suppression hiv			///
				notnormalbmi					///
				)

	* Group number of comorbidities
	recode num_comorbid 0=0 1=1 2=2 3/max=3, gen(gp_comorbid)
	drop 	asthma_sev diabetes recentcanc recenthaemcanc poorkidney ///
			notnormalbmi num_comorbid

			
	/*  Pick up list of variables in model  */
	
	qui do "analysis/104_pr_variable_selection_landmark_output.do" 

	
	
	/*  Obtain predicted risks from each model  */
	
	foreach tvc in foi ae susp all objective {


		/*  Age and sex only  */

		gen xb = 0
		local t = ${nt_b_pois_`tvc'_agesex}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${ce`j'_b_pois_`tvc'_agesex}*${ve`j'_b_pois_`tvc'_agesex}
		}
		gen pred_b_pois_`tvc'_agesex = 1 -  ((${bs_b_pois_`tvc'_agesex})^exp(xb))^100
		drop xb


		/*  Age, sex and number of comorbidities   */

		gen xb = 0
		local t = ${nt_b_pois_`tvc'_comorbid}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${ce`j'_b_pois_`tvc'_comorbid}*${ve`j'_b_pois_`tvc'_comorbid}
		}
		gen pred_b_pois_`tvc'_comorbid = 1 -  ((${bs_b_pois_`tvc'_comorbid})^exp(xb))^100
		drop xb
		
		
		/*  Full model no variable selection  */

		gen xb = 0
		local t = ${nt_b_pois_`tvc'_all}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${ce`j'_b_pois_`tvc'_all}*${ve`j'_b_pois_`tvc'_all}
		}
		gen pred_b_pois_`tvc'_all = 1 -  ((${bs_b_pois_`tvc'_all})^exp(xb))^100
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
		using "data/approach_b_`i'_sens_agesex", replace


		forvalues j = 0 (1) 1 {		// Sex
			forvalues k = 1 (1) 3 { 	// Age-group
				foreach var of varlist pred* {
				
				* Overall performance: Brier score
				noi brier onscoviddeath28 `var' ///
						if agegroup_small==`k' & male==`j', group(10)
				local brier 	= r(brier) 
				local brier_p 	= r(p) 

				* Discrimination: C-statistic
				local cstat 	= r(roc_area) 
				local cstat_p 	= r(p_roc)
				 
				* Calibration
				noi cc_calib onscoviddeath28  `var' ///
						if agegroup_small==`k' & male==`j', data(internal) 

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
								(`k') (`j')			 							///
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
use "data/approach_b_1_sens_agesex", clear
forvalues i = 2(1)3 { 
	append using "data/approach_b_`i'_sens_agesex" 
	erase "data/approach_b_`i'_sens_agesex.dta" 
}
erase "data/approach_b_1_sens_agesex.dta" 

capture label drop agegroup
label define agegroup 	1 "18-<70"	///
						2 "70-<80"	///
						3 "80+"
label values age agegroup

save "data/approach_b_validation_28day_sens_agesex.dta", replace 




* Export a text version of the output
use "data/approach_b_validation_28day_sens_agesex.dta", clear
outsheet using "output/approach_b_validation_28day_sens_agesex.out", replace




* Close log file
log close

