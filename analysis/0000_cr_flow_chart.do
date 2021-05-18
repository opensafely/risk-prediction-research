********************************************************************************
*
*	Do-file:		000_cr_flow_chart.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		Data in memory (from input.csv)
*
*	Data created:   data/cr_base_cohort.dta (full base cohort dataset)
*
*	Other output:	Log file:  000_cr_flow_chart.log
*
********************************************************************************
*
*	Purpose:		This do-file creates a flow chart for the risk prediction
*					work.
*  
********************************************************************************






clear all
set more off

* Open a log file
cap log close
log using "output/000_cr_flow_chart", replace t




****************************
*  Create required cohort  *
****************************

* Import data
import delimited "output/input_flow_chart.csv", clear

* Count household number
bysort household_id: egen hh_num=count(patient_id)
drop household_id

* Total
qui count
noi di "Patients in import: "  _col(60) r(N)

* Registered as of index date
qui count if alive_at_cohort_start!=1
noi di _col(10) "- Not registered at index date:" _col(65) r(N)
qui drop if alive_at_cohort_start!=1
qui count
noi di "Registered at index date: "  _col(60) r(N)
	
* Dead prior to index date (late de-registrations)
qui confirm string variable died_date_ons
qui gen temp = date(died_date_ons, "YMD")
qui count if temp < `index'
noi di _col(10) "- Not alive at index date:" _col(65) r(N)
qui drop if temp < `index'
qui count
noi di "Alive at index date: "  _col(60) r(N)
	
* Households >= 10 people
qui count if hh_num >=10
noi di _col(10) "- Household size 10+:" _col(65) r(N)
qui drop if hh_num >=10
qui count
noi di "Houshold less than 10 people: "  _col(60) r(N)

* Age: Missing
qui count if age>=.
noi di _col(10) "- Age missing:" _col(65) r(N)
qui drop if age>=.
qui count
noi di "Age recorded: "  _col(60) r(N)

* Age: >105
qui count if age>105
noi di _col(10) "- Age greater than 105:" _col(65) r(N)
qui drop if  age>105
qui count
noi di "Age <= 105: "  _col(60) r(N)

* Age: <18
qui count if age<18
noi di _col(10) "- Age less than 18:" _col(65) r(N)
qui drop if  age<18
qui count
noi di "Age between 18 and 105: "  _col(60) r(N)
	
* Sex: Exclude categories other than M and F
qui count if inlist(sex, "I", "U")
noi di _col(10) "- Sex not M/F:" _col(65) r(N)
qui keep if inlist(sex, "M", "F")
qui count
noi di "Sex M/F: "  _col(60) r(N)

* STP: Missing
qui count if stp==""
noi di _col(10) "- Missing STP:" _col(65) r(N)
qui drop if stp==""
qui count
noi di "STP recorded: "  _col(60) r(N)
	
* Deprivation: Missing 
qui count if imd>=. | imd==-1
noi di _col(10) "- Missing deprivation (IMD):" _col(65) r(N)
qui drop if imd>=. | imd==-1
qui count
noi di "IMD available: "  _col(60) r(N)

* Ethnicity: Missing (only excluded in complete case)
qui count if ethnicity>=. 
noi di _col(10) "- Missing ethnicity:" _col(65) r(N)
qui drop if ethnicity>=.
qui count
noi di "Ethnicity available: "  _col(60) r(N)
	



* Close log file	
log close
