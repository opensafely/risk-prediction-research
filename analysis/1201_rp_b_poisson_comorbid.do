********************************************************************************
*
*	Do-file:		1201_rp_b_poisson_comorbid.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_`tvc'_comorbid.dta, 
*						where tvc=foi, ae, susp, all, objective
*
*	Other output:	Log file:  	output/1201_rp_b_poisson_comorbid.log
*					Estimates:	output/models/coefs_b_pois_`tvc'_comorbid.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases,  using only age, sex, 
*					ethnicity, rural/not and grouped number of comorbidities
*					as covariates.
*
********************************************************************************



* Open a log file
capture log close
log using "./output/1201_rp_b_poisson_comorbid", text replace



****************************
*  TVC-related predictors  *
****************************

global tvc_foi  = "c.logfoi c.foi_q_day c.foi_q_daysq c.foiqd c.foiqds" 
global tvc_ae   = "c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2"
global tvc_susp = "c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2"

global tvc_all  = "c.logfoi c.foi_q_day c.foi_q_daysq c.foiqd c.foiqds c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2 c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2" 
global tvc_objective = "c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2 c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2" 




***************
*  Open data  *
***************

* Open landmark data
use "data/cr_landmark.dta", clear




********************************
*   Create covariates needed   *
********************************

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
drop asthma_sev diabetes recentcanc recenthaemcanc poorkidney notnormalbmi


* Group number of comorbidities
recode num_comorbid 0=0 1=1 2=2 3/max=3, gen(gp_comorbid)



*********************
*   Poisson Model   *
*********************

* Loop over the sets of time-varying covariates
foreach tvc in foi ae susp all objective {

	capture erase output/models/coefs_b_pois_`tvc'_comorbid.ster

	* Fit model
	timer clear 1
	timer on 1
	streg ${tvc_`tvc'} 							///
		i.male##i.agegroup_fine##i.gp_comorbid 	///
		i.ethnicity_8 i.rural					///
		, dist(exp) 							///
		robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1

	estimates save output/models/coefs_b_pois_`tvc'_comorbid, replace



	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************


	* Pick up coefficient matrix
	matrix b = e(b)

	*  Calculate baseline survival 
	global base_surv28 = exp(-28*exp(_b[_cons]))

	* Add baseline survival to matrix (and add a matrix column name)
	matrix b = [$base_surv28, b]
	local names: colfullnames b
	local names: subinstr local names "c1" "_t:base_surv28"
	mat colnames b = `names'


	/*  Save coefficients to Stata dataset  */

	qui do "analysis/0000_pick_up_coefficients.do"
	get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
		dataname("data/model_b_poisson_`tvc'_comorbid")

}


* Close log file
log close
