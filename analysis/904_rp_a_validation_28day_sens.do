********************************************************************************
*
*	Do-file:		904_rp_a_validation_28day_sens.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH_agesex.dta
*						model_a_coxPH_comorbid.dta
*						model_a_coxPH_all.dta
*						model_a_coxPH_all2.dta
*
*	Data created:	data/approach_a_validation_sens.dta
*					output/approach_a_validation_28day_sens.out
*
*	Other output:	Log file:  	output/904_rp_a_validation_28day_sens.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models in various sensitivity
*					analyses (all using Cox models):
*						- age and sex only
*						- age, sex, ethnicity, rural and number of comorbidities
*						- COVID Age
*						- richer model (including additional categories)
*						- full model (no variable selection)
*  
********************************************************************************


* Read in output from each model

* Open a log file
capture log close
log using "./output/904_rp_a_validation_28day_sens", text replace


* Ensure programs cc_calib and covidage are available
qui do "analysis/ado/cc_calib.ado"
qui do "analysis/0000_calculate_COVIDage.do"



******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Age and sex only  */

use "data/model_a_coxPH_agesex", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_agesex = coef[1]

* Pick up HRs
qui count
global nt_agesex = r(N) - 1
forvalues j = 1 (1) $nt_agesex {
	local k = `j' + 1
	global coef`j'_agesex		= coef[`k']
	global varexpress`j'_agesex = varexpress[`k']
}


/*  Age, sex and number of comorbidities   */

use "data/model_a_coxPH_comorbid", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_comorbid = coef[1]

* Pick up HRs
qui count
global nt_comorbid = r(N) - 1
forvalues j = 1 (1) $nt_comorbid {
	local k = `j' + 1
	global coef`j'_comorbid			= coef[`k']
	global varexpress`j'_comorbid 	= varexpress[`k']
}


/*  Slightly richer model (all selected, with full categories)  */

use "data/model_a_coxPH_all", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_all = coef[1]

* Pick up HRs
qui count
global nt_all = r(N) - 1
forvalues j = 1 (1) $nt_all {
	local k = `j' + 1
	global coef`j'_all			= coef[`k']
	global varexpress`j'_all 	= varexpress[`k']
}



/*  Full model no variable selection  */

use "data/model_a_coxPH_all2", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_all2 = coef[1]

* Pick up HRs
qui count
global nt_all2 = r(N) - 1
forvalues j = 1 (1) $nt_all2 {
	local k = `j' + 1
	global coef`j'_all2			= coef[`k']
	global varexpress`j'_all2 	= varexpress[`k']
}







******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	
	
	/*   Create covariates needed   */

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


	
	/*   Cox model: Age and sex only   */

	gen xb = 0
	forvalues j = 1 (1) $nt_agesex {
		replace xb = xb + ${coef`j'_agesex}*${varexpress`j'_agesex}	
	}
	gen pred_agesex = 1 -  (${bs_agesex})^exp(xb)
	drop xb


	/*   Cox model: Age and sex and comorbidities   */

	gen xb = 0
	forvalues j = 1 (1) $nt_comorbid {
		replace xb = xb + ${coef`j'_comorbid}*${varexpress`j'_comorbid}	
	}
	gen pred_comorbid = 1 -  (${bs_comorbid})^exp(xb)
	drop xb
	
	
	/*  COVID-Age  */

	covidage
	* Creates new variable: covid_age
	* 85+ = very high, 70+ = high
	gen pred_covidage = (covid_age>=85)

	* Scale covidage to be between 0 and 1
	qui sum covid_age
	replace covid_age = covid_age/r(max)


	/*   Cox model: Richer model (all categories)   */

	gen xb = 0
	forvalues j = 1 (1) $nt_all {
		replace xb = xb + ${coef`j'_all}*${varexpress`j'_all}	
	}
	gen pred_all = 1 -  (${bs_all})^exp(xb)
	drop xb
	
	
	/*   Cox model: Full model (no variable selection)   */

	gen xb = 0
	forvalues j = 1 (1) $nt_all2 {
		replace xb = xb + ${coef`j'_all2}*${varexpress`j'_all2}	
	}
	gen pred_all2 = 1 -  (${bs_all2})^exp(xb)
	drop xb
	

	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_a_`i'_sens", replace

		foreach var of varlist pred* covid_age {
			
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
			post `measures' ("A") ("`var'") ("vp`i'") (`brier') (`brier_p') ///
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
use "data/approach_a_1_sens", clear
forvalues i = 2(1)3 { 
	append using "data/approach_a_`i'_sens" 
	erase "data/approach_a_`i'_sens.dta" 
}
erase "data/approach_a_1_sens.dta" 
save "data/approach_a_validation_28day_sens.dta", replace 



* Export a text version of the output
use "data/approach_a_validation_28day_sens.dta", clear
outsheet using "output/approach_a_validation_28day_sens.out", replace




* Close log file
log close







