********************************************************************************
*
*	Do-file:		206_rp_a_validation_28day_agesex.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH.dta
*						model_a_roy.dta
*						model_a_weibull.dta
*						model_a_ggamma.dta
*
*	Data created:	data/approach_a_validation_agesex.dta
*					output/approach_a_validation_28day_agesex.out
*
*	Other output:	Log file:  	output/206_rp_a_validation_28day_agesex.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models within groups 
*					defined by age and sex.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


* Read in output from each model

* Open a log file
capture log close
log using "./output/rp_a_validation_28day_agesex", text replace


* Ensure cc_calib is available
do "analysis/ado/cc_calib.ado"




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Cox model  */

use "data/model_a_coxPH", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_a_cox = coef[1]

* Pick up HRs
qui count
global nt_a_cox = r(N) - 1
forvalues j = 1 (1) $nt_a_cox {
	local k = `j' + 1
	global coef`j'_a_cox = coef[`k']
	global varexpress`j'_a_cox = varexpress[`k']
}


/*  Royston Parmar model */

use "data/model_a_roy", clear
drop if term == "base_surv100"  | term == "_cons" // remove base_surv100

* Pick up baseline survival
global bs_a_roy = coef[1]

qui count
global nt_a_roy = r(N) - 1
forvalues j = 1 (1) $nt_a_roy {
	local k = `j' + 1
	global coef`j'_a_roy = coef[`k']
	global varexpress`j'_a_roy = varexpress[`k']
}


/*  Weibull model  */

use "data/model_a_weibull", clear
drop if term == "base_surv100" | term == "_cons" 

* Pick up baseline survival
global bs_a_weibull = coef[1]

* Pick up HRs
qui count
global nt_a_weibull = r(N) - 1
forvalues j = 1 (1) $nt_a_weibull {
	local k = `j' + 1
	global coef`j'_a_weibull = coef[`k']
	global varexpress`j'_a_weibull = varexpress[`k']
}


/*  Generalised gamma model  */

use "data/model_a_ggamma", clear
global sigma = coef[1]
global kappa = coef[2]

di $sigma 
di $kappa
drop if _n <=2 // ie drop sigma / kappa values

qui count
global nt_a_ggamma = r(N)
forvalues j = 1 (1) $nt_a_ggamma {
	global coef`j'_a_ggamma = coef[`j']
	global varexpress`j'_a_ggamma = varexpress[`j']
	
}




******************************
*  Open validation datasets  *
******************************


forvalues i = 1/3 {

	use "data/cr_cohort_vp`i'.dta", clear
	
	
	/*  Re-group age  */
	
	recode agegroup 1/4=1 5=2 6=3, gen(agegroup_small)
	label define agegroup_small 1 "<70" 2 "70-<80" 3 "80+"
	label values agegroup_small agegroup_small
	
	
	
	* Pick up list of variables in model
	do "analysis/101_pr_variable_selection_output.do"
	noi di "$bn_terms"
	
	* Define the bn terms for Royston parmar model
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



	/*   Cox model   */

	gen xb = 0
	forvalues j = 1 (1) $nt_a_cox {
		replace xb = xb + ${coef`j'_a_cox}*${varexpress`j'_a_cox}	
	}
	gen pred_a_cox = 1 -  (${bs_a_cox})^exp(xb)
	drop xb

	/* Royston-Parmar */

	gen xb = 0
	forvalues j = 1 (1) $nt_a_roy {
	* If coefficient is NOT the constant term
	if `j' != $nt_a_roy {
		replace xb = xb + ${coef`j'_a_roy}*${varexpress`j'_a_roy}
		}

	}
	gen pred_a_roy = 1 -  (${bs_a_roy})^exp(xb)
	drop xb


	/*  Weibull */

	gen xb = 0
	forvalues j = 1 (1) $nt_a_weibull {

	* If coefficient is NOT the constant term
	if `j' != $nt_a_weibull {
		replace xb = xb + ${coef`j'_a_weibull}*${varexpress`j'_a_weibull}
		}
	}
	gen pred_a_weibull = 1 -  (${bs_a_weibull})^exp(xb)
	drop xb
	 
	 
	/* Gamma */ 

	gen xb = 0
	forvalues j = 1 (1) $nt_a_ggamma {

		* If coefficient is NOT the constant term
		if `j' != $nt_a_ggamma {
			replace xb = xb + ${coef`j'_a_ggamma}*${varexpress`j'_a_ggamma}
			}
		* Add on the constant term	
		if `j' == $nt_a_ggamma {
			replace xb = xb + ${coef`j'_a_ggamma}
		}	
	}
	gen sign = cond($kappa < 0,-1,1) 
	gen gamma = abs($kappa )^(-2)
	gen z = sign*(ln(28) - xb)/$sigma

	if $kappa == 0 {
		global surv_a_gamma = 1 - normal(z)
	}
	else {
		* s(t) = pred if k < 1
		gen surv_a_gamma = gammap(gamma, gamma*exp(abs($kappa) *z))
		* Replace s(t) = 1-pred if k > 1 
		replace surv_a_gamma = cond(sign == 1 , 1 - surv_a_gamma, surv_a_gamma)
	}

	gen pred_a_gamma = 1 - surv_a_gamma

	drop xb sign gamma z 



	
	**************************
	*   Validation measures  *
	**************************


	tempname measures
	postfile `measures' str5(approach) str30(prediction) str3(period)			///
		age sex 																///
		brier brier_p c_stat c_stat_p hl hl_p mean_obs mean_pred 				///
		calib_inter calib_inter_se calib_inter_cl calib_inter_cu calib_inter_p 	///
		calib_slope calib_slope_se calib_slope_cl calib_slope_cu calib_slope_p 	///
		using "data/approach_a_`i'_agesex", replace

		forvalues j = 0 (1) 1 {		// Sex
			forvalues k = 1 (1) 3 { 	// Age-group
				foreach var of varlist pred* {
					
					* Overall performance: Brier score
					noi brier onscoviddeath28 `var' 	///
						if agegroup_small==`k' & male==`j', group(10)
					local brier 	= r(brier) 
					local brier_p 	= r(p) 

					* Discrimination: C-statistic
					local cstat 	= r(roc_area) 
					local cstat_p 	= r(p_roc)
					 
					* Calibration
					noi cc_calib onscoviddeath28  `var'	///
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
					post `measures' ("A") ("`var'") ("vp`i'") 						///
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
use "data/approach_a_1_agesex", clear
forvalues i = 2(1)3 { 
	append using "data/approach_a_`i'_agesex" 
	erase "data/approach_a_`i'_agesex.dta" 
}
erase "data/approach_a_1_agesex.dta" 

capture label drop agegroup
label define agegroup 	1 "18-<70"	///
						2 "70-<80"	///
						3 "80+"
label values age agegroup

save "data/approach_a_validation_28day_agesex.dta", replace 




* Export a text version of the output
use "data/approach_a_validation_28day_agesex.dta", clear
outsheet using "output/approach_a_validation_28day_agesex.out", replace




* Close log file
log close





