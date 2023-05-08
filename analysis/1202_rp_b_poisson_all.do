********************************************************************************
*
*	Do-file:		1202_rp_b_poisson_all.do
*
*	Programmed by:	Fizz & John & Krishnan
*
*	Data used:		data/cr_landmark.dta
*
*	Data created:	data/model_b_poisson_`tvc'_all.dta, 
*						where tvc=foi, ae, susp, all, objective
*
*	Other output:	Log file:  	output/1202_rp_b_poisson_all.log
*					Estimates:	output/models/coefs_b_pois_`tvc'_all.ster
*
********************************************************************************
*
*	Purpose:		This do-file fits Poisson regression models to the landmark
*					substudies to predict 28-day COVID-19 death incorporating
*					3 different measures of time-varying measures of disease:
*					force of infection estimates, A&E attendances for COVID, 
*					and suspected GP COVID cases, with all potential covariates 
*					(i.e. not using any form of variable selection).
*
********************************************************************************



* Open a log file
capture log close
log using "./output/1202_rp_b_poisson_all", text replace



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





*********************
*   Poisson Model   *
*********************

* Loop over the sets of time-varying covariates
foreach tvc in foi ae susp all objective {

	capture erase output/models/coefs_b_pois_`tvc'_all.ster

	* Fit model
	timer clear 1
	timer on 1
	streg ${tvc_`tvc'} 												///
		c.agec i.male												///
			i.rural i.imd i.ethnicity_8 							///
			i.obesecat i.smoke_nomiss i.bpcat_nomiss 				///
			i.hypertension i.diabcat i.cardiac 						///
			i.af i.dvt_pe i.pad 									///
			i.stroke i.dementia i.neuro 							///
			i.asthmacat i.cf i.respiratory							///
			i.cancerExhaem i.cancerHaem 							///
			i.liver i.dialysis i.transplant i.kidneyfn 				///
			i.autoimmune i.spleen i.suppression i.hiv i.ibd			///
			i.ld i.smi i.fracture 									///
			i.hh_children c.hh_numc c.hh_num2 c.hh_num3				///
			c.age2 c.age3 											///
			c.agec#i.male	 										///
			c.agec#(i.rural i.imd i.ethnicity_8 					///
				i.obesecat i.smoke_nomiss i.bpcat_nomiss 			///
				i.hypertension i.diabcat i.cardiac 					///
				i.af i.dvt_pe i.pad 								///
				i.stroke i.dementia i.neuro 						///
				i.asthmacat i.cf i.respiratory						///
				i.cancerExhaem i.cancerHaem 						///
				i.liver i.dialysis i.transplant i.kidneyfn 			///
				i.autoimmune i.spleen i.suppression i.hiv i.ibd		///
				i.ld i.smi i.fracture 								///
				i.hh_children)										///
			i.male#(i.rural i.imd i.ethnicity_8 					///
				i.obesecat i.smoke_nomiss i.bpcat_nomiss 			///
				i.hypertension i.diabcat i.cardiac 					///
				i.af i.dvt_pe i.pad 								///
				i.stroke i.dementia i.neuro 						///
				i.asthmacat i.cf i.respiratory						///
				i.cancerExhaem i.cancerHaem 						///
				i.liver i.dialysis i.transplant i.kidneyfn 			///
				i.autoimmune i.spleen i.suppression i.hiv i.ibd		///
				i.ld i.smi i.fracture 								///
				i.hh_children)										///
				, dist(exp) 										///
				robust cluster(patient_id) 
	estat ic
	timer off 1
	timer list 1

	estimates save output/models/coefs_b_pois_`tvc'_all, replace



	***********************************************
	*  Put coefficients and survival in a matrix  * 
	***********************************************


	* Pick up coefficient matrix
	matrix b = e(b)

	*  Calculate baseline survival 
	global base_surv28 = exp(-28*exp(_b[_cons])/100)

	* Add baseline survival to matrix (and add a matrix column name)
	matrix b = [$base_surv28, b]
	local names: colfullnames b
	local names: subinstr local names "c1" "_t:base_surv28"
	mat colnames b = `names'


	/*  Save coefficients to Stata dataset  */

	qui do "analysis/0000_pick_up_coefficients.do"
	get_coefs, coef_matrix(b) eqname("_t:") cons_no ///
		dataname("data/model_b_poisson_`tvc'_all")

}


* Close log file
log close
