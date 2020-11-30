********************************************************************************
*
*	Do-file:		602_rp_b_weibull_intext.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_weibull_`tvc'_`r'.dta, where tvc=foi, ae, susp
*									and r=1, 2, 3, ..., 8
*
*	Other output:	Log file:  		output/602_rp_b_weibull_intext_`tvc'.log
*
********************************************************************************
*
*	Purpose:		This do-file fits Weibull regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases, for the internal-external
*					validation (leaving out one region at a time, then 
* 					omitting the later time period). 
*
********************************************************************************





* Specify the time-varying measures: foi, ae or susp
local tvc `1' 
noi di "`tvc'"



* Open a log file
capture log close
log using "./output/602_rp_b_weibull_intext_`tvc'", text replace




*******************************
*  Pick up predictor list(s)  *
*******************************


qui do "analysis/104_pr_variable_selection_landmark_output.do" 
noi di "${selected_vars_landmark_`tvc'}"


* Cycle over regions & time
forvalues r = 1 (1) 8 {
	


		
	************************************
	*  Open dataset for model fitting  *
	************************************

		
	* Open landmark data
	use "data/cr_landmark.dta", clear
	
	
	* Delete one region 
	if `r'<8 {
		drop if region_7==`r'
	}
	if `r'==8 { // Analyse only data in period: 1 March-11 May (first 45 landmark sub-studies)
		drop if time>45
	}

	


	/*  Create time-varying variables needed  */

	* Variables needed for force of infection data

	gen logfoi = log(foi)
	gen foiqd  =  foi_q_day/foi_q_cons
	gen foiqds =  foi_q_daysq/foi_q_cons


	* Variables needed for A&E attendance data
	gen aepos = aerate
	qui summ aerate if aerate>0 
	replace aepos = aepos + r(min)/2 if aepos==0

	gen logae		= log(aepos)
	gen aeqd		= ae_q_day/ae_q_cons
	gen aeqds 		= ae_q_daysq/ae_q_cons

	replace aeqd  = 0 if ae_q_cons==0
	replace aeqds = 0 if ae_q_cons==0

	gen aeqint 		= aeqd*aeqds
	gen aeqd2		= aeqd^2
	gen aeqds2		= aeqds^2


	* Variables needed for GP suspected case data

	gen susppos = susp_rate
	qui summ susp_rate if susp_rate>0 
	replace susppos = susppos + r(min)/2 if susppos==0

	* Create time variables to be fed into the variable selection process
	gen logsusp	 	= log(susppos)
	gen suspqd	 	= susp_q_day/susp_q_cons
	gen suspqds 	= susp_q_daysq/susp_q_cons

	replace suspqd  = 0 if susp_q_cons==0
	replace suspqds = 0 if susp_q_cons==0

	gen suspqint   	= suspqd*suspqds
	gen suspqd2 	= suspqd^2
	gen suspqds2	= suspqds^2




	********************
	*   Weibull Model  *
	********************


	* Fit model
	timer clear 1
	timer on 1
	streg ${selected_vars_landmark_`tvc'}, dist(weibull) ///
		robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1





	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************


	* Pick up coefficient matrix
	matrix b = e(b)

	*  Calculate baseline survival 
	local p = exp(_b[/:ln_p])
	global base_surv28 = exp(-1*(28^(`p'))*exp(_b[_cons]))


	* Add baseline survival to matrix (and add a matrix column name)
	matrix b = [$base_surv28, b]
	local names: colfullnames b
	local names: subinstr local names "c1" "_t:base_surv28"
	mat colnames b = `names'

	* Remove unneeded parameters from matrix
	local np = colsof(b) - 1
	matrix b = b[1,1..`np']
	matrix list b

	*  Save coefficients to Stata dataset  
	qui do "analysis/0000_pick_up_coefficients.do"

	* Save coeficients needed for prediction

	get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
		dataname("data/model_b_weibull_`tvc'_`r'")

}

* Close log file
log close
