********************************************************************************
*
*	Do-file:			1702_cstatistic_graph.do
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
*	Purpose:			This do-file tidies the validation data for approach A,
*						B and C models to copy and paste to Word.
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
replace approach = "B (ME)" if regexm(prediction, "foi")
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
replace approach = "B (ME)" if regexm(prediction, "foi")
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






****************
*  Graph data  *
****************

gen xaxis = model
replace xaxis = xaxis + 8  if approach == "B (ME)"
replace xaxis = xaxis + 16 if approach == "B (AE)"
replace xaxis = xaxis + 24 if approach == "B (GP)"

local tsex0 = "Females, "
local tsex1 = "Males, "

local tage1 = "Age 18-<70"
local tage2 = "Age 70-<80"
local tage3 = "Age 80+"

* Model: 
* 1 Age/sex
* 2 Comorbid
* 3 COVID=AGE
* 4 Selected
* 5 All


forvalues i = 1 (1) 3 {
    forvalues j = 0 (1) 1 {
	    local title = "`tsex`j''" + "`tage`i''" 
	twoway 	(scatter cstat xaxis if model==1 & age==`i' & sex==`j' & vp==1, msize(small) 	msymbol(square)   mcolor(navy))		///
			(scatter cstat xaxis if model==2 & age==`i' & sex==`j' & vp==1, msize(small) 	msymbol(circle)   mcolor(maroon))		///
			(scatter cstat xaxis if model==3 & age==`i' & sex==`j' & vp==1, msize(medlarge) msymbol(X)        mcolor(orange))		///
			(scatter cstat xaxis if model==4 & age==`i' & sex==`j' & vp==1, msize(small) 	msymbol(triangle) mcolor(green))		///
			(scatter cstat xaxis if model==5 & age==`i' & sex==`j' & vp==1, msize(small) 	msymbol(diamond)  mcolor(gs8))			///
			(scatter cstat xaxis if model==1 & age==`i' & sex==`j' & vp==2, msize(small) 	msymbol(square)   mcolor(navy))	///
			(scatter cstat xaxis if model==2 & age==`i' & sex==`j' & vp==2, msize(small) 	msymbol(circle)   mcolor(maroon))	///
			(scatter cstat xaxis if model==3 & age==`i' & sex==`j' & vp==2, msize(medlarge) msymbol(X)        mcolor(orange))	///
			(scatter cstat xaxis if model==4 & age==`i' & sex==`j' & vp==2, msize(small) 	msymbol(triangle) mcolor(green))	///
			(scatter cstat xaxis if model==5 & age==`i' & sex==`j' & vp==2, msize(small) 	msymbol(diamond)  mcolor(gs8))		///
			(scatter cstat xaxis if model==1 & age==`i' & sex==`j' & vp==3, msize(small) 	msymbol(square)   mcolor(navy))	///
			(scatter cstat xaxis if model==2 & age==`i' & sex==`j' & vp==3, msize(small) 	msymbol(circle)   mcolor(maroon))	///
			(scatter cstat xaxis if model==3 & age==`i' & sex==`j' & vp==3, msize(medlarge) msymbol(X)        mcolor(orange))	///
			(scatter cstat xaxis if model==4 & age==`i' & sex==`j' & vp==3, msize(small) 	msymbol(triangle) mcolor(green))	///
			(scatter cstat xaxis if model==5 & age==`i' & sex==`j' & vp==3, msize(small) 	msymbol(diamond)  mcolor(gs8))		///
			, legend(order(1 2 3 4 5) label(1 "Age-sex") label(2 "Comorbidities") label(3 "COVID-AGE")							/// 
			label(4 "Selected") label(5 "Full") col(5) size(small))																///
			xlabel(3 "A" 10.5 "B (ME)" 18.5 "B (AE)" 26.5 "B (GP)")																///
			yscale(range(0.50 1)) ylabel(0.5 (0.1) 1, angle(0)) 																///
			ytitle("") xtitle("") subtitle("`title'")
	graph save output/graph_cstat_`i'_`j'.gph, replace
	}
}



grc1leg output/graph_cstat_1_0.gph output/graph_cstat_1_1.gph	///
		output/graph_cstat_2_0.gph output/graph_cstat_2_1.gph	///
		output/graph_cstat_3_0.gph output/graph_cstat_3_1.gph, colfirst

graph display, ysize(3) scale(*1.25)

