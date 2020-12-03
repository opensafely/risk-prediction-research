********************************************************************************
*
*	Do-file:		1503_tabulate_cohort_descriptives.do
*
*	Programmed by:	Krishnan (edited by Fizz)
*
*	Data used:		data/cr_base_cohort.dta
*
*	Data created:	None
*
*	Other output:	Table: 		output/table1.txt
*					Log file: 	output/1503_an_describe_cohort.log
*
********************************************************************************
*
*	Purpose:		This do-file describes the data in the base cohort and 
*					puts the output in a log file.
*
*	NOTES: 			1) Stata do-file called internally:
*							analysis/0000_cr_define_covariates.do
*  
********************************************************************************* 



* Open a log file
cap log close
log using "output/1503_an_describe_cohort", text replace 


* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"



*******************************************************************************
*   Program: generaterow 
*
*			 Generic code to output one row of table
*******************************************************************************

cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) outcome(string)
	
	* Put the varname and condition to left so that alignment 
	*   can be checked vs shell
	file write tablecontent ("`variable'") _tab ("`condition'") _tab
	
	count
	local overalldenom=r(N)
	
	count if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	cou if onscoviddeath==1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent (r(N)) (" (") %4.2f  (`pct') (")") _n

	
end




*******************************************************************************
*   Program: tabulatevariable 
*
*			 Generic code to output one section (variable) within table 
*******************************************************************************

cap prog drop tabulatevariable
prog define tabulatevariable
	syntax, variable(varname) start(real) end(real) [missing] outcome(string)

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') ///
			condition("==`varlevel'") outcome(onscoviddeath)
	}
	if "`missing'"!="" generaterow, ///
		variable(`variable') condition(">=.") outcome(onscoviddeath)

end





*************************
*  Create table output  *
*************************



cap file close tablecontent
file open tablecontent using "output/table1.txt", write text replace



/*  Open cohort and extract covariates  */
	

use "data/cr_base_cohort.dta", replace

* Complete case for ethnicity  
tab ethnicity_8
tab ethnicity_8, m
drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.
	
*  Extract relevant covariates (as of 1 Mar 2020)
local start = d(01/03/2020)
define_covs, dateno(`start')



/* Table: Demographic variables  */

gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) outcome(onscoviddeath)
file write tablecontent _n 

tabulatevariable, variable(agegroup) start(1) end(6) outcome(onscoviddeath) 
file write tablecontent _n 

tabulatevariable, variable(male) start(0) end(1) outcome(onscoviddeath)
file write tablecontent _n 

tabulatevariable, variable(bmicat) start(1) end(5) missing outcome(onscoviddeath)
file write tablecontent _n 

tabulatevariable, variable(smoke) start(1) end(3) missing outcome(onscoviddeath) 
file write tablecontent _n 

tabulatevariable, variable(ethnicity_8) start(1) end(8) missing outcome(onscoviddeath)
file write tablecontent _n 

tabulatevariable, variable(imd) start(1) end(5) outcome(onscoviddeath)
file write tablecontent _n 

tabulatevariable, variable(rural) start(0) end(1) outcome(onscoviddeath)
file write tablecontent _n 



/* Table: Clinical variables  */


tabulatevariable, variable(bpcat) start(1) end(4) missing outcome(onscoviddeath)
tabulatevariable, variable(hypertension) start(1) end(1) outcome(onscoviddeath)			
file write tablecontent _n  
file write tablecontent _n
file write tablecontent _n


/* Table: Comorbidities, respiratory  */

* Asthma  (Order: none, no OCS, OCS)
tabulatevariable, variable(asthmacat) start(2) end(3) outcome(onscoviddeath) 

* Respiratory
tabulatevariable, variable(respiratory) start(1) end(1) outcome(onscoviddeath)

* CF
tabulatevariable, variable(cf) start(1) end(1) outcome(onscoviddeath)
file write tablecontent _n


/* Table: Comorbidities, cardiovascular  */

* Cardiac
tabulatevariable, variable(cardiac) start(1) end(1) outcome(onscoviddeath)

* AF
tabulatevariable, variable(af) start(1) end(1) outcome(onscoviddeath)

* DVT/PE
tabulatevariable, variable(dvt_pe) start(1) end(1) outcome(onscoviddeath)

* PAD/Amputation
tabulatevariable, variable(pad) start(1) end(1) outcome(onscoviddeath)

* Diabetes (Order: controlled, then uncontrolled, then missing hba1c)
tabulatevariable, variable(diabcat) start(2) end(4) outcome(onscoviddeath) 
file write tablecontent _n



/* Table: Comorbidities, neurological  */


* Stroke
tabulatevariable, variable(stroke) start(1) end(1) outcome(onscoviddeath)

* Dementia
tabulatevariable, variable(dementia) start(1) end(1) outcome(onscoviddeath)

* Other neurological 
tabulatevariable, variable(neuro) start(1) end(1) outcome(onscoviddeath)
file write tablecontent _n



/* Table: Comorbidities, cancer  */


* Cancer Ex-Haem (Order: <1, 1-4.9, 5+ years ago)
tabulatevariable, variable(cancerExhaem) start(2) end(4) outcome(onscoviddeath) 
file write tablecontent _n

* Cancer Haem (Order: <1, 1-4.9, 5+ years ago)
tabulatevariable, variable(cancerHaem) start(2) end(4) outcome(onscoviddeath) 
file write tablecontent _n



/* Table: Comorbidities, kidney/liver  */


* Reduced kidney function
tabulatevariable, variable(kidneyfn) start(2) end(3) outcome(onscoviddeath)

* Dialysis
tabulatevariable, variable(dialysis) start(1) end(1) outcome(onscoviddeath)

* Liver
tabulatevariable, variable(liver) start(1) end(1) outcome(onscoviddeath)

* Organ transplant
tabulatevariable, variable(transplant) start(1) end(1) outcome(onscoviddeath)
file write tablecontent _n




/* Table: Comorbidities, immunosuppression  */

* Spleen
tabulatevariable, variable(spleen) start(1) end(1) outcome(onscoviddeath)

* RA/SLE/PSORIASIS
tabulatevariable, variable(autoimmune) start(1) end(1) outcome(onscoviddeath)

* Other immunosuppression 
tabulatevariable, variable(suppression) start(1) end(1) outcome(onscoviddeath)

* HIV 
tabulatevariable, variable(hiv) start(1) end(1) outcome(onscoviddeath)

* Inflammatory Bowel Disease
tabulatevariable, variable(ibd) start(1) end(1) outcome(onscoviddeath)
file write tablecontent _n




/* Table: Other  */

* Fracture
tabulatevariable, variable(fracture) start(1) end(1) outcome(onscoviddeath)

* Intellectual disability
tabulatevariable, variable(ld) start(1) end(1) outcome(onscoviddeath)

* Serious mental illness
tabulatevariable, variable(smi) start(1) end(1) outcome(onscoviddeath)


file close tablecontent
