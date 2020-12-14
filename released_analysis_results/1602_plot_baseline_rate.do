********************************************************************************
*
*	Do-file:			1602_an_plot_baseline_rate.do
*
*	Written by:			Fizz & John
*
*	Data used:			data/
*							cr_base_cohort.dta
*							foi_coefs.dta
*							ae_coefs.dta
*							susp_coefs.dta
*
*	Data created:		None
*
*	Other output:		output/graphs/
*							tvcmod_reg`i'_age`j'.svg
*									where 	i=1, 2, ..., 7 (region)
*											j = 7 (age 50-54) or 11 (70-74)
*
********************************************************************************
*
*	Purpose:			This do-file graphs the estimated baseline rate using
*						the three different time-varying measures of infection
*						burden: force of infection, A&E attendances and GP
*						suspected cases. 
*
********************************************************************************





**************************************
*  Count COVID-19 deaths over time   *
**************************************
	
	
use "data/cr_base_cohort.dta", replace

* Complete case for ethnicity 
drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.


* Just keep required variables 
keep patient_id died_date_onscovid age ///
	 stp_combined 

* 28-day COVID mortality crude count by day
forvalues i = 1 (1) 73 {
	gen onscoviddeath28_`i' = 			///
		inrange(died_date_onscovid, 	///
		d(1mar2020)-1+`i', 				///
		d(1mar2020)+27-1+`i')
}

* Recode agegroup
recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)
drop age
drop died_date_
drop patient_id

* Count COVID-19 cases by agegroup and STP 
collapse (sum) ons*, by(agegroupfoi stp_combined)
reshape long onscoviddeath28_, i(stp_combined agegroupfoi) j(time)
rename onscoviddeath28_ crude_coviddeath28

label var crude_coviddeath28 "Crude number of COVID-19 deaths by age-group, STP and time"

save "covid_temp", replace




*****************************
*  Count people over time   *
*****************************
	

use "data/cr_base_cohort.dta", replace

* Complete case for ethnicity 
drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.

* Recode agegroup
recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 		///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)
drop age


/* Just keep required variables  */ 

keep patient_id agegroupfoi stp_combined region_7 

* Count COVID-19 cases by agegroup and STP 
gen cons = 1
bysort agegroupfoi stp_combined: egen pop=sum(cons)
keep agegroupfoi stp_combined pop
duplicates drop 

qui summ pop
noi di r(sum)

label var pop "Population size by age-group and STP"

save "covid_temp2", replace

	
	
	


*******************************
*  Create landmark datasets   *
*******************************



* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"


	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace


/* Complete case for ethnicity  */ 

drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.



/* Just keep required variables  */ 

keep patient_id died_date_onscovid died_date_onsother onscoviddeath ///
	age stp_combined region_7
noi count
noi tab onscoviddeath

save "cohort_temp", replace


* Create separate landmark substudies (with only age, region and STP)
forvalues i = 1 (1) 73 {

	use "cohort_temp", clear

	* Date landmark substudy i starts
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'

	
	/*  Event indicator for the 28 day period  */
	
	* Date this landmark started: d(1/03/2020) + `i' - 1
	* Days until death:  died_date_onscovid - {d(1/03/2020) + `i' - 1} + 1
	
	* Survival time (must be between 1 and 28)
	qui gen stime28 = (died_date_onscovid - (d(1/03/2020) + `i' - 1) + 1) ///
			if died_date_onscovid < .
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 & stime28>28
	qui drop stime28 died_date_*
	
	
	
	/* Collapse by age, sex, STP and region  */
	
	recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 	///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)
	drop age
	
	collapse (count) patient_id, by(agegroupfoi region_7 ///
								stp_combined onscoviddeath)

								
	
	/* Tidy and save dataset  */
	
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
	qui save time_`i', replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use time_1.dta, clear
forvalues i = 2 (1) 73 {
	qui append using time_`i'
}

* Delete unneeded datasets
forvalues i = 1 (1) 73 {
	qui erase time_`i'.dta
}

erase "cohort_temp.dta"
save "cohort_temp2.dta", replace





*******************
*  Collapse data  *
*******************

use "cohort_temp2.dta", clear

collapse (sum) patient_id, 			///
	by(agegroupfoi region_7 		///
	stp_combined onscoviddeath time)

rename patient_id fweight



****************************************
*  Add in time-varying infection data  *
****************************************


* Merge in the force of infection data
merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
	assert(match using) keep(match) nogen 


* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen


* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen


* Merge in the time series of COVID-19 deaths
merge m:1 time stp_combined agegroupfoi using "covid_temp", nogen
*erase "covid_temp.dta"
order crude_coviddeath, after(onscoviddeath) 


* Merge in the time series of COVID-19 deaths
merge m:1 stp_combined agegroupfoi using "covid_temp2", nogen
*erase "covid_temp2.dta"
order crude_coviddeath, after(onscoviddeath) 


* Save temporary copy of data
save funcform_temp, replace






**********************************
*  Draw graphs of baseline rate  *
**********************************

use funcform_temp, clear

* Create numerical version of stp
encode stp_combined, gen(stp)


	
	
*************************************************************
*  Pick up estimates from models age-only adjusted models   *
*************************************************************

* Crude
poisson onscoviddeath i.agegroupfoi i.stp i.time 	///
	[fweight=fweight]
matrix b = e(b)
matrix cr_age  = b[1, 1..12]
matrix cr_stp  = b[1, 13..37]
matrix cr_time = b[1, 38..110]
matrix cr_cons = b[1, 111]



* FOI
poisson onscoviddeath 	i.agegroupfoi logfoi 					///
						c.foi_q_day c.foi_q_daysq 				///
						foiqd foiqds							///
						[fweight=fweight]
matrix b = e(b)
matrix foi_age  = b[1, 1..12]
matrix foi_foi  = b[1, 13..17]
matrix foi_cons = b[1, 18]


* A&E attendances
poisson onscoviddeath 	i.agegroupfoi 							///
						logae c.ae_q_day c.ae_q_daysq 			///
						aeqd aeqds aeqds2						///			
						[fweight=fweight]
matrix b = e(b)
matrix ae_age  = b[1, 1..12]
matrix ae_ae   = b[1, 13..18]
matrix ae_cons = b[1, 19]

* Suspected cases
poisson onscoviddeath 	i.agegroupfoi 							///
						logsusp c.susp_q_day c.susp_q_daysq 	///
						suspqd suspqds suspqds2					///
						[fweight=fweight]
matrix b = e(b)
matrix susp_age  = b[1, 1..12]
matrix susp_susp = b[1, 13..18]
matrix susp_cons = b[1, 19]



********************************************************************
*  Create dataset with population by age-group and STP over time   *
********************************************************************


*** THESE UNIQUELY DEFINE ROW:  isid stp agegroupfoi time onscoviddeath
drop fweight onscoviddeath
duplicates drop 
isid stp agegroupfoi time
		


label define age 	1 "18-24" 	///
					2 "25-29" 	///
					3 "30-34" 	///
					4 "35-39" 	///
					5 "40-44" 	///
					6 "45-49" 	///
					7 "50-54" 	///
					8 "55-59" 	///
					9 "60-64" 	///
					10 "65-69" 	///
					11 "70-74" 	///
					21 "75+" 
label values agegroupfoi age
					
label values stp stp

replace stpname = "Buckinghams., Oxfords., Berks., Hamps., IoW"  	if stp==23




************************************************************************
*  Use coefficients to estimate rates by age-group and STP over time   *
************************************************************************


/*  Crude model  */

* Expected number for each STP, for each agegroup and time
gen ln_cr_rate = cr_cons[1,1] 
forvalues i = 1 (1) 25 {
	replace ln_cr_rate = ln_cr_rate + cr_stp[1,`i']  if stp==`i'
}
forvalues j = 1 (1) 73 {
	replace ln_cr_rate = ln_cr_rate + cr_time[1,`j'] if time==`j'
}
forvalues k = 1 (1) 12 {
    replace ln_cr_rate = ln_cr_rate + cr_age[1,`k']  if agegroupfoi==`k' 
}
gen cr_rate = exp(ln_cr_rate)
gen exp_cr_n = cr_rate*pop
drop ln_cr_rate




/*  FOI model  */

gen ln_foi_rate = foi_cons[1,1] 
forvalues k = 1 (1) 12 {
    replace ln_foi_rate = ln_foi_rate + foi_age[1,`k']  if agegroupfoi==`k' 
}
replace ln_foi_rate = ln_foi_rate + foi_foi[1,1]*logfoi
replace ln_foi_rate = ln_foi_rate + foi_foi[1,2]*foi_q_day
replace ln_foi_rate = ln_foi_rate + foi_foi[1,3]*foi_q_daysq
replace ln_foi_rate = ln_foi_rate + foi_foi[1,4]*foiqd
replace ln_foi_rate = ln_foi_rate + foi_foi[1,5]*foiqds

gen foi_rate = exp(ln_foi_rate)
gen exp_foi_n = foi_rate*pop
drop ln_foi_rate




/*  A&E model  */

gen ln_ae_rate = ae_cons[1,1] 
forvalues k = 1 (1) 12 {
    replace ln_ae_rate = ln_ae_rate + ae_age[1,`k']  if agegroupfoi==`k' 
}
replace ln_ae_rate = ln_ae_rate + ae_ae[1,1]*logae
replace ln_ae_rate = ln_ae_rate + ae_ae[1,2]*ae_q_day
replace ln_ae_rate = ln_ae_rate + ae_ae[1,3]*ae_q_daysq
replace ln_ae_rate = ln_ae_rate + ae_ae[1,4]*aeqd
replace ln_ae_rate = ln_ae_rate + ae_ae[1,5]*aeqds
replace ln_ae_rate = ln_ae_rate + ae_ae[1,6]*aeqds2

gen ae_rate = exp(ln_ae_rate)
gen exp_ae_n = ae_rate*pop
drop ln_ae_rate




/*  GP suspected cases model  */

gen ln_susp_rate = susp_cons[1,1] 
forvalues k = 1 (1) 12 {
    replace ln_susp_rate = ln_susp_rate + susp_age[1,`k']  if agegroupfoi==`k' 
}
replace ln_susp_rate = ln_susp_rate + susp_susp[1,1]*logsusp
replace ln_susp_rate = ln_susp_rate + susp_susp[1,2]*susp_q_day
replace ln_susp_rate = ln_susp_rate + susp_susp[1,3]*susp_q_daysq
replace ln_susp_rate = ln_susp_rate + susp_susp[1,4]*suspqd
replace ln_susp_rate = ln_susp_rate + susp_susp[1,5]*suspqds
replace ln_susp_rate = ln_susp_rate + susp_susp[1,6]*suspqds2

gen susp_rate = exp(ln_susp_rate)
gen exp_susp_n = susp_rate*pop
drop ln_susp_rate


		
		
		
		
		
		
*****************************************************
*  Graph expected numbers by STP:  Agegroup 50-54   *
*****************************************************

sort time

* East of England
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==1, 								///
		by(stpname, note("") title("East")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg1_age7.svg", as(svg) replace


* London
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==2, 								///
		by(stpname, note("") title("London")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (5) 15, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg2_age7.svg", as(svg) replace

* Midlands
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==3, 								///
		by(stpname, note("") title("Midlands")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 12)) ylabel(0 (3) 12, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg3_age7.svg", as(svg) replace

* North East/Yorkshire
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==4, 								///
		by(stpname, note("") title("North East/Yorkshire")) 			///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 12, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg4_age7.svg", as(svg) replace

* North West
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==5, 								///
		by(stpname, note("") title("North West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 12)) ylabel(0 (3) 12, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg5_age7.svg", as(svg) replace

* South East
twoway  (line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==6, 								///
		by(stpname, note("") title("South East")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg6_age7.svg", as(svg) replace

* South West
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==7 & region_7==7, 								///
		by(stpname, note("") title("South West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg7_age7.svg", as(svg) replace



	
		

*****************************************************
*  Graph expected numbers by STP:  Agegroup 70-74   *
*****************************************************


* East of England
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==1, 								///
		by(stpname, note("") title("East")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg1_age11.svg", as(svg) replace

* London
twoway  (line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==2, 								///
		by(stpname, note("") title("London")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 60, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg2_age11.svg", as(svg) replace

* Midlands
twoway  (line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==3, 								///
		by(stpname, note("") title("Midlands")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg3_age11.svg", as(svg) replace

* North East/Yorkshire
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==4, 								///
		by(stpname, note("") title("North East/Yorkshire")) 			///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 60, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg4_age11.svg", as(svg) replace

* North West
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==5, 								///
		by(stpname, note("") title("North West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg5_age11.svg", as(svg) replace

* South East
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==6, 								///
		by(stpname, note("") title("South East")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected no cases")										///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg6_age11.svg", as(svg) replace

* South West
twoway 	(line exp_foi_n  			time, lwidth(thick))				///
		(line exp_ae_n  		 	time, lwidth(thick))				///
		(line exp_susp_n 			time, lwidth(thick)) 				///
		(line crude_coviddeath28 	time, lwidth(thick))  				///
		if agegroupfoi==11 & region_7==7, 								///
		by(stpname, note("") title("South West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected no cases")										///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Force of infection") 									///
		label(2 "Smoothed A & E rate") 									///
		label(3 "GP suspected case rate")								///
		label(4 "Crude numbers"))
graph export "output/graphs/tvcmod_reg7_age11.svg", as(svg) replace
		

		
		

		
	