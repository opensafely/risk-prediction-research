
* cd needs to be the overall repo folder
* data/ and output/ need to be added to file paths


* To obtain output/input.csv :
*  OPEN ANACONDA PROMPT
*  CHANGE CD TO REPO FOLDER
*  command:  cohortextractor generate_cohort --expectations-population 10000



clear all
import delimited "output/input.csv", clear
set more off


gen temp=ceil(uniform()*10)
sort temp


gen hhid1 = _n if temp==1

forvalues j = 1 (1) 9 {
	local k = `j' + 1
	qui sum hhid`j'
	local start = r(max) + 1
	egen hhid`k' = seq() if temp==`k', from(`start') block(`k') 
}

drop household_id
gen household_id = hhid1 if hhid1<.
forvalues j = 2 (1) 10 {
	replace household_id = hhid`j' if hhid`j'<.
}
drop hhid* temp



