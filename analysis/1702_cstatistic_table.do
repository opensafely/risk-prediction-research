********************************************************************************
*
*	Do-file:			1702_cstatistic_table.do
*
*	Written by:			Fizz & John
*
*	Data used:			output/
*							approach_a_validation_28day_agesex.out
*							approach_b_validation_28day_agesex.out
*							approach_a_validation_28day_sens_agesex.out
*							approach_b_validation_28day_sens_agesex.out
*
*	Data created:		None
*
*	Other output:		None

********************************************************************************
*
*	Purpose:			This do-file creates a table of the C-statistics 
*						achieved by different predictor sets.
*
********************************************************************************




***************************
*  Program to tidy data   *
***************************

capture program drop model_cstat
program define model_cstat

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
	

	/*  Calibration  */

	* Hosmer-Lemeshow
	drop hl_p hl
	
	* Mean calibration
	drop mean_obs mean_pred

	* Calibration intercept
	drop calib_inter_p calib_inter calib_inter_se calib_inter_cl calib_inter_cu 

	* Calibration slope
	drop calib_slope_p calib_slope calib_slope_se calib_slope_cl calib_slope_cu 
	
	* Validation period
	gen 	vp = 1 if period=="vp1"
	replace vp = 2 if period=="vp2"
	replace vp = 3 if period=="vp3"
	drop period
	
	/* Demographics  */
	
	encode age, gen(agegp)
	drop age
	rename agegp age
	
	label define sex 1 "Male" 0 "Female"
	label values sex sex
	  

end



*************************************
*  Tidy data from various analyses  *
*************************************


/*  Approach A: 28 day validation by age and sex  */



model_cstat, inputdata("output/approach_a_validation_28day_agesex.out")  

keep if prediction=="pred_a_cox"
drop prediction

gen model = 4

isid vp age sex

save "data/cstat_a_agesex", replace


/*  Approach B: 28-day validation by age and sex  */



model_cstat, inputdata("output/approach_b_validation_28day_agesex.out")  

keep if regexm(prediction, "pois")
replace approach = "B (FOI)" if regexm(prediction, "foi")
replace approach = "B (AE)"  if regexm(prediction, "ae")
replace approach = "B (GP)"  if regexm(prediction, "susp")
drop prediction

gen model = 4

isid vp age sex approach

save "data/cstat_b_agesex", replace



/*  Approach A: Simpler models by age and sex  */


model_cstat, inputdata("output/approach_a_validation_28day_sens_agesex.out")  

drop if prediction=="pred_all"
drop if prediction=="pred_covidage"
replace prediction = "pred_all" if prediction=="pred_all2"

gen		model = 1 if prediction=="pred_agesex"
replace model = 2 if prediction=="pred_comorbid"
replace model = 3 if prediction=="covid_age"
replace model = 5 if prediction=="pred_all"
drop prediction

isid vp age sex model

save "data/cstat_asimple_agesex", replace



/*  Approach B: Simpler models by age and sex  */


model_cstat, inputdata("output/approach_b_validation_28day_sens_agesex.out")  

keep if regexm(prediction, "pois")
replace approach = "B (FOI)" if regexm(prediction, "foi")
replace approach = "B (AE)"  if regexm(prediction, "ae")
replace approach = "B (GP)"  if regexm(prediction, "susp")
drop if regexm(prediction, "objective")
drop if regexm(prediction, "_all_")


gen 	model = 1 if regexm(prediction, "agesex")
replace model = 2 if regexm(prediction, "comorbid")
replace model = 3 if regexm(prediction, "covid_age")
replace model = 5 if regexm(prediction, "all")
drop prediction

isid vp age sex approach model

save "data/cstat_bsimple_agesex", replace



/*  Combine data  */

use "data/cstat_a_agesex", clear
append using "data/cstat_b_agesex"
append using "data/cstat_asimple_agesex"
append using "data/cstat_bsimple_agesex"

erase "data/cstat_a_agesex.dta"
erase "data/cstat_b_agesex.dta"
erase "data/cstat_asimple_agesex.dta"
erase "data/cstat_bsimple_agesex.dta"





*******************************
*  Tidy data to put in table  *
*******************************

*keep if inlist(approach, "A", "B (FOI)")
reshape wide cstat, i(approach vp model age) j(sex)

rename cstat0 cstatfem
rename cstat1 cstatmal

reshape wide cstatfem cstatmal, i(approach vp model) j(age)


label define model  1 "Age-sex"			///
					2 "Comorbidities"	///
					3 "COVID-AGE"		///
					4 "Selected"		///
					5 "Full"
label values model model

order approach vp model cstat*


format cstat* %3.2f


