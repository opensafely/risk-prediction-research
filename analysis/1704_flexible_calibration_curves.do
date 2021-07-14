********************************************************************************
*
*	Do-file:		1704_flexible_calibration_curves.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/
*						model_a_coxPH.dta
*						model_b_poisson_foi.dta
*						model_b_poisson_ae.dta
*						model_b_poisson_susp.dta
*
*	Data created:	None
*
*	Other output:	Log file:  	output/1704_flexible_calibration_curves.log
*					Graphs:		output/calibration_a.svg
*								output/calibration_b_foi.svg
*								output/calibration_b_ae.svg
*								output/calibration_b_gp.svg
*
********************************************************************************
*
*	Purpose:		This do-file obtains flexible calibration plots and decile
*					plots to graphically assess moderate calibration.
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


forvalues i = 1/3 {

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
		
		* Use as many knots as allows models to converge
		*   (problems encountered in validation period 3)
		local knots = 6
		if `i'==3 & inlist(`k', 2, 3) {
			local knots = 4
		}
		if `i'==3 & inlist(`k', 4) {
			local knots = 3
		}		
		
		mkspline logitrp = logitrp, cubic nknots(`knots')
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
		replace ptile_`k' = ptile_`k' + 1
		bysort ptile_`k': egen obsptile_`k'		= mean(onscoviddeath28)
		bysort ptile_`k': egen predmeanptile_`k'= mean(pred_model`k')

		egen tag_`k' = tag(ptile_`k')
		
		* Put all risks on % scale (for consistency with rest of paper)
		replace obsptile_`k' 		= 100*obsptile_`k'
		replace predmeanptile_`k' 	= 100*predmeanptile_`k'
		
		replace flex_pred_obs_`k'		= 100*flex_pred_obs_`k'
		replace flex_pred_obs_cl_`k' 	= 100*flex_pred_obs_cl_`k' 
		replace flex_pred_obs_cu_`k' 	= 100*flex_pred_obs_cu_`k' 
 
		replace pred_model`k' = 100*pred_model`k'
	}
		
	
	/*  Graph: Approach A - Cox model  */
	
	* Flexible curve
	qui sum pred_model1 if rowuse_1==1
	local max = r(max)
	sort pred_model1
	twoway 	(rarea flex_pred_obs_cl_1 flex_pred_obs_cu_1 pred_model1, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_1 pred_model1, lcolor(gs3))				///
			(function y=x, lcolor(black) lpattern(dot) range(0 `max'))	///
			if rowuse_1==1,												///
			xtitle("")													///
			ytitle("")													///
			legend(order(2 1 3) label(2 "Flexible curve (splines)") 	///
			label(1 "Pointwise 95% CI") label(3 "Line of equality") 	///
			colfirst)													///
			subtitle("VP `i'")
	graph save output/flex1_`i', replace
	
	* Boxplot
	sort ptile_1
	twoway 	(scatter predmeanptile_1 ptile_1, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_1 ptile_1, mcolor(green) msymbol(triangle))	///
			if tag_1==1, legend(order(1 2)  label(1 "Predicted (mean)") 	///
			label(2 "Observed") colfirst)									///
			xtitle("") xlabel(5 (5) 20)	xmtick(1 (1) 20)					///
			subtitle("VP `i'")
	graph save output/box1_`i', replace

	
	
	/*  Graph: Approach B - FOI model  */
	
	* Flexible curve
	qui sum pred_model2 if rowuse_2==1
	local max = r(max)
	sort pred_model2
	twoway 	(rarea flex_pred_obs_cl_2 flex_pred_obs_cu_2 pred_model2, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_2 pred_model2, lcolor(gs3))				///
			(function y=x, lcolor(black) lpattern(dot) range(0 `max'))	///
			if rowuse_2==1,												///
			xtitle("")													///
			ytitle("")													///
			legend(order(2 1 3) label(2 "Flexible curve (splines)") 	///
			label(1 "Pointwise 95% CI") label(3 "Line of equality") 	///
			colfirst)													///
			subtitle("VP `i'")	
	graph save output/flex2_`i', replace
	
	* Boxplot
	sort ptile_2
	twoway 	(scatter predmeanptile_2 ptile_2, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_2 ptile_2, mcolor(green) msymbol(triangle))	///
			if tag_2==1, legend(order(1 2)  label(1 "Predicted (mean)") 	///
			label(2 "Observed") colfirst)									///
			xtitle("") xlabel(5 (5) 20)	xmtick(1 (1) 20)					///
			subtitle("VP `i'")
	graph save output/box2_`i', replace
	
	
	/*  Graph: Approach B - A&E model  */
	
	* Flexible curve
	qui sum pred_model3 if rowuse_3==1
	local max = r(max)	
	sort pred_model3
	twoway 	(rarea flex_pred_obs_cl_3 flex_pred_obs_cu_3 pred_model3, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_3 pred_model3, lcolor(gs3))				///
			(function y=x, lcolor(black) lpattern(dot) range(0 `max'))	///
			if rowuse_3==1,												///
			xtitle("")													///
			ytitle("")													///
			legend(order(2 1 3) label(2 "Flexible curve (splines)") 	///
			label(1 "Pointwise 95% CI") label(3 "Line of equality") 	///
			colfirst)													///
			subtitle("VP `i'")
	graph save output/flex3_`i', replace
		
	* Boxplot
	sort ptile_3
	twoway 	(scatter predmeanptile_3 ptile_3, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_3 ptile_3, mcolor(green) msymbol(triangle))	///
			if tag_3==1, legend(order(1 2)  label(1 "Predicted (mean)") 	///
			label(2 "Observed") colfirst)									///
			xtitle("") xlabel(5 (5) 20)	xmtick(1 (1) 20)					///
			subtitle("VP `i'")
	graph save output/box3_`i', replace

	
	
	/*  Graph: Approach B - GP cases model  */
	
	* Flexible curve
	qui sum pred_model4 if rowuse_4==1
	local max = r(max)
	sort pred_model4
	twoway 	(rarea flex_pred_obs_cl_4 flex_pred_obs_cu_4 pred_model4, 	///
			fcolor(gs13) lcolor(gs8)) 									///
			(line flex_pred_obs_4 pred_model4, lcolor(gs3))				///
			(function y=x, lcolor(black) lpattern(dot) range(0 `max'))	///
			if rowuse_4==1,												///
			xtitle("")													///
			ytitle("")													///
			legend(order(2 1 3) label(2 "Flexible curve (splines)") 	///
			label(1 "Pointwise 95% CI") label(3 "Line of equality") 	///
			colfirst)													///
			subtitle("VP `i'")
	graph save output/flex4_`i', replace

	* Boxplot
	sort ptile_4
	twoway 	(scatter predmeanptile_4 ptile_4, mcolor(navy) mlcolor(navy))	///
			(scatter obsptile_4 ptile_4, mcolor(green) msymbol(triangle))	///
			if tag_4==1, legend(order(1 2)  label(1 "Predicted (mean)") 	///
			label(2 "Observed") colfirst)									///
			xtitle("") xlabel(5 (5) 20)	xmtick(1 (1) 20)					///
			subtitle("VP `i'")
	graph save output/box4_`i', replace

	
}


/*  Combine graphs across validation periods  */

adopath ++ analysis/ado


* Approach A
grc1leg output/box1_1.gph  output/box1_2.gph  output/box1_3.gph, 		///
	col(3) b1title("Predicted risk (20 groups)")						///
	l1title("Observed risk") ring(100)
graph save output/box1, replace 

grc1leg  output/flex1_1.gph output/flex1_2.gph output/flex1_3.gph, 		///
	col(3) b1title("Predicted risk")									///
	l1title("Observed risk") ring(100)
graph save output/flex1, replace 

graph combine output/flex1.gph output/box1.gph, col(1)
graph export output/calibration_a.svg, replace as(svg)




* Approach B (FOI)
grc1leg output/box2_1.gph  output/box2_2.gph  output/box2_3.gph, 		///
	col(3) b1title("Predicted risk (20 groups)")						///
	l1title("Observed risk") ring(100)
graph save output/box2, replace 

grc1leg output/flex2_1.gph output/flex2_2.gph output/flex2_3.gph, 		///
	col(3) b1title("Predicted risk")									///
	l1title("Observed risk") ring(100)
graph save output/flex2, replace 

graph combine output/flex2.gph output/box2.gph, col(1)
graph export output/calibration_b_foi.svg, replace as(svg)


* Approach B (AE)
grc1leg output/box3_1.gph  output/box3_2.gph  output/box3_3.gph, 		///
	col(3) b1title("Predicted risk (20 groups)")						///
	l1title("Observed risk") ring(100)
graph save output/box3, replace 

grc1leg output/flex3_1.gph output/flex3_2.gph output/flex3_3.gph,	 	///
	col(3) b1title("Predicted risk")									///
	l1title("Observed risk") ring(100)
graph save output/flex3, replace 

graph combine output/flex3.gph output/box3.gph, col(1)
graph export output/calibration_b_ae.svg, replace as(svg)


* Approach B (GP)
grc1leg output/box2_1.gph  output/box4_2.gph  output/box4_3.gph, 		///
	col(3) b1title("Predicted risk (20 groups)")						///
	l1title("Observed risk") ring(100)
graph save output/box4, replace 

grc1leg output/flex4_1.gph output/flex4_2.gph output/flex4_3.gph, 		///
	col(3) b1title("Predicted risk")									///
	l1title("Observed risk") ring(100)
graph save output/flex4, replace 

graph combine output/flex4.gph output/box4.gph, col(1)
graph export output/calibration_b_gp.svg, replace as(svg)



/*  Erase unneeded graphs  */

forvalues k = 1/4 {
	forvalues i = 1/3 {
		erase output/box`k'_`i'.gph 
		erase output/flex`k'_`i'.gph 
	}
	erase output/box`k'.gph 
	erase output/flex`k'.gph 
}





* Close log file
log close



