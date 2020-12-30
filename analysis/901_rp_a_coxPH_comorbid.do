********************************************************************************
*
*	Do-file:		901_rp_a_coxPH_comorbid.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_coxPH_comorbid.dta
*
*	Other output:	Log file:  	output/900_rp_a_coxPH_comorbid.log
*					Estimates:	output/models/coefs_a_cox_comorbid.ster
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model using only age, sex, ethnicity, rural/not and grouped 
*					number of comorbidities as covariates.
*  
********************************************************************************


* Open a log file
capture log close
log using "./output/901_rp_a_coxPH_comorbid", text replace




************************************
*  Open dataset for model fitting  *
************************************

use "data/cr_casecohort_models.dta", replace


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



*******************
*   CoxPH Model   *
*******************
		
capture erase output/models/coefs_a_cox_comorbid.ster

timer clear 1
timer on 1
stcox i.male##i.agegroup_fine##i.gp_comorbid 	///
		i.ethnicity_8 i.rural					///		
		, vce(robust)
estat ic
timer off 1
timer list 1

estimates save output/models/coefs_a_cox_comorbid, replace




***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
predict basesurv, basesurv
summ basesurv if _t <= 28 
global base_surv28 = r(min) // baseline survival decreases over time

summ basesurv if _t <= 100 
global base_surv100 = r(min) 

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv28 , $base_surv100 , b]
local names: colfullnames b
local names: subinstr local names "c1" "base_surv28"
local names: subinstr local names "c2" "base_surv100"
mat colnames b = `names'

*  Save coefficients to Stata dataset  
qui do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("")  ///
	dataname("data/model_a_coxPH_comorbid")



log close

