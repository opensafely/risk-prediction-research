********************************************************************************
*
*	Do-file:			004_cr_ae_attendance_data.do
*
*	Written by:			Fizz
*
*	Data used:			data/stp_ae_attendances.csv
*
*	Data created:		data/ae_coefs (A&E attendances over time)
*
*	Other output:		Log file:  004_cr_ae_attendance_data.log
*
********************************************************************************
*
*	Purpose:			To create a dataset containing summaries of A&E 
*						attendances over time by STP. 
*
********************************************************************************



* Open a log file
capture log close
log using "output/004_cr_ae_attendance_data", text replace

*** PARAMETER NEEDED:  max days from infection to death
global maxlag = 21





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

merge 1:1 stpcode using "temppop", assert(match) nogen
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
replace day = day-1

merge m:1 day using "tempdate", assert(match) nogen
drop day
erase "tempdate.dta"






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
label var aerate "Smoother rate of A&E attendances over last 7 days"
drop aemean

	
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



/*  Fit quadratic model to A&E data  */

gen aerate_init = aerate_lag0


* Fit quadratic model to infection proportion over last "lag" days
reshape long aerate_lag, i(date stp_combined) j(lag)
replace lag = -lag

preserve
statsby ae_q_cons	=_b[_cons] 								///
		ae_q_day	=_b[lag] 								///
		ae_q_daysq	=_b[c.lag#c.lag]	 					///
		, by(stp_combined stpname date aerate_init) clear: 			///
	regress aerate_lag c.lag##c.lag
save "quadratic", replace
restore
statsby ae_c_cons	=_b[_cons] 								///
		ae_c_day	=_b[lag] 								///
		ae_c_daysq	=_b[c.lag#c.lag]	 					///
		ae_c_daycu	=_b[c.lag#c.lag#c.lag]					///
		, by(stp_combined stpname date aerate_init) clear: 			///
	regress aerate_lag c.lag##c.lag##c.lag
merge 1:1 stp_combined date using "quadratic", assert(match) nogen
rename aerate_init aerate

* Delete data not needed
erase "quadratic.dta"


/*  Days since cohort start date  */

gen time = date - d(1mar2020) + 2
drop date



/*  Tidy and save data  */


* Label variables
label var time 			"Days since 1 March 2020 (inclusive)"
label var aerate		"A&E attendances (mean daily count over last 7 days)"
label var ae_q_cons 	"Quadratic model of A&E attendances: constant coefficient"
label var ae_q_day		"Quadratic model of A&E attendances: linear coefficient"
label var ae_q_daysq	"Quadratic model of A&E attendances: squared coefficient"
label var ae_c_cons 	"Cubic model of A&E attendances: constant coefficient"
label var ae_c_day		"Cubic model of A&E attendances: linear coefficient"
label var ae_c_daysq	"Cubic model of A&E attendances: squared coefficient"
label var ae_c_daycu	"Cubic model of A&E attendances: cubed coefficient"
label var stpname 		"Sustainability and Transformation Partnership"
label var stp_combined 	"STP combined for smaller areas"


* Order and sort variables
order time stp* aerate ae_q_cons ae_q_day ae_q_daysq	///
		ae_c_cons ae_c_day ae_c_daysq ae_c_daycu
sort stp_combined time

* Label and save dataset
label data "A&E attendance data, rate over last week and quadratic/cubic model"
save "data/ae_coefs", replace


* Close the log file
log close