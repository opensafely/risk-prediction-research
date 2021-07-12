********************************************************************************
*
*	Do-file:			1703_intext_table.do
*
*	Written by:			Fizz & John
*
*	Data used:			output/
*							approach_a_validation_28day.out
*							approach_a_validation_28day_agesex.out
*							approach_a_validation_28day_intext.out
*							approach_a_validation_full_period.out
*							approach_a_validation_full_period_intext.out
*
*	Data created:		None
*
*	Other output:		None

********************************************************************************
*
*	Purpose:			This do-file tidies the validation data for approach A,
*						B and C models to copy and paste to Word.
*
********************************************************************************




***************************
*  Program to tidy data   *
***************************

capture program drop model_intextstat
program define model_intextstat

	syntax, inputdata(string)   

	* Read in data
	import delimited "`inputdata'", clear


	/*  Overall model accuracy  */

	* Brier score
	drop brier_p brier
	
	
	/*  Discrimination  */

	* C-statistic
	drop c_stat_p
	rename c_stat cstat
	replace cstat = cstat
	format cstat %04.3f

	/*  Calibration  */

	* Mean and observed predictions - put as %	
	replace mean_obs  = 100*mean_obs
	replace mean_pred = 100*mean_pred

	format mean_obs  %05.4f
	format mean_pred %05.4f
		
		
	* Hosmer-Lemeshow
	drop hl_p hl
	
	* Calibration intercept and slope
	gen calib_inter_all = string(calib_inter, "%03.2f")  			///
						+ " (" + string(calib_inter_cl, "%03.2f")  	///
						+ ", " + string(calib_inter_cu, "%03.2f") + ")"	

	gen calib_slope_all = string(calib_slope, "%03.2f")  			///
						+ " (" + string(calib_slope_cl, "%03.2f")  	///
						+ ", " + string(calib_slope_cu, "%03.2f") + ")"
						
	drop calib_inter calib_inter_p calib_inter_se calib_inter_cl calib_inter_cu 
	drop calib_slope calib_slope_p calib_slope_se calib_slope_cl calib_slope_cu 
	
	* Validation period
	gen 	vp = 1 if period=="vp1"
	replace vp = 2 if period=="vp2"
	replace vp = 3 if period=="vp3"
	drop period
	
	  

end



*************************************
*  Tidy data from various analyses  *
*************************************


/*  Approach A: overall and internal-external validation  */


model_intextstat, inputdata("output\approach_a_validation_28day.out")
keep if regexm(prediction, "cox")
drop prediction
gen model = 1
save "data/intextstat_a_all", replace

model_intextstat, inputdata("output\approach_a_validation_28day_intext.out")  
keep if regexm(prediction, "cox")
drop prediction

gen 	model = 2 if loo=="Region 1 omitted"
replace model = 3 if loo=="Region 2 omitted"
replace model = 4 if loo=="Region 3 omitted"
replace model = 5 if loo=="Region 4 omitted"
replace model = 6 if loo=="Region 5 omitted"
replace model = 7 if loo=="Region 6 omitted"
replace model = 8 if loo=="Region 7 omitted"
replace model = 9 if loo=="Later time omitted"
drop loo
replace approach = "A"

save "data/intextstat_a_intext", replace




/*  Approach B: overall and internal-external validation  */


model_intextstat, inputdata("output\approach_b_validation_28day.out")
keep if regexm(prediction, "pois")
replace approach = "B (FOI)" if regexm(prediction, "foi")
replace approach = "B (AE)"  if regexm(prediction, "ae")
replace approach = "B (GP)"  if regexm(prediction, "susp")
drop prediction
gen model = 1
save "data/intextstat_b_all", replace



model_intextstat, inputdata("output\approach_b_validation_28day_intext.out")  
rename model prediction
keep if regexm(prediction, "pois")
replace approach = "B (FOI)" if regexm(tvc, "foi")
replace approach = "B (AE)"  if regexm(tvc, "ae")
replace approach = "B (GP)"  if regexm(tvc, "susp")
drop prediction tvc

gen 	model = 2 if loo=="Region 1 omitted"
replace model = 3 if loo=="Region 2 omitted"
replace model = 4 if loo=="Region 3 omitted"
replace model = 5 if loo=="Region 4 omitted"
replace model = 6 if loo=="Region 5 omitted"
replace model = 7 if loo=="Region 6 omitted"
replace model = 8 if loo=="Region 7 omitted"
replace model = 9 if loo=="Later time omitted"
drop loo

save "data/intextstat_b_intext", replace



/*  Combine data  */

use "data/intextstat_a_all", clear
append using "data/intextstat_a_intext"
append using "data/intextstat_b_all"
append using "data/intextstat_b_intext"

erase "data/intextstat_a_all.dta"
erase "data/intextstat_a_intext.dta"
erase "data/intextstat_b_all.dta"
erase "data/intextstat_b_intext.dta"


label define model 	1 "Main"			///
					2 "R{subscript:-1}" ///
					3 "R{subscript:-2}" ///
					4 "R{subscript:-3}" ///
					5 "R{subscript:-4}" ///
					6 "R{subscript:-5}" ///
					7 "R{subscript:-6}" ///
					8 "R{subscript:-7}" ///
					9 "R{subscript:-T}" 
label values model model

gen 	app = 1 if approach=="A"
replace app = 2 if approach=="B (FOI)"
replace app = 3 if approach=="B (AE)"
replace app = 4 if approach=="B (GP)"

gen model_offset = model
replace model_offset = model_offset - 0.1 if vp==1
replace model_offset = model_offset + 0.1 if vp==3
label values model_offset model


gen 	model_offset2 = model +  0 if inrange(model, 2, 8) & vp==1
replace model_offset2 = model + 11 if inrange(model, 2, 8) & vp==2
replace model_offset2 = model + 22 if inrange(model, 2, 8) & vp==3
label values model_offset2 model




************************************
*  Temporal:  Tidy data for table  *
************************************

save temp, replace
keep if inlist(app, 1, 2)
keep if model==9
drop model

order approach vp cstat mean_obs mean_pred calib_inter calib_slope
drop model_offset model_offset2 app
sort approach vp 






****************************************
*  Geographical:  Tidy data for table  *
****************************************

use temp, replace
keep if inlist(app, 1, 2)
keep if inrange(model, 2, 8)
gen region = model-1
drop model

label define region 1 "East"				///
					2 "London"				///
					3 "Midlands"			///
					4 "North East/Yorks" 	///
					5 "North West"			///
					6 "South East"			///
					7 "South West"
label values region region

order approach vp region cstat mean_obs mean_pred calib_inter calib_slope
drop model_offset model_offset2 app
sort approach vp region


erase temp.dta












