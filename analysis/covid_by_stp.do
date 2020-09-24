********************************************************************************
*
*	Do-file:		005_cr_covid_by_stp.do
*
*	Programmed by:	Alex (edited by Fizz)
*
*	Data used:		output/input_covid_by_stp.csv  
*						(generated from study_definition_covid_by_stp.py)

*	Data created:	data/covid_by_stp.dta
*
*	Other output:	Log file:  005_cr_covid_by_stp.log
*
********************************************************************************
*
*	Purpose:		This do-file cleans the GP suspected COVID-19 case data.  
*  
********************************************************************************



* Open a log file
cap log close
log using "output/005_cr_covid_by_stp", replace t





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

** Drop those without a code
drop if covid_suspected == ""

** Count patients per date and STP
collapse (count) patient_id, by(covid_suspected stp)
rename patient_id count

gen temp = date(covid_suspected, "YMD")
format temp %td
gen days_1feb = temp - d(1feb2020) + 1
drop temp

** Reshape
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

* Combine A&E counts within new combined STPs
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








save "data/covid_by_stp.dta", replace

* Close the log file
log close
