********************************************************************************
*
*	Do-file:		403_rp_infection_measures.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/
*						ci_coefs_`tvc'.dta
*						cii_coefs_`tvc'.dta
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
log using "./output/403_rp_infection_measures", text replace




*************************************************************
*   Variables relating to the burden of COVID-19 infection  *
*************************************************************

global tvc_foi  = "logfoi foi_q_day foi_q_daysq foiqd foiqds" 
global tvc_ae   = "logae ae_q_day ae_q_daysq aeqd aeqds aeqds2"
global tvc_susp = "logsusp susp_q_day susp_q_daysq suspqd suspqds suspqds2"




********************************************************************************
*  Extract coefficients for burden of infection proxies from predictive models *
********************************************************************************

/*  Time-split 28-day landmark studies  */

foreach tvc in foi ae susp {

	use "data/model_ci_`tvc'.dta", clear
	
	* Save coefficients for time-varying measures of infection
	gen temp = 0
	local searchlist = "${tvc_`tvc'}" 
	foreach term in `searchlist' {
		replace temp = 1 if regexm(term, "`term'")
	}
	keep if temp==1

	* Put in dataset with variables containing the TVC coefficients
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

	* Create one row per relevant day (t=1, 8, 15, and 22) 
	* for merging onto a 28-day dataset
	expand 4
	gen t = (_n-1)*7 + 1
	save "data/ci_coefs_`tvc'", replace	
}



/*  Daily landmark studies - COVID models */

foreach tvc in foi ae susp {

	use "data/model_cii_covid_`tvc'.dta", clear
	
	* Save coefficients for time-varying measures of infection
	gen temp = 0
	local searchlist = "${tvc_`tvc'}" 
	foreach term in `searchlist' {
		replace temp = 1 if regexm(term, "`term'")
	}
	keep if temp==1

	* Put in dataset with variables containing the TVC coefficients
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
	* Create one row per day (t=1 to 28) for merging onto a 28-day dataset
	expand 28
	gen t = _n
	save "data/cii_coefs_`tvc'", replace	
}


		
		
		




*******************************************************************
*   Obtain quadratic coefficients of burden of infection proxies  *
*******************************************************************

*** In each case, under three scenarios:
*		Actual
*		Assuming proxy remains constant from day 1 of the validation period
*		"Best guess" given data until day 1 of the validation period

* Dates of day 1 of the validation periods
local start_vp1 = d(01/03/2020)  
local start_vp2 = d(06/04/2020)  
local start_vp3 = d(12/05/2020) 

* Variables within which proxies are measured
local matching_vars_foi  = "region_7 agegroupfoi" 
local matching_vars_ae   = "stp_combined" 
local matching_vars_susp = "stp_combined" 



***********************************************
*  Program: Impose constant-value assumption  *
***********************************************

* This program uses a constant-value assumption to fill in variables 
* foi, ae, or susp in the validation period
capture program drop pred_cons
program define pred_cons

	syntax , tvc(string) date(varname) startdate(real) matchingvars(varlist)

	* Replace with missing values after first date of validation period
	replace `tvc' = . if `date' > `startdate'

	* Assume proxy remains constant during validation period
	bysort `matchingvars' (`date'): replace `tvc' = `tvc'[_n-1] if `tvc' == .

end



********************************************************************
*  Program: Use fractional polynomials to predict infection proxy  *
********************************************************************

* This program uses fractional polynomials to fill in variables 
* foi, ae, or susp in the validation period
capture program drop pred_fp
program define pred_fp

	syntax , tvc(string) date(varname) startdate(real) matchingvars(varlist)

	* Replace with missing values after first date of validation period
	replace `tvc' = . if `date' > `startdate'

	* Deal with only zero values
	qui summ `tvc' 
	if r(max)==0 {
	    replace `tvc' = 0 if `tvc'==.
	}
	else {
		* Weight observations so more recent ones count more (Gaussian weights)
		tempvar day weight 
		gen `day' = `date' - (`startdate' - 21) + 1
		gen `weight' = exp(-((`day' - 21)/(21/2))^2/2)/(2*_pi)
		
		* Cycle over the categories within which the proxy is constant
		tempvar gp
		egen `gp' = group(`matchingvars')
		qui summ `gp'
		local ngp = r(max)
		
		forvalues j = 1 (1) `ngp' {
			fp <`day'>, replace all: ///
				regress `tvc' <`day'>  [pweight=`weight']	///
				if `gp'==`j'
			predict temp
			replace `tvc' = temp if `gp'==`j' & `tvc'==.
			drop temp
		}
	}
end





*************************************************************
*  Obtain quadratic coefficients under various predictions  *
*************************************************************

foreach tvc in foi ae susp  {
	forvalues i = 1 (1) 3 {		
		foreach pred in actual cons pred {
			use "data/`tvc'_rates", clear
			capture drop day
			
			* We need the quadratic coefficients for days 1 to 28 for this validation period
			drop if date < `start_vp`i'' - 21
			drop if date > `start_vp`i'' + 28

			if "`tvc'"=="ae" {
				rename aerate ae
			}
			else if "`tvc'"=="susp" {
				rename susp_rate susp
			}
			
			* Predict FOI, if using other than actual data
			if "`pred'"=="cons" {
				pred_cons, tvc(`tvc') date(date)	///
					startdate(`start_vp`i'') 		///
					matchingvars(`matching_vars_`tvc'')	
			}
			if "`pred'"=="pred" {
				pred_fp, tvc(`tvc') date(date) 		///
					startdate(`start_vp`i'') 		///
					matchingvars(`matching_vars_`tvc'')	
			}	
			
			* Create lagged variables over last 21 days
			rename `tvc' `tvc'_lag
			forvalues t = 1 (1) 21 {
				bysort `matching_vars_`tvc'' (date): ///
					gen `tvc'_lag`t' = `tvc'_lag[_n-`t']
			}
			rename `tvc'_lag `tvc'_lag0

			* Only keep dates from (day before) first day of validation period onwards
			drop if date < `start_vp`i'' - 1


			/*  Fit quadratic model to force of infection data  */

			* Fit quadratic model to infection proportion over last "lag" days
			gen `tvc'_init = `tvc'_lag0
			reshape long `tvc'_lag, ///
				i(date `matching_vars_`tvc'' `tvc'_init) j(lag)
			replace lag = -lag
			statsby `tvc'_`pred'_q_cons	= _b[_cons] 					///
					`tvc'_`pred'_q_day	=_b[lag] 						///
					`tvc'_`pred'_q_daysq	=_b[c.lag#c.lag]	 		///
					, by(`matching_vars_`tvc'' date `tvc'_init) clear: 	///
				regress `tvc'_lag c.lag##c.lag	
			rename `tvc'_init `tvc'_`pred'
			
	
			*  Days since cohort start date  
			gen time = date - `start_vp`i'' + 2
			keep if inrange(time, 1, 28)
			
			save "data/quadcoefs_`tvc'_`pred'_vp`i'", replace
		}
	}
}	




***************************************************************
*  Combine coefficients for each proxy and validation period  *
***************************************************************

* Combine
foreach tvc in foi ae susp {
	forvalues i = 1 (1) 3 {	
		use "data/quadcoefs_`tvc'_actual_vp`i'", clear
		merge 1:1 `matching_vars_`tvc'' date using	///
			"data/quadcoefs_`tvc'_cons_vp`i'", 		///
			assert(match) nogen
		merge 1:1 `matching_vars_`tvc'' date using 	///
			"data/quadcoefs_`tvc'_pred_vp`i'", 		///
			assert(match) nogen
		drop date
		save "data/quadmodel_`tvc'_vp`i'", replace
	}
}

* Delete unneeded datasets
foreach tvc in foi ae susp {
	forvalues i = 1 (1) 3 {	
		erase "data/quadcoefs_`tvc'_actual_vp`i'.dta"
		erase "data/quadcoefs_`tvc'_cons_vp`i'.dta"
		erase "data/quadcoefs_`tvc'_pred_vp`i'.dta"
	}
}

	


*************************************************************
*  Create required functions of infection proxy variables   *
*************************************************************

foreach tvc in foi ae susp { 
	forvalues i = 1 (1) 3 {	
		use "data/quadmodel_`tvc'_vp`i'", replace

		foreach pred in actual cons pred {		
			gen `tvc'pos_`pred' = `tvc'_`pred'
			if "`tvc'"=="ae" {
				* Manual correction factor for zero A&E rates 
				replace aepos_`pred' = .0299034/2 if aepos_`pred'<=0
			}
			if "`tvc'"=="susp" {
				* Manual correction factor for zero primary care rates 
				replace susppos_`pred' = .0042719/2 if susppos_`pred'<=0
			}
			if "`tvc'"=="foi" {
			    * Manual correction factor for FOI negative/zero rates 
				replace `tvc'pos_`pred' = 0.0000000001 if `tvc'pos_`pred'<=0
			}
			assert `tvc'pos_`pred'>0
			
			gen log`tvc'_`pred'	= log(`tvc'pos_`pred')
			gen `tvc'qd_`pred'	= `tvc'_`pred'_q_day/`tvc'_`pred'_q_cons
			gen `tvc'qds_`pred' = `tvc'_`pred'_q_daysq/`tvc'_`pred'_q_cons

			replace `tvc'qd_`pred'  = 0 if `tvc'_`pred'_q_cons==0
			replace `tvc'qds_`pred' = 0 if `tvc'_`pred'_q_cons==0

			gen `tvc'qint_`pred' 	= `tvc'qd_`pred'*`tvc'qds_`pred'
			gen `tvc'qd2_`pred'		= `tvc'qd_`pred'^2
			gen `tvc'qds2_`pred'	= `tvc'qds_`pred'^2			
		}
		save "data/quadmodel_`tvc'_vp`i'", replace
	}
}




****************************************************************
*   Obtain covariate summaries required for prediction models  *
****************************************************************


/*  Time-split 28-day landmark studies  */

foreach tvc in foi ae susp { 
	forvalues i = 1 (1) 3 {	
   		use "data/quadmodel_`tvc'_vp`i'", clear
		rename time t
		merge m:1 t using "data/ci_coefs_`tvc'", 	///
			assert(match master) keep(match) nogen

		* If last coefficient doesn't exist set it to zero (for FOI)
		capture gen coef_`tvc'qds2 = 0

		foreach pred in actual cons pred {
			gen xb_`pred' =											///
						coef_log`tvc'*log`tvc'_`pred'			+	///
						coef_`tvc'_q_day*`tvc'_`pred'_q_day 	+	///
						coef_`tvc'_q_daysq*`tvc'_`pred'_q_daysq	+	///
						coef_`tvc'qd*`tvc'qd_`pred'				+ 	///
						coef_`tvc'qds*`tvc'qds_`pred'			+ 	///
						coef_`tvc'qds2*`tvc'qds2_`pred'
			gen exp_`pred' = exp(xb_`pred')
			drop xb_`pred'
		}
		
		* Sum over four relevant follow-up days
		collapse (sum) exp_actual exp_cons exp_pred, by(`matching_vars_`tvc'')

		* Save data
		save "data/sumxb_ci_`tvc'_vp`i'", replace
	}
}


/*  Daily landmark studies - COVID models */
 

foreach tvc in foi ae susp { 
	forvalues i = 1 (1) 3 {	

	use "data/quadmodel_`tvc'_vp`i'", clear
		rename time t
		merge m:1 t using "data/cii_coefs_`tvc'", 	///
			assert(match master) keep(match) nogen

		* If last coefficient doesn't exist set it to zero (for FOI)
		capture gen coef_`tvc'qds2 = 0

		foreach pred in actual cons pred {
			gen xb_`pred' =											///
						coef_log`tvc'*log`tvc'_`pred'			+	///
						coef_`tvc'_q_day*`tvc'_`pred'_q_day 	+	///
						coef_`tvc'_q_daysq*`tvc'_`pred'_q_daysq	+	///
						coef_`tvc'qd*`tvc'qd_`pred'				+ 	///
						coef_`tvc'qds*`tvc'qds_`pred'			+ 	///
						coef_`tvc'qds2*`tvc'qds2_`pred'
			gen exp_`pred' = exp(xb_`pred')
			drop xb_`pred'
		}
		
		* Create cumulative sums
		keep t `matching_vars_`tvc'' exp_actual exp_cons exp_pred
		foreach pred in actual cons pred {
			bysort `matching_vars_`tvc'' (t): gen cumsum_exp_`pred' = sum(exp_`pred')
		}
		reshape wide 	exp_actual exp_cons exp_pred 						///
						cumsum_exp_actual cumsum_exp_cons cumsum_exp_pred, 	///
						i(`matching_vars_`tvc'') j(t)
		
		isid `matching_vars_`tvc''

		* Save data
		save "data/sumxb_cii_`tvc'_vp`i'", replace
	}
}




* Erase unneeded datasets
foreach tvc in foi ae susp { 
	forvalues i = 1 (1) 3 {	
		erase "data/quadmodel_`tvc'_vp`i'.dta"
	}
}







* Close log file
log close
