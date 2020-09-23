********************************************************************************
*
*	Do-file:			cr_dynamic_modelling_output.do
*
*	Written by:			Fizz
*
*	Data used:			analysis/foi-2020-07-10.csv
*
*	Data created:		data/foi_coefs.dta  (force of infection over time)
*
*	Other output:		None
*
********************************************************************************
*
*	Purpose:			To create a dataset containing estimates of the force
*						of infection over time by age, sex, and region. 
*
********************************************************************************




* Open a log file
capture log close
log using "output/cr_dynamic_modelling_output", text replace

*** PARAMETER NEEDED:  max days from infection to death
global maxlag = 21


*****************************
*  Force of infection data  *
*****************************

* Open dataset 
import delimited "analysis/foi-2020-07-10.csv", clear 
drop v1


/*  Date  */

rename date date_str
gen date = date(date_str, "DMY")
format date %td
drop date_str


/*  Age-groups  */

* Delete first four age-groups (0-5, 5-10, 10-15, 15-20)
drop if group<=4
replace group = group - 4
rename group agegroupfoi
label define agegroupfoi 	1 "20-24"	///
							2 "25-29"	///
							3 "30-34"	///
							4 "35-39"	///
							5 "40-44"	///
							6 "45-49"	///
							7 "50-54"	///
							8 "55-59"	///
							9 "60-64"	///
							10 "65-69"	///
							11 "70-74"	///
							12 "75+"
label values agegroupfoi agegroupfoi
label var agegroupfoi "Age-group (force of infection data)"


/*  Region  */

* Create numerical region variable to match cohort version
gen 	region_7 = 1 if population=="East of England"
replace region_7 = 2 if population=="London"
replace region_7 = 3 if population=="Midlands"
replace region_7 = 4 if population=="North East and Yorkshire"
replace region_7 = 5 if population=="North West"
replace region_7 = 6 if population=="South East"
replace region_7 = 7 if population=="South West"

* Delete data for devolved nations
drop if region_7==.
drop population
		  
* Label the region variable 
label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"



/*  Estimated force of infection  */

rename foi_mean foi
label var foi "Force of infection (mean of posterior; estimated)"


keep date agegroupfoi region_7 foi
order date agegroupfoi region_7 foi




/*  Create lagged force of infection variables  */


* Only keep dates needed to create sufficient lags
drop if date < d(1mar2020) - $maxlag

rename foi foi_lag
forvalues t = 1 (1) $maxlag {
	bysort region_7 agegroup (date): gen foi_lag`t' = foi_lag[_n-`t']
}
rename foi_lag foi_lag0

* Only keep dates from 1 March onwards
drop if date < d(1mar2020)



/*  Fit quadratic model to force of infection data  */

gen foi_init = foi_lag0

* Fit quadratic model to infection proportion over last "lag" days
reshape long foi_lag, i(date region_7 agegroupfoi foi_init) j(lag)

replace lag = -lag
statsby cons=_b[_cons] 						///
		day=_b[lag] 						///
		daysq=_b[c.lag#c.lag]	 			///
		, by(region_7 agegroupfoi date foi_init) clear: 	///
	regress foi_lag c.lag##c.lag
rename foi_init foi

	
/*  Days since cohort start date  */

gen time = date - d(1mar2020) + 1
drop date


/*  Tidy and save data  */


	
label var time 	"Days since 1 March 2020 (inclusive)"
label var foi 	"Estimated force of infection"
label var cons 	"Quadratic model of force of infection: constant coefficient"
label var day	"Quadratic model of force of infection: linear coefficient"
label var daysq	"Quadratic model of force of infection: squared coefficient"

order time region_7 agegroupfoi foi cons day daysq
sort region_7 agegroupfoi time
label data "Force of infection data, estimate and quadratic model"
save "data/foi_coefs", replace


* Close the log file
log close


