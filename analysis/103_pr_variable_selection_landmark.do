********************************************************************************
*
*	Do-file:			103_pr_variable_selection_landmark.do
*
*	Written by:			Fizz & John
*
*	Data used:			data/cr_base_cohort.dta
*
*	Data created:		Selected variables (Stata dataset): 
*							data/cr_selected_model_coefficients_landmark_`tvc'.dta
*									for tcv = foi, ae and susp
*
*	Other output:		Log file:  103_pr_variable_selection_landmark_`tvc'.log
*									for tcv = foi, ae and susp
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple logistic lasso model on a  
*						random sample of data taken at three times across the 
*						study period, for the purposes of variable selection. 
*
*	NOTES:				Stata do-file called:
*							analysis/0000_cr_define_covariates.do
*
********************************************************************************


* Time-varyng variable: either foi (force of infection), ae (A&E attendances)
*  or susp (GP suspected cases)

local tvc `1' 
noi di "`tvc'"




/******   Chosen functional form for timevarying variables  ******/

global tvc_foi  = "c.logfoi c.foi_q_day c.foi_q_daysq c.foiqd c.foiqds" 
global tvc_ae   = "c.logae c.ae_q_day c.ae_q_daysq c.aeqd c.aeqds c.aeqds2"
global tvc_susp = "c.logsusp c.susp_q_day c.susp_q_daysq c.suspqd c.suspqds c.suspqds2"

* Print out relevant variables
noi di "${tvc_`tvc'}"


* Open a log file
cap log close
log using "output/103_pr_variable_selection_landmark_`tvc'", replace t


* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"




	

*************************************************
*  Select 4% random sample from cohort dataset  *
*************************************************

	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace


/* Complete case for ethnicity  */ 

drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.

/* Just keep list of patients  */ 

keep patient_id died_date_onscovid died_date_onsother onscoviddeath
noi count
noi tab onscoviddeath


/* Take random sample  */ 

set seed 12378009


* Each equal to 3% of cohort; non-overlapping
gen select1 = uniform()<0.03
gen select2 = uniform()<0.03092784 if select1==0
gen select3 = uniform()<0.03191489 if select1==0 & select2==0

tab select1 select2, m
tab select1 select3, m
tab select2 select3, m

* Variable time: days since 1 March (inclusive)
gen     time = d(1mar2020)  - d(1mar2020) + 1 if select1==1
replace time = d(6apr2020)  - d(1mar2020) + 1 if select2==1
replace time = d(12may2020) - d(1mar2020) + 1 if select3==1

* Dates of each sample start follow-up
global select1date = d(1mar2020)
global select2date = d(6apr2020)
global select3date = d(12may2020)

save "list.dta", replace



/*  Extract relevant covariates  */

forvalues i = 1 (1) 3 {
    
	use "data/cr_base_cohort.dta", replace
	merge 1:1 patient_id using "list", nogen
	keep if select`i'==1
	
	* Drop people who die prior to their start date
	drop if died_date_onscovid < ${select`i'date}
	drop if died_date_onsother < ${select`i'date}
	
	* Define covariates as of the start date of the validation period
	define_covs, dateno(${select`i'date})

	save sample`i', replace
}
erase "list.dta"

* Put the three samples together
use "sample1", clear
append using "sample2"
append using "sample3"
drop select1 select2 select3

erase "sample1.dta"
erase "sample2.dta"
erase "sample3.dta"




/*  Add in time-varying variables  */

recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)

* Merge in the force of infection data
merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
	assert(match using) keep(match) nogen 
drop agegroupfoi
drop foi_c_cons foi_c_day foi_c_daysq foi_c_daycu

* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen
drop ae_c_cons ae_c_day ae_c_daysq ae_c_daycu

* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen
drop susp_c_cons susp_c_day susp_c_daysq susp_c_daycu



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








***********************************************
*  Outcome and offset for variable selection  *
***********************************************
	
* Outcome 
qui capture drop stime
qui gen stime28 = (died_date_onscovid - (d(1/03/2020) + time - 1) + 1) ///
			if died_date_onscovid < .
				
* Mark people who have an event in the relevant 28 day period
qui replace onscoviddeath = 0 if onscoviddeath==1 & stime28>28
qui replace stime28 = 28 if onscoviddeath==0
noi bysort onscoviddeath: summ stime28

			


*******************************
*  Variable Selection  - FOI  *
*******************************


timer clear 1
timer on 1
lasso logit onscoviddeath	 										///
			(c.agec i.male 											///
			${tvc_`tvc'} )											///
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
			 ,  rseed(7248) grid(20) folds(3)
timer off 1
timer list 1





/*  Save coefficients of post-lasso   */

lassocoef, display(coef, postselection eform)
matrix define A = r(coef)

* Selected coefficients
local  SelectedVars = e(allvars_sel)
noi di "`SelectedVars'"


* Save coefficients of post-lasso 
tempname coefs
postfile `coefs' str30(variable) coef using 	///
	"data\cr_selected_model_coefficients_landmark_`tvc'.dta", replace

local i = 1

foreach v of local SelectedVars {
	
	local coef = A[`i',1]

	post `coefs' ("`v'") (`coef')
    local ++i
}
postclose `coefs'





* Close the log file
log close


		

