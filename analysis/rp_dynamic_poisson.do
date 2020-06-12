********************************************************************************
*
*	Do-file:			rp_dynamic_poisson.do
*
*	Written by:			Fizz
*
*	Data used:			cr_create_analysis_dataset.dta (cohort data)
*						infected_coefs_dm.dta (burden of infection over time)
*
*	Data created:		test.dta  
*
*	Other output:		None
*
********************************************************************************
*
*	Purpose:			To give this analysis approach (dynamic poisson models)
*						a test run. 
*
********************************************************************************



* Open a log file
capture log close
log using "output/rp_dynamic_poisson", text replace





***************************
*  Create daily datasets  *
***************************

timer clear 1
timer on 1
forvalues i = 0 (1) 100 {
	use "cr_create_analysis_dataset", clear
	
	* Calculate survival time from March 1
	drop if stime_onscoviddeath<td(1mar2020)
	gen stime = stime_onscoviddeath - td(1mar2020)

	qui drop if stime<`i'

	* Obtain sampling fraction for controls (10 x number covid cases on that day)
	qui count
	local N = r(N)
	qui count if stime==`i' & onscoviddeath==1
	local ncont = r(N)*10
	
	* Obtain sampling fraction (1 for cases on this day)
	qui gen u = uniform()
	sort u
	gen keep = 1 if _n<=`ncont'
	gen sf_weight = 1/(`ncont'/`N') if keep==1
	
	* Also keep all cases on that day
	replace keep = 1 if stime==`i' & onscoviddeath==1
	
	* Delete everyone not randomly selected and not a case
	keep if keep==1

	* Covid individuals in the random sample
	replace onscoviddeath = 0 if onscoviddeath==1 & stime>`i'

	* Tidy and save dataset
	gen time = `i'
	recode sf_weight .=1
	drop stime u keep
	save time_`i', replace
}

* Stack the datasets
use time_1.dta, clear
forvalues i = 2 (1) 100 {
	append using time_`i'
}

label var sf_weight "Inverse of sampling fraction"
label var time "Day of event"

* Merge in the lagged infection prevalence data (TO COME)


* Merge in the summary infection prevalence data
gen region_small = region
replace region_small = "Midlands" if inlist(region, "East Midlands", "West Midlands")
replace region_small = "North East and Yorkshire" if inlist(region, "North East", "Yorkshire and The Humber", "Yorkshire and the Humber")
merge m:1 time region_small agegroup using "infected_coefs_dm", keep(master match) nogen


* TEMPORARILY SAVE
save test, replace
timer off 1
timer list 1



***************
*  Fit model  *
***************

timer clear 1
timer on 1
* New model (Poisson 0 vs more); AC+ve, B-ve (with analytic derivatives)
mlexp (-(1-onscoviddeath)*exp({xb: male i.agegroup chronic_respiratory_disease	///
		asthma chronic_cardiac_disease diabetes 	///
		hypertension stroke_dementia other_neuro	///
		organ_transplant spleen ra_sle_psoriasis	///	
		other_immunosuppression})*(exp({b: _cons})*cons - exp({c: _cons})*day + exp({d: _cons})*daysq) ///
        + onscoviddeath*log(1 - exp(-1*exp({xb: })*(exp({b: _cons})*cons - exp({c: _cons})*day + exp({d: _cons})*daysq)))),  ///	 
		deriv(/xb = -(1-onscoviddeath)*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq) ///
			+ onscoviddeath*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq)*exp(-1*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq))*((1 -	exp(-1*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq)))^(-1))) ///
         deriv(/b = -(1-onscoviddeath)*cons*exp({b:})*exp({xb:}) ///
			+ cons*onscoviddeath*exp({xb:})*(exp({b:}))*exp(-1*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq))*((1 - exp(-exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq )))^(-1) ))  ///
	     deriv(/c= (1-onscoviddeath)*day*exp({c:})*exp({xb:}) ///
			- day*onscoviddeath*exp({xb:})*(exp({c:}))*exp(-1*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq))*((1 - exp(-exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq )))^(-1) ))  ///		
	     deriv(/d= -(1-onscoviddeath)*daysq*exp({d:})*exp({xb:}) ///
			+ daysq*onscoviddeath*exp({xb:})*(exp({d:}))*exp(-1*exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq))*((1 - exp(-exp({xb:})*(exp({b:})*cons - exp({c:})*day + exp({d:})*daysq )))^(-1) )) ///
		 from(b:_cons=0.05 c:_cons=0.05 d:_cons=0.05) 	 
nlcom 	(cons:   exp(_b[b:_cons])) 	///
		(day:   -exp(_b[c:_cons]))	///	
		(daysq:  exp(_b[d:_cons]))
timer off 1
timer list 1		   
		
		


	
* Close the log file
log close


