********************************************************************************
*
*	Do-file:		1704_flexible_calibration_curves.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH.dta
*						model_a_roy.dta
*						model_a_weibull.dta
*						model_a_ggamma.dta
*
*	Data created:	data/approach_a_validation.dta
*					output/approach_a_validation_28day.out
*
*	Other output:	Log file:  	output/1704_flexible_calibration_curves.log
*					
********************************************************************************
*
*	Purpose:		This do-file compares Design A models.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


* Read in output from each model

* Open a log file
capture log close
log using "./output/1704_flexible_calibration_curves", text replace




******************************************************
*   Pick up coefficients needed to make predictions  *
******************************************************


/*  Approach A: Cox model  */

use "data/model_a_coxPH", clear
drop if term == "base_surv100" // remove base_surv100

* Pick up baseline survival
global bs_a_cox_nos = coef[1]

* Pick up HRs
qui count
global nt_a_cox_nos = r(N) - 1
forvalues j = 1 (1) $nt_a_cox_nos {
	local k = `j' + 1
	global coef`j'_a_cox_nos = coef[`k']
	global varexpress`j'_a_cox_nos = varexpress[`k']
}




/*  Approach B: Poisson regression models  */


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





******************************
*  Open validation datasets  *
******************************


*forvalues i = 1/3 {
local i = 1
	use "data/cr_cohort_vp`i'.dta", clear
	

	/*   Approach A: Cox model   */
	
	* Pick up list of variables in model
	qui do "analysis/101_pr_variable_selection_output.do"
	
	gen xb = 0
	forvalues j = 1 (1) $nt_a_cox_nos {
		replace xb = xb + ${coef`j'_a_cox_nos}*${varexpress`j'_a_cox_nos}	
	}
	gen pred_a_cox_nos = 1 -  (${bs_a_cox_nos})^exp(xb)
	drop xb
	

	/*  Approach B: Poisson model  */

	* Pick up list of variables in model
	qui do "analysis/104_pr_variable_selection_landmark_output.do" 
	
	foreach tvc in foi ae susp {
		gen xb = 0
		local t = ${nt_b_pois_`tvc'}
		forvalues j = 1 (1) `t' {
			replace xb = xb + ${coef`j'_b_pois_`tvc'}*${varexpress`j'_b_pois_`tvc'}
		}
		gen pred_b_pois_`tvc' = 1 -  (${bs_b_pois_`tvc'})^exp(xb)
		drop xb
	}
	
	
	
	**************************
	*   Validation measures  *
	**************************

	rename pred_a_cox_nos 	pred_model1
	rename pred_b_pois_foi 	pred_model2
	rename pred_b_pois_ae 	pred_model3
	rename pred_b_pois_susp pred_model4
	
	forvalues k = 1 (1) 4 {
		
		* Flexible modelling
		gen logitrp = log(pred_model`k'/(1-pred_model`k'))
		mkspline logitrp = logitrp, cubic nknots(7)
		logit onscoviddeath28 logitrp?
		
		predict xbhat, xb
		predict xbse, stdp
		
		gen xbhat_cu = xbhat + 1.96*xbse
		gen xbhat_cl = xbhat - 1.96*xbse

		gen flex_pred_obs_`k' 		= exp(xbhat)/(1+exp(xbhat))
		gen flex_pred_obs_cl_`k' 	= exp(xbhat_cl)/(1+exp(xbhat_cl))
		gen flex_pred_obs_cu_`k' 	= exp(xbhat_cu)/(1+exp(xbhat_cu))

		drop xbhat* xbse logitrp*
		
		sort flex_pred_obs_`k'
		gen rowuse_`k' = mod(_n, 200000)
		recode rowuse_`k' 0=1 1/max=0
		
		
		* Percentiles
		egen ptile_`k' = cut(pred_model`k'), group(20)
		bysort ptile_`k': egen obsptile_`k'=mean(onscoviddeath28)
		bysort ptile_`k': egen predmedptile_`k'=median(pred_model`k')
		bysort ptile_`k': egen predq25ptile_`k'=pctile(pred_model`k'), p(25)
		bysort ptile_`k': egen predq75ptile_`k'=pctile(pred_model`k'), p(75)
		
	}
		
	
	/*  Graph: Approach A - Cox model  */
	
	* Flexible curve
	sort pred_model1
	twoway 	(rarea flex_pred_obs_cl_1 flex_pred_obs_cu_1 pred_model1, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_1 pred_model1, lcolor(gs3))				///
			if rowuse_1==1,												///
			xtitle("Predicted")											///
			ytitle("Observed")											///
			legend(off) title("Approach A (Cox)")
	
	* Boxplot
	sort ptile_1
	twoway 	(rcap predq25ptile_1 predq75ptile_1 ptile_1, lcolor(navy))		///
			(scatter predmedptile_1 ptile_1, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_1 ptile_1, mcolor(green) msymbol(triangle))	///
			, legend(order(2 1 3)  label(2 "Predicted (median)") 			///
			label(1 "(25th-75th percentile)") label(3 "Observed") colfirst)
	
	
	
	/*  Graph: Approach B - FOI model  */
	
	* Flexible curve
	sort pred_model2
	twoway 	(rarea flex_pred_obs_cl_2 flex_pred_obs_cu_2 pred_model2, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_2 pred_model2, lcolor(gs3))				///
			if rowuse_2==1,												///
			xtitle("Predicted")											///
			ytitle("Observed")											///
			legend(off) title("Approach B (FOI, Poisson)")
	
	* Boxplot
	sort ptile_4
	twoway 	(rcap predq25ptile_2 predq75ptile_2 ptile_2, lcolor(navy))		///
			(scatter predmedptile_2 ptile_2, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_2 ptile_2, mcolor(green) msymbol(triangle))	///
			, legend(order(2 1 3)  label(2 "Predicted (median)") 			///
			label(1 "(25th-75th percentile)") label(3 "Observed") colfirst)	///
			title("Approach B (FOI, Poisson)")	
	
	
	/*  Graph: Approach B - FOI model  */
	
	* Flexible curve
	sort pred_model3
	twoway 	(rarea flex_pred_obs_cl_3 flex_pred_obs_cu_3 pred_model3, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_3 pred_model3, lcolor(gs3))				///
			if rowuse_3==1,												///
			xtitle("Predicted")											///
			ytitle("Observed")											///
			legend(off) title("Approach B (A&E, Poisson)")
		
	* Boxplot
	sort ptile_3
	twoway 	(rcap predq25ptile_3 predq75ptile_3 ptile_3, lcolor(navy))		///
			(scatter predmedptile_3 ptile_3, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_3 ptile_3, mcolor(green) msymbol(triangle))	///
			, legend(order(2 1 3)  label(2 "Predicted (median)") 			///
			label(1 "(25th-75th percentile)") label(3 "Observed") colfirst)	///
			title("Approach B (A&E, Poisson)")
	
	
	
	/*  Graph: Approach B - FOI model  */
	
	* Flexible curve
	sort pred_model4
	twoway 	(rarea flex_pred_obs_cl_4 flex_pred_obs_cu_4 pred_model4, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_4 pred_model4, lcolor(gs3))				///
			if rowuse_4==1,												///
			xtitle("Predicted")											///
			ytitle("Observed")											///
			legend(off) title("Approach B (GP, Poisson)")

	* Boxplot
	sort ptile_4
	twoway 	(rcap predq25ptile_4 predq75ptile_4 ptile_4, lcolor(navy))		///
			(scatter predmedptile_4 ptile_4, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_4 ptile_4, mcolor(green) msymbol(triangle))	///
			, legend(order(2 1 3)  label(2 "Predicted (median)") 			///
			label(1 "(25th-75th percentile)") label(3 "Observed") colfirst)	///
			title("Approach B (GP, Poisson)")
	
	
*}





* Close log file
log close




