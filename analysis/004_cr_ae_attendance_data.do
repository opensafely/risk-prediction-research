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





/*  Import AE attendance data  */

* Import first row (dates)
import delimited "data/stp_ae_attendances.csv", ///
	varnames(nonames) rowrange(1:1) colrange(2) clear 

gen cons = 1
reshape long v, i(cons) j(day)

gen date = date(v, "DMY")
format date %td
drop v cons
save "tempdate", replace


* Import remaining rows (counts)
import delimited "data/stp_ae_attendances.csv", ///
	varnames(nonames) rowrange(2) clear 

egen stp = group(v1)
rename v1 stpcode
order stp stpcode

foreach var of varlist v* {
	recode `var' .=0
}

reshape long v, i(stp) j(day)
rename v aecount
replace day = day-1

merge m:1 day using "tempdate", assert(match) nogen
drop day


/*  Smooth AE attendance counts (mean over last 7 days) */

forvalues t = 0 (1) 6 {
	bysort stp (date): gen aecount_lag`t' = aecount[_n-`t']
}
egen aemean = rowmean( aecount_lag0 aecount_lag1 aecount_lag2 ///
						aecount_lag3 aecount_lag4 aecount_lag5 ///
						aecount_lag6)
drop aecount*
label var aemean "Mean A&E attendances over last 7 days"
						
						
						
	
/*  Create lagged A&E attendance variables  */


* Only keep dates needed to create sufficient lags
drop if date < d(1mar2020) - $maxlag

rename aemean aemean_lag
forvalues t = 1 (1) $maxlag {
	bysort stp (date): gen aemean_lag`t' = aemean_lag[_n-`t']
}
rename aemean_lag aemean_lag0

* Only keep dates from (day before) 1 March onwards
drop if date < d(29feb2020)



/*  Fit quadratic model to A&E data  */

gen aemean_init = aemean_lag0


* Fit quadratic model to infection proportion over last "lag" days
reshape long aemean_lag, i(date stp) j(lag)
replace lag = -lag

preserve
statsby ae_q_cons	=_b[_cons] 								///
		ae_q_day	=_b[lag] 								///
		ae_q_daysq	=_b[c.lag#c.lag]	 					///
		, by(stp stpcode date aemean_init) clear: 			///
	regress aemean_lag c.lag##c.lag
save "quadratic", replace
restore
statsby ae_c_cons	=_b[_cons] 								///
		ae_c_day	=_b[lag] 								///
		ae_c_daysq	=_b[c.lag#c.lag]	 					///
		ae_c_daycu	=_b[c.lag#c.lag#c.lag]					///
		, by(stp stpcode date aemean_init) clear: 			///
	regress aemean_lag c.lag##c.lag##c.lag
merge 1:1 stp date using "quadratic", assert(match) nogen
rename aemean_init aemean

* Delete data not needed
erase "quadratic.dta"


/*  Days since cohort start date  */

gen time = date - d(1mar2020) + 2
drop date



/*  Tidy and save data  */

	
* Label variables
label var time 			"Days since 1 March 2020 (inclusive)"
label var aemean		"A&E attendances (mean daily count over last 7 days)"
label var ae_q_cons 	"Quadratic model of A&E attendances: constant coefficient"
label var ae_q_day		"Quadratic model of A&E attendances: linear coefficient"
label var ae_q_daysq	"Quadratic model of A&E attendances: squared coefficient"
label var ae_c_cons 	"Cubic model of A&E attendances: constant coefficient"
label var ae_c_day		"Cubic model of A&E attendances: linear coefficient"
label var ae_c_daysq	"Cubic model of A&E attendances: squared coefficient"
label var ae_c_daycu	"Cubic model of A&E attendances: cubed coefficient"
label var stp 			"Sustainability and Transformation Partnership"
label var stpcode 		"Sustainability and Transformation Partnership"

* Order and sort variables
order time stp* aemean ae_q_cons ae_q_day ae_q_daysq	///
		ae_c_cons ae_c_day ae_c_daysq ae_c_daycu
sort stp time

* Label and save dataset
label data "A&E attendance data, mean over last week and quadratic/cubic model"
save "data/ae_coefs", replace


* Close the log file
log close