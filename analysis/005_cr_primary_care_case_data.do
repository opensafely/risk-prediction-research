********************************************************************************
*
*	Do-file:		005_cr_primary_care_case_data.do
*
*	Programmed by:	Alex & Fizz & John
*
*	Data used:		output/input_covid_by_stp.csv  
*						(generated from study_definition_covid_by_stp.py)
*					data/ae_stp_pop.csv  (denominator data)
* 					data/STP_region_map.xlsx (STP linked to regions)
*
*	Data created:	data/susp_rates.dta (smoothed rates over time)
*					data/susp_coefs.dta (current rate and coefficients)
*
*	Other output:	Log file:  005_cr_primary_care_case_data.log
*
********************************************************************************
*
*	Purpose:		To create a dataset containing summaries of GP suspected
*					COVID-19 cases over time by STP.  
*  
********************************************************************************



* Open a log file
cap log close
log using "output/005_cr_primary_care_case_data", replace t

*** PARAMETER NEEDED:  max days from infection to death
global maxlag = 21



/*  Import denominator data  */


import delimited "data/ae_stp_pop.csv", clear varnames(1)
egen pop = rowtotal(v2 v3 v4 v5 unknown)
drop v2 v3 v4 v5 unknown
save "temppop", replace

import excel "data/STP_region_map.xlsx", ///
	sheet("STP_region_map") firstrow clear
keep Code Region Name
rename Code stpcode
gen region_7 = 1 if Region=="East"
replace region_7 = 2 if Region=="London"
replace region_7 = 3 if Region=="East Midlands" |  Region=="West Midlands"
replace region_7 = 4 if Region=="North East" |  Region=="Yorkshire and The Humber"
replace region_7 = 5 if Region=="North West"
replace region_7 = 6 if Region=="South East"
replace region_7 = 7 if Region=="South West"

label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"
drop Region
rename Name stpname
merge 1:1 stpcode using temppop, keep(match) assert(match master) nogen
save "temppop", replace



					
/*  Import suspect COVID data  */
					
* Read in data
import delimited "output/input_covid_by_stp.csv", clear

* Drop those without a code
drop if covid_suspected == ""

* Drop those missing STP
drop if stp==""

* Count patients per date and STP
collapse (count) patient_id, by(covid_suspected stp)
rename patient_id count

* Count days since start of feb until each suspected case
gen temp = date(covid_suspected, "YMD")
format temp %td
drop if !inrange(temp, d(1feb2020), d(7jun2020))
gen days_1feb = temp - d(1feb2020) + 1
drop temp

* Reshape
drop covid_suspected
reshape wide count, i(stp) j(days_1feb) 

foreach var of varlist count* {
	recode `var' .=0
}



					
/*  Merge in STP and population details  */

rename stp stpcode
merge m:1 stp using "temppop", assert(match using) keep(match) nogen
erase "temppop.dta"
order stpcode stpname region_7 pop


/*  Combine smaller STPs wth neighbouring areas  */

replace stpcode ="E54000007/E54000008" if inlist(stpcode, "E54000007", "E54000008")
replace stpname = "Manchester/Cheshire/Merseyside"  if stpcode=="E54000007/E54000008" 

replace stpcode ="E54000010/E54000012" if inlist(stpcode, "E54000010", "E54000012")
replace stpname = "Staffordshire/Derbyshire"  if stpcode=="E54000010/E54000012" 

replace stpcode ="E54000027/E54000029" if inlist(stpcode, "E54000027", "E54000029")
replace stpname = "London"  if stpcode=="E54000027/E54000029" 

replace stpcode ="E54000033/E54000035" if inlist(stpcode, "E54000033", "E54000035")
replace stpname = "Sussex and Surrey"  if stpcode=="E54000033/E54000035" 

replace stpcode ="E54000036/E54000037" if inlist(stpcode, "E54000036", "E54000037")
replace stpname = "Devon/Cornwall"  if stpcode=="E54000036/E54000037" 

replace stpcode ="E54000042/E54000044" if inlist(stpcode, "E54000042", "E54000044")
replace stpname = "Buckinghamshire, Oxfordshire and Berkshire, Hampshire, IoW"  ///
			if stpcode=="E54000042/E54000044" 


																								
														
* Combine total population within combined STPs
bysort stpname: egen population = sum(pop)
drop pop

* Combine suspected case counts within new combined STPs
foreach var of varlist count* {
	bysort stpname: egen temp = sum(`var')
	drop `var'
	rename temp `var'
}

* Drop duplicated rows
duplicates drop

* Tidy data
rename stpcode stp_combined
label var stp_combined "STP, with smaller areas combined"
sort stp_combined 
order stp_combined stpname region_7 population




/*  Put counts over time in long format  */

reshape long count, i(stp_combined) j(day)
rename count susp_count

* Put day back in date format
gen date = day + d(1feb2020) - 1 
drop day



/*  Smooth GP suspected cases (mean over last 7 days) */

forvalues t = 0 (1) 6 {
	bysort stp_combined (date): gen susp_count_lag`t' = susp_count[_n-`t']
}
egen susp_mean = rowmean( susp_count_lag0 susp_count_lag1 susp_count_lag2 	///
						susp_count_lag3 susp_count_lag4 susp_count_lag5 	///
						susp_count_lag6)
drop susp_count_lag*

* Smoothed (over 7 days) rate of GP suspected cases
gen susp_rate = 100000*susp_mean/population
label var susp_rate "Smoothed rate of suspected GP COVID cases over last 7 days (per 100,000)"
drop susp_mean susp_count



/*  Save data for descriptive plots  */

format date %td
label var population "TPP population used for case count" 
label var date "Date"


* Label and save dataset
label data "GP suspected COVID-19 cases, smoothed rates over time"
save "data/susp_rates", replace






/*  Create lagged GP suspected cases  */

rename susp_rate susp_rate_lag
forvalues t = 1 (1) $maxlag {
	bysort stp_combined (date): gen susp_rate_lag`t' = susp_rate_lag[_n-`t']
}
rename susp_rate_lag susp_rate_lag0

* Set earlier missing values to zero (no data, i.e. zero count)
forvalues t =  1 (1) $maxlag {
	replace susp_rate_lag`t' = 0 if susp_rate_lag`t' ==.
}

* Only keep dates from (day before) 1 March onwards
drop if date < d(1mar2020) - 1

* Drop dates after the 7 june
drop if date > d(7June2020) 



/*  Fit quadratic model to A&E data  */

gen susp_rate_init = susp_rate_lag0


* Fit quadratic model to infection proportion over last "lag" days
reshape long susp_rate_lag, i(date stp_combined) j(lag)
replace lag = -lag

preserve
statsby susp_q_cons	=_b[_cons] 									///
		susp_q_day	=_b[lag] 									///
		susp_q_daysq	=_b[c.lag#c.lag]	 					///
		, by(stp_combined stpname date susp_rate_init) clear: 	///
	regress susp_rate_lag c.lag##c.lag
save "quadratic", replace
restore
statsby susp_c_cons	=_b[_cons] 									///
		susp_c_day	=_b[lag] 									///
		susp_c_daysq	=_b[c.lag#c.lag]	 					///
		susp_c_daycu	=_b[c.lag#c.lag#c.lag]					///
		, by(stp_combined stpname date susp_rate_init) clear: 	///
	regress susp_rate_lag c.lag##c.lag##c.lag
merge 1:1 stp_combined date using "quadratic", assert(match) nogen
rename susp_rate_init susp_rate

* Delete data not needed
erase "quadratic.dta"


/*  Days since cohort start date  */

gen time = date - d(1mar2020) + 2
drop date



/*  Tidy and save data  */


* Label variables
label var time 			"From 1 (29Feb, data for predicting 1Mar) to 100 (7Jun for predicting 8Jun)"
label var susp_rate		"Suspected GP case rate (mean daily rate over last 7 days)"
label var susp_q_cons 	"Quadratic model of suspected GP cases: constant coefficient"
label var susp_q_day	"Quadratic model of suspected GP cases: linear coefficient"
label var susp_q_daysq	"Quadratic model of suspected GP cases: squared coefficient"
label var susp_c_cons 	"Cubic model of suspected GP cases: constant coefficient"
label var susp_c_day	"Cubic model of suspected GP cases: linear coefficient"
label var susp_c_daysq	"Cubic model of suspected GP cases: squared coefficient"
label var susp_c_daycu	"Cubic model of suspected GP cases: cubed coefficient"
label var stpname 		"Sustainability and Transformation Partnership"
label var stp_combined 	"STP combined for smaller areas"


* Order and sort variables
order time stp* susp_rate susp_q_cons susp_q_day susp_q_daysq	///
		susp_c_cons susp_c_day susp_c_daysq susp_c_daycu
sort stp_combined time

* Label and save dataset
label data "GP suspected COVID-19 cases, rate over last week and quadratic/cubic model"
save "data/susp_coefs", replace

* Close the log file
log close
