********************************************************************************
*
*	Do-file:		301_rp_b_poisson.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_noshield.dta
*					data/model_b_poisson_shield_foi.dta
*					data/model_b_poisson_shield_???.dta
*
*	Other output:	Log file:  			rp_b_poisson.log
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death. 
*
********************************************************************************



* Open a log file
capture log close
log using "./output/rp_b_poisson", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************

do "analysis/101_pr_variable_selection_output.do" 

* Pre-shielding
noi di "$predictors_preshield"

* Pre- and Post-shielding
noi di "$predictors"




********************************************************
*   Models not including measures of infection burden  *
********************************************************


use "data/cr_landmark.dta", clear


* Barlow weights used as an offset, alongside the usual offset (exposure time)
gen offset = log(dayout - dayin) + log(sf_wts)



* Model details
*	Model type: Poisson
*	Predictors: As selected by lasso etc.
*	SEs: Robust to account for patients being in multiple sub-studies
*	Sampling: Offset (log-sampling fraction) to incorporate sampling weights

* Fit model
timer clear 1
timer on 1
poisson onscoviddeath $predictors_preshield,	///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

* Pick up coefficient matrix
matrix b = e(b)

/*  Save coefficients to Stata dataset  */

do "analysis/0000_pick_up_coefficients.do"
get_coefs, coef_matrix(b) eqname("onscoviddeath") ///
	dataname("data/model_b_poisson_noshield")







****************************************************
*   Models including measures of infection burden  *
****************************************************

* WITH SHIELDING
* Use 1 April cut-off for shielding 
* Dataset has 2 lines of data per person already
* Use post-shielding set of predictors (shielding indicator + any interactions) 





/*  Measure of burden of infection:  Force of infection  */

* Measure of force of infection on the previous day
timer clear 1
timer on 1
poisson onscoviddeath $predictors		///
	foi, 											///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic


* Measure of force of infection - quadratic model of last 3 weeks
timer clear 1
timer on 1
poisson onscoviddeath $predictors		///
	foi_q_cons foi_q_day foi_q_daysq,				///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

gen logfoi = log(foi)

* Measure of force of infection on the previous day
timer clear 1
timer on 1
poisson onscoviddeath $predictors		///
	logfoi, 											///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic

gen logfoi_q_cons 	= log(foi_q_cons)
gen logfoi_q_day  	= log(foi_q_day)
gen logfoi_q_daysq 	= log(foi_q_daysq)


* Measure of force of infection - quadratic model of last 3 weeks
timer clear 1
timer on 1
poisson onscoviddeath $predictors_preshield		///
	logfoi_q_cons logfoi_q_day logfoi_q_daysq,		///
	robust cluster(patient_id) offset(offset)
timer off 1
timer list 1
estat ic



/*  Measure of burden of infection:  (?????)  */





* Close log file
log close
