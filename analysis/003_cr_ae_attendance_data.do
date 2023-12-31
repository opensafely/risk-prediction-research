********************************************************************************
*
*	Do-file:			003_cr_ae_attendance_data.do
*
*	Written by:			Fizz
*
*	Data used:			data/stp_ae_attendances.csv
*
*	Data created:		data/ae_rates.dta (smoothed rates over time)
*						data/ae_coefs.dta (current rate and coefficients)
*
*	Other output:		Log file:  003_cr_ae_attendance_data.log
*
********************************************************************************
*
*	Purpose:			To create a dataset containing summaries of A&E 
*						attendances over time by STP. 
*
********************************************************************************



* Open a log file
capture log close
log using "output/003_cr_ae_attendance_data", text replace

*** PARAMETER NEEDED:  max days from infection to death
global maxlag = 21



***********************
*  A&E COVID-19 data  *
***********************


/*  Import AE denominator data  */

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
					
					
					
/*  Create list of STPs by possible dates  */

clear
set obs 147
gen date = d(4feb2020) + _n
format date %td
save "datelist", replace

import delimited "data/ae_counts.csv", ///
	encoding(ISO-8859-9) colrange(1:1) clear 
rename v1 stpcode
drop in 1
expand 147
bysort stpcode: gen date = d(4feb2020) + _n
merge m:1 date using "datelist", assert(match) nogen
format date %td
save "datelist", replace




/*  Import AE attendance data  */

* Import first row (dates)
import delimited "data/ae_counts.csv", ///
	varnames(nonames) rowrange(1:1) colrange(2) clear 

gen cons = 1
reshape long v, i(cons) j(day)

gen date = date(v, "DMY")
format date %td
drop v cons
save "tempdate", replace


* Import remaining rows (counts)
import delimited "data/ae_counts.csv", ///
	varnames(nonames) rowrange(2) clear 
rename v1 stpcode

foreach var of varlist v* {
	recode `var' .=0
}

reshape long v, i(stpcode) j(day)
replace day = day - 1
merge m:1 day using "tempdate", assert(match) nogen
merge 1:1 date stpcode using "datelist", assert(match using) nogen
drop day
gen day = date - d(5feb2020) + 1
label var day "Days since 5 Feb (inc)"
drop date

reshape wide v, i(stpcode) j(day)
merge 1:1 stpcode using "temppop", assert(match) nogen
erase "temppop.dta"
order stpcode stpname region_7 pop


/*  Combine smaller STPs wth neighbouring areas  */

replace stpcode ="E54000007/E54000008" if inlist(stpcode, "E54000007", "E54000008")
replace stpname = "Manchester/Cheshire/Merseyside" if stpcode=="E54000007/E54000008" 

replace stpcode ="E54000010/E54000012" if inlist(stpcode, "E54000010", "E54000012")
replace stpname = "Staffordshire/Derbyshire" if stpcode=="E54000010/E54000012" 

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

* Combine A&E counts within new combined STPs
foreach var of varlist v* {
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

reshape long v, i(stp_combined) j(day)
rename v aecount
gen date = d(5feb2020) + day - 1
format date %td



/*  Smooth AE attendance counts (mean over last 7 days) */

forvalues t = 0 (1) 6 {
	bysort stp_combined (date): gen aecount_lag`t' = aecount[_n-`t']
}
egen aemean = rowmean( aecount_lag0 aecount_lag1 aecount_lag2 ///
						aecount_lag3 aecount_lag4 aecount_lag5 ///
						aecount_lag6)
drop aecount*

* Smoothed (over 7 days) rate of A&E attendances 
gen aerate = 100000*aemean/population
label var aerate "Smoothed rate of A&E attendances over last 7 days (per 100,000)"
drop aemean

	
	

/*  Save data for descriptive plots  */

format date %td
label var population "TPP population used for case count" 
label var date "Date"


* Label and save dataset
label data "A&E COVID-19 attendances, smoothed rates over time"
save "data/ae_rates", replace




*****************************************
*  Quadratic coefficients for A&E data  *
*****************************************

	
/*  Create lagged A&E attendance variables  */


* Only keep dates needed to create sufficient lags
drop if date < d(1mar2020) - $maxlag

rename aerate aerate_lag
forvalues t = 1 (1) $maxlag {
	bysort stp_combined (date): gen aerate_lag`t' = aerate_lag[_n-`t']
}
rename aerate_lag aerate_lag0

* Set earlier missing values to zero (no data, i.e. zero count)
forvalues t =  1 (1) $maxlag {
	replace aerate_lag`t' = 0 if aerate_lag`t' ==.
}

* Only keep dates from (day before) 1 March onwards
drop if date < d(1mar2020) - 1

* Drop dates after the 7 june
drop if date > d(7June2020) 



/*  Fit quadratic model to A&E data  */

gen aerate_init = aerate_lag0


* Fit quadratic model to infection proportion over last "lag" days
reshape long aerate_lag, i(date stp_combined) j(lag)
replace lag = -lag

statsby ae_q_cons	=_b[_cons] 									///
		ae_q_day	=_b[lag] 									///
		ae_q_daysq	=_b[c.lag#c.lag]	 						///
		, by(stp_combined stpname date aerate_init) clear: 		///
	regress aerate_lag c.lag##c.lag
rename aerate_init aerate





******************************
*  Keep only 100 days data   *
******************************

*  Days since cohort start date  
gen time = date - d(1mar2020) + 2
drop date

* Keep days 1-100
keep if inrange(time, 1, 100)



***************************************************
*  Create required functions of A&E coefficients  *
***************************************************

gen aepos = aerate
noi summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

noi di "CORRECTION FACTOR (for zero A&E rates) USED:   " r(min)/2

gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons

replace aeqd  = 0 if ae_q_cons==0
replace aeqds = 0 if ae_q_cons==0

gen aeqint 		= aeqd*aeqds
gen aeqd2		= aeqd^2
gen aeqds2		= aeqds^2




*************************
*  Tidy and save data   *
*************************

* Label variables
label var time 			"From 1 (29Feb, data for predicting 1Mar) to 100 (7Jun for predicting 8Jun)"
label var stpname 		"Sustainability and Transformation Partnership"
label var stp_combined 	"STP combined for smaller areas"
label var aerate		"A&E attendances (mean daily rate over last 7 days)"
label var aepos			"A&E COVID-19 rate (no zeros)"
label var logae			"Log of the A&E COVID-19 rate" 
label var ae_q_cons 	"Quadratic model of A&E attendances: constant coefficient"
label var ae_q_day		"Quadratic model of A&E attendances: linear coefficient"
label var ae_q_daysq	"Quadratic model of A&E attendances: squared coefficient"
label var aeqd			"Standardised quadratic term, day, A&E"
label var aeqds 		"Standardised quadratic term, day-squared, A&E"
label var aeqint 		"Standardised quadratic term, interaction, A&E"
label var aeqd2			"Standardised quadratic term, day^2, A&E"
label var aeqds2		"Standardised quadratic term, day-squared^2, A&E"	

* Order and sort variables
order time stp* aerate aepos logae ae_q_cons ae_q_day ae_q_daysq	///
			aeqd aeqds aeqint aeqd2 aeqds2
sort stp_combined time

* Label and save dataset
label data "A&E attendance data, rate over last week and quadratic model"
save "data/ae_coefs", replace


* Close the log file
log close







