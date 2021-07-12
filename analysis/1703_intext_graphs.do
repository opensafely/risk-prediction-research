********************************************************************************
*
*	Do-file:			1703_intext_graphs.do
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
*	Purpose:			This do-file creates a graph of the measures of model
*						performance from the internal-external validation.
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
	

	/*  Calibration  */

	* Mean and observed predictions - put as %	
	replace mean_obs  = 100*mean_obs
	replace mean_pred = 100*mean_pred

		
	* Hosmer-Lemeshow
	drop hl_p hl
	
	* Calibration intercept
	drop calib_inter_p calib_inter_se calib_inter_cl calib_inter_cu 

	* Calibration slope
	drop calib_slope_p calib_slope_se calib_slope_cl calib_slope_cu 
	
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






********************************************************************************
***						 	Graphs  										 ***
********************************************************************************

*************************
*  Internal validation  *
*************************

/*  Graph C-statistics  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"

forvalues a = 1 (1) 4 {
	twoway 	(scatter cstat vp if vp==1, msize(medium) 	msymbol(square)   mcolor(navy))		///
			(scatter cstat vp if vp==2, msize(medlarge) msymbol(triangle) mcolor(orange))	///
			(scatter cstat vp if vp==3, msize(medium)   msymbol(diamond)  mcolor(maroon))	///
			if app==`a' & model==1, ///
			yscale(range(0.8 1)) ylabel(0.8 (0.1) 1, angle(0) labsize(large)) ytick(0.8 (0.05) 1, grid)							///
			ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
			xlabel(none) xscale(range(0.75 3.25)) 	///
			legend(order(1 2 3) label(1 "Period 1") label(2 "Period 2") label(3 "Period 3") col(3))
	graph save "output/graph_intext_cstat_`a'", replace
}

grc1leg output/graph_intext_cstat_1.gph 	///
		output/graph_intext_cstat_2.gph 	///
		output/graph_intext_cstat_3.gph 	///
		output/graph_intext_cstat_4.gph, col(4)	///
		t1title("C-statistic", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_cstat, replace


/*  Graph mean predictions  */

local ta1 = "A"
local ta2 = "B (ME)"
local ta3 = "B (AE)"
local ta4 = "B (GP)"

forvalues i = 1 (1) 3 {
    qui summ mean_obs if vp==`i'
	local mp`i' = r(mean)
}

forvalues a = 1 (1) 4 {
	twoway 	(function y = `mp1', lcolor(navy*0.75) lpattern(dash)   range(0.75 3.25))	///
			(function y = `mp2', lcolor(orange*0.75) lpattern(dash) range(0.75 3.25))	///
			(function y = `mp3', lcolor(maroon*0.75) lpattern(dash) range(0.75 3.25))	///
			(scatter mean_pred vp if vp==1, msize(medium)    msymbol(square)   mcolor(navy))		///
			(scatter mean_pred vp if vp==2, msize(medlarge)  msymbol(triangle) mcolor(orange))	///
			(scatter mean_pred vp if vp==3, msize(medium)    msymbol(diamond)  mcolor(maroon))	///
	if app==`a' & model==1, ///
				yscale(range(0 0.065)) ylabel(0 (0.02) 0.06, angle(0) labsize(large)) ///
				ytick(0 (0.01) 0.06, grid) 	///
				ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
				xlabel(none) xscale(range(0.75 3.25)) 		///
			legend(order(4 5 6) label(4 "Period 1") label(5 "Period 2") label(6 "Period 3") col(3))
	graph save "output/graph_intext_meanpred_`a'", replace
}

grc1leg output/graph_intext_meanpred_1.gph 	///
		output/graph_intext_meanpred_2.gph 	///
		output/graph_intext_meanpred_3.gph 	///
		output/graph_intext_meanpred_4.gph, col(4) ///
		t1title("Overall mean prediction (%)", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_meanpred, replace


/*  Graph calibration intercept  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"

forvalues a = 1 (1) 4 {
	twoway 	(function y = 0, lcolor(gs8) lpattern(dot) range(0.75 3.25))	///
			(scatter calib_inter vp if vp==1, msize(medium) msymbol(square)      mcolor(navy))	///
			(scatter calib_inter vp if vp==2, msize(medlarge) msymbol(triangle) mcolor(orange))	///
			(scatter calib_inter vp if vp==3, msize(medium) msymbol(diamond)     mcolor(maroon))	///
			if app==`a' & model==1, ///
				yscale(range(-2.5 2.75)) ylabel(-2 (2) 2, angle(0) labsize(large)) /// 	
				ytick(-2 (1) 2, grid) 	///
				ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
				xlabel(none) xscale(range(0.75 3.25)) 		///
			legend(order(2 3 4) label(2 "Period 1") label(3 "Period 2") label(4 "Period 3") col(3))
	graph save "output/graph_intext_calibi_`a'", replace
}

grc1leg output/graph_intext_calibi_1.gph 	///
		output/graph_intext_calibi_2.gph 	///
		output/graph_intext_calibi_3.gph 	///
		output/graph_intext_calibi_4.gph, col(4) ///
		t1title("Calibration intercept", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_calibi, replace


/*  Graph calibration slope  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"


forvalues a = 1 (1) 4 {
	twoway 	(function y = 1, lcolor(navy) lpattern(dot) range(0.75 3.25))						///
			(scatter calib_slope vp if vp==1, msize(medium)    msymbol(square)   mcolor(navy))	///
			(scatter calib_slope vp if vp==2, msize(medlarge) msymbol(triangle) mcolor(orange))	///
			(scatter calib_slope vp if vp==3, msize(medium)    msymbol(diamond)  mcolor(maroon))	///
			(function y = 1, lcolor(navy) lpattern(dot) range(0.75 3.25))						///
			if app==`a' & model==1, ///
				yscale(range(0.5 1.5)) ylabel(0.5 (0.5) 1.5, angle(0) labsize(large)) /// 	 
				ytick(0.5 (0.25) 1.5, grid) 	///
				ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
				xlabel(none) xscale(range(0.75 3.25)) 		///
			legend(order(2 3 4) label(2 "Period 1") label(3 "Period 2") label(4 "Period 3") col(3))
	graph save "output/graph_intext_calibs_`a'", replace
}

grc1leg output/graph_intext_calibs_1.gph 	///
		output/graph_intext_calibs_2.gph 	///
		output/graph_intext_calibs_3.gph 	///
		output/graph_intext_calibs_4.gph, col(4) ///
		t1title("Calibration slope", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_calibs, replace


/*  Combine graphs  */

grc1leg output/graph_intext_cstat.gph 		///
		output/graph_intext_meanpred.gph 	///
		output/graph_intext_calibi.gph 		///
		output/graph_intext_calibs.gph, 	///
		col(1) imargin(tiny)

graph display, scale(0.5)
graph save output/graph_internal_validation, replace









*************************
*  Temporal validation  *
*************************

capture recode model 9=2 1=1 2/8=., gen(temp)


/*  Graph C-statistics  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"

forvalues a = 1 (1) 4 {
	twoway 	(scatter cstat temp if vp==3 & temp==1, msize(medium) msymbol(diamond_hollow) mcolor(maroon))	///
			(scatter cstat temp if vp==3 & temp==2, msize(medium) msymbol(diamond)        mcolor(maroon))	///
			if app==`a', 														///
			yscale(range(0.8 1)) ylabel(0.8 (0.1) 1, angle(0) labsize(large)) 	///
			ytick(0.8 (0.05) 1, grid)											///
			ytitle("") xtitle("") subtitle("`ta`a''", size(large))				///
			xlabel(none) xscale(range(0.75 2.25)) 								///
			legend(order(1 2) subtitle("Validation period 3:") label(1 "Internal validation") label(2 "Temporal validation")  col(3))
	graph save "output/graph_intext_cstat_`a'", replace
}

grc1leg output/graph_intext_cstat_1.gph 	///
		output/graph_intext_cstat_2.gph 	///
		output/graph_intext_cstat_3.gph 	///
		output/graph_intext_cstat_4.gph, col(4)	///
		t1title("C-statistic", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_cstat, replace


/*  Graph mean predictions  */

local ta1 = "A"
local ta2 = "B (ME)"
local ta3 = "B (AE)"
local ta4 = "B (GP)"

forvalues i = 3 (1) 3 {
    qui summ mean_obs if vp==`i'
	local mp`i' = r(mean)
}

forvalues a = 1 (1) 4 {
	twoway 	(scatter mean_pred temp if vp==3 & temp==1, msize(medium) msymbol(diamond_hollow) mcolor(maroon)) ///
			(scatter mean_pred temp if vp==3 & temp==2, msize(medium) msymbol(diamond)        mcolor(maroon)) ///
			(function y = `mp3', lcolor(maroon) lpattern(dash) range(0.75 2.25))	///
			if app==`a', 															///
			yscale(range(0 0.065)) ylabel(0 (0.02) 0.06, angle(0) labsize(large)) 	/// 	 
			ytick(0 (0.01) 0.06, grid)												///
			ytitle("") xtitle("") subtitle("`ta`a''", size(large))					///
			xlabel(none) xscale(range(0.75 2.25)) 									///
			legend(order(1 2) subtitle("Validation period 3:") label(1 "Internal validation") label(2 "Temporal validation")  col(3))
	graph save "output/graph_intext_meanpred_`a'", replace
}

grc1leg output/graph_intext_meanpred_1.gph 	///
		output/graph_intext_meanpred_2.gph 	///
		output/graph_intext_meanpred_3.gph 	///
		output/graph_intext_meanpred_4.gph, col(4) ///
		t1title("Overall mean prediction (%)", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_meanpred, replace


/*  Graph calibration intercept  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"

forvalues a = 1 (1) 4 {
	twoway 	(scatter calib_inter temp if vp==3 & temp==1, msize(medium) msymbol(diamond_hollow) mcolor(maroon)) ///
			(scatter calib_inter temp if vp==3 & temp==2, msize(medium) msymbol(diamond)        mcolor(maroon)) ///
			(function y = 0, lcolor(gs8) lpattern(dot) range(0.75 2.25))		///
			if app==`a', 														///
			yscale(range(-2.5 2.75)) ylabel(-2 (2) 2, angle(0) labsize(large)) 	/// 	 
			ytick(-2 (1) 2, grid)												///
			ytitle("") xtitle("") subtitle("`ta`a''", size(large))				///
			xlabel(none) xscale(range(0.75 2.25)) 								///
			legend(order(1 2) subtitle("Validation period 3:") label(1 "Internal validation") label(2 "Temporal validation")  col(3))
	graph save "output/graph_intext_calibi_`a'", replace
}

grc1leg output/graph_intext_calibi_1.gph 	///
		output/graph_intext_calibi_2.gph 	///
		output/graph_intext_calibi_3.gph 	///
		output/graph_intext_calibi_4.gph, col(4) ///
		t1title("Calibration intercept", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_calibi, replace


/*  Graph calibration slope  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"


forvalues a = 1 (1) 4 {
	twoway 	(scatter calib_slope temp if vp==3 & temp==1, msize(medium) msymbol(diamond_hollow) mcolor(maroon)) ///
			(scatter calib_slope temp if vp==3 & temp==2, msize(medium) msymbol(diamond)        mcolor(maroon)) ///
			(function y = 1, lcolor(navy) lpattern(dot) range(0.75 2.25))			///
			if app==`a', 															///
			yscale(range(0.5 1.5)) ylabel(0.5 (0.5) 1.5, angle(0) labsize(large)) 	/// 	 
			ytick(0.5 (0.25) 1.5, grid)												///
			ytitle("") xtitle("") subtitle("`ta`a''", size(large))					///
			xlabel(none) xscale(range(0.75 2.25)) 									///
			legend(order(1 2) subtitle("Validation period 3:") label(1 "Internal validation") label(2 "Temporal validation")  col(3))
	graph save "output/graph_intext_calibs_`a'", replace
}

grc1leg output/graph_intext_calibs_1.gph 	///
		output/graph_intext_calibs_2.gph 	///
		output/graph_intext_calibs_3.gph 	///
		output/graph_intext_calibs_4.gph, col(4) ///
		t1title("Calibration slope", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_calibs, replace


/*  Combine graphs  */

grc1leg output/graph_intext_cstat.gph 		///
		output/graph_intext_meanpred.gph 	///
		output/graph_intext_calibi.gph 		///
		output/graph_intext_calibs.gph, 	///
		col(1) imargin(tiny)

graph display, scale(0.5)
graph save output/graph_temporal_validation, replace













***********************************************
*  Internal-external geographical validation  *
***********************************************

/*  Graph C-statistics  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"

forvalues a = 1 (1) 4 {
	twoway 	(scatter cstat model_offset2 if vp==1, msize(medium) 	msymbol(square)   mcolor(navy))		///
			(scatter cstat model_offset2 if vp==2, msize(medlarge) msymbol(triangle) mcolor(orange))	///
			(scatter cstat model_offset2 if vp==3, msize(medium)   msymbol(diamond)  mcolor(maroon))	///
			if app==`a' & inrange(model, 2, 8), ///
			yscale(range(0.8 1)) ylabel(0.8 (0.1) 1, angle(0) labsize(large)) ytick(0.8 (0.05) 1, grid)							///
			ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
			xlabel(none) xscale(range(0.75 3.25)) 	///
			legend(order(1 2 3) label(1 "Period 1") label(2 "Period 2") label(3 "Period 3") col(3))
	graph save "output/graph_intext_cstat_`a'", replace
}

grc1leg output/graph_intext_cstat_1.gph 	///
		output/graph_intext_cstat_2.gph 	///
		output/graph_intext_cstat_3.gph 	///
		output/graph_intext_cstat_4.gph, col(4)	///
		t1title("C-statistic", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_cstat, replace


/*  Graph mean predictions  */

local ta1 = "A"
local ta2 = "B (ME)"
local ta3 = "B (AE)"
local ta4 = "B (GP)"

forvalues i = 1 (1) 3 {
    qui summ mean_obs if vp==`i'
	local mp`i' = r(mean)
}

forvalues a = 1 (1) 4 {
	twoway 	(function y = `mp1', lcolor(navy*0.75) lpattern(dash)   range(0.75 30.25))	///
			(function y = `mp2', lcolor(orange*0.75) lpattern(dash) range(0.75 30.25))	///
			(function y = `mp3', lcolor(maroon*0.75) lpattern(dash) range(0.75 30.25))	///
			(scatter mean_pred model_offset2 if vp==1, msize(medium)    msymbol(square)   mcolor(navy))		///
			(scatter mean_pred model_offset2 if vp==2, msize(medlarge)  msymbol(triangle) mcolor(orange))	///
			(scatter mean_pred model_offset2 if vp==3, msize(medium)    msymbol(diamond)  mcolor(maroon))	///
	if app==`a'  & inrange(model, 2, 8), ///
				yscale(range(0 0.065)) ylabel(0 (0.02) 0.06, angle(0) labsize(large)) ///
				ytick(0 (0.01) 0.06, grid) 	///
				ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
				xlabel(none) xscale(range(0.75 3.25)) 		///
			legend(order(4 5 6) label(4 "Period 1") label(5 "Period 2") label(6 "Period 3") col(3))
	graph save "output/graph_intext_meanpred_`a'", replace
}

grc1leg output/graph_intext_meanpred_1.gph 	///
		output/graph_intext_meanpred_2.gph 	///
		output/graph_intext_meanpred_3.gph 	///
		output/graph_intext_meanpred_4.gph, col(4) ///
		t1title("Overall mean prediction (%)", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_meanpred, replace


/*  Graph calibration intercept  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"

forvalues a = 1 (1) 4 {
	twoway 	(function y = 0, lcolor(gs8) lpattern(dot) range(0.75 30.25))	///
			(scatter calib_inter model_offset2 if vp==1, msize(medium) msymbol(square)      mcolor(navy))	///
			(scatter calib_inter model_offset2 if vp==2, msize(medlarge) msymbol(triangle) mcolor(orange))	///
			(scatter calib_inter model_offset2 if vp==3, msize(medium) msymbol(diamond)     mcolor(maroon))	///
			if app==`a' & inrange(model, 2, 8), ///
				yscale(range(-2.5 2.75)) ylabel(-2 (2) 2, angle(0) labsize(large)) /// 	
				ytick(-2 (1) 2, grid) 	///
				ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
				xlabel(none) xscale(range(0.75 3.25)) 		///
			legend(order(2 3 4) label(2 "Period 1") label(3 "Period 2") label(4 "Period 3") col(3))
	graph save "output/graph_intext_calibi_`a'", replace
}

grc1leg output/graph_intext_calibi_1.gph 	///
		output/graph_intext_calibi_2.gph 	///
		output/graph_intext_calibi_3.gph 	///
		output/graph_intext_calibi_4.gph, col(4) ///
		t1title("Calibration intercept", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_calibi, replace


/*  Graph calibration slope  */

local ta1 = "A"
local ta2 = "B (FOI)"
local ta3 = "B (A&E)"
local ta4 = "B (GP)"


forvalues a = 1 (1) 4 {
	twoway 	(function y = 1, lcolor(navy) lpattern(dot) range(0.75 30.25))									///
			(scatter calib_slope model_offset2 if vp==1, msize(medium)    msymbol(square)   mcolor(navy))	///
			(scatter calib_slope model_offset2 if vp==2, msize(medlarge) msymbol(triangle) mcolor(orange))	///
			(scatter calib_slope model_offset2 if vp==3, msize(medium)    msymbol(diamond)  mcolor(maroon))	///
			if app==`a' & inrange(model, 2, 8), ///
				yscale(range(0.5 1.5)) ylabel(0.5 (0.5) 1.5, angle(0) labsize(large)) /// 	 
				ytick(0.5 (0.25) 1.5, grid) 	///
				ytitle("") xtitle("") subtitle("`ta`a''", size(large))	///
				xlabel(none) xscale(range(0.75 3.25)) 		///
			legend(order(2 3 4) label(2 "Period 1") label(3 "Period 2") label(4 "Period 3") col(3))
	graph save "output/graph_intext_calibs_`a'", replace
}

grc1leg output/graph_intext_calibs_1.gph 	///
		output/graph_intext_calibs_2.gph 	///
		output/graph_intext_calibs_3.gph 	///
		output/graph_intext_calibs_4.gph, col(4) ///
		t1title("Calibration slope", size(large))

graph display, ysize(2) scale(*1.25)
graph save output/graph_intext_calibs, replace


/*  Combine graphs  */

grc1leg output/graph_intext_cstat.gph 		///
		output/graph_intext_meanpred.gph 	///
		output/graph_intext_calibi.gph 		///
		output/graph_intext_calibs.gph, 	///
		col(1) imargin(tiny)

graph display, scale(0.5)
graph save output/graph_geographical_validation, replace



