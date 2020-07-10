
* cd needs to be the overall repo folder
* data/ and output/ need to be added to file paths

import delimited "analysis/input.csv", clear
set more off


* Region (coding does not match server)
replace region= "East" if region=="East of England"
replace region = "Yorkshire and The Humber" if ///
	region == "Yorkshire and the Humber"
