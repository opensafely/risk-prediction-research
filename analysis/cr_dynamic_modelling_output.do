********************************************************************************
*
*	Do-file:			cr_dynamic_modelling_output.do
*
*	Written by:			Fizz
*
*	Data used:			posteriors.dta
*						infected_coefs_dm.dta (burden of infection over time)
*
*	Data created:		infected_coefs_dm.dta (burden of infection over time)
*
*	Other output:		None
*
********************************************************************************
*
*	Purpose:			To create a dataset containing estimates of the burden
*						of infection over time by age, sex, and region. 
*
********************************************************************************



shell rename posteriors.do posteriors.csv

* Open a log file
capture log close
log using "output/cr_dynamic_modelling_output", text replace

*** PARAMETER NEEDED:  max days from infection to death
global lag = 21

* Open dataset 
import delimited "posteriors.csv", clear 
*use "posteriors.dta", clear

capture rename R r
capture rename S s
capture rename Ip ip
capture rename Is is
capture rename Ia ia


* Age-group
rename group agegroup
keep if inlist(agegroup, 3, 6, 8, 10, 12, 13)
recode agegroup 3=1 6=2 8=3 10=4 12=5 13=6
label define agegroup  1 "18-<40" 	///
					   2 "40-<50"	///
					   3 "50-<60"	///
					   4 "60-<70"	///
					   5 "70-<80"	///
					   6 "80+"
label values agegroup agegroup

gen date = 21929 + t
format date %d
* 1 march = (t=46)

* Days since 1 March 2020
replace t = t-46
label var t "Days since 1 March 2020" 
rename t time

* Region 
drop if population=="Wales"
drop if population=="Scotland"
drop if population=="Northern Ireland"
rename population region_small

* Population total
bysort region agegroup (t): gen N = s[1]


* Proportion dead
bysort region agegroup (t): gen cumdead = sum(death_o)
replace cumdead = cumdead/N


* Proportion recovered  (how to account for deaths)?
gen immune = (r/N)*(1-cumdead)

* Proportion infected today
gen infect = (ip+ is+ ia)/ N


keep time date region agegroup immune infect

forvalues i = 0 (1) $lag {
	bysort region agegroup (t): gen infect_lag`i' = infect[_n-`i']
}
keep if time>=0
drop infect


**************************
*  9 days infection lag  *
**************************

* Fit quadratic model to infection proportion over last "lag" days
reshape long infect_lag, i(time date region agegroup immune) j(day)
replace day = -day
statsby cons=_b[_cons] 						///
		day=_b[day] 						///
		daysq=_b[c.day#c.day]	 			///
		, by(region agegroup time) clear: 	///
	regress infect_lag c.day##c.day
save "infected_coefs_dm", replace


	
* Close the log file
log close



