********************************************************************************
*
*	Do-file:			1701_model_performance_a.do
*
*	Written by:			Fizz & John
*
*	Data used:			output/
*							approach_a_validation_28day.out
*
*	Data created:		output/
*							approach_a_validation_full_period_tidy.out
*
*	Other output:		Dataset left in memory

********************************************************************************
*
*	Purpose:			This do-file tidies the validation data for approach A
*						models to copy and paste to Word.
*
********************************************************************************




***************************
*  Program to tidy data   *
***************************

capture program drop model_meas_tidy
program define model_meas_tidy

	syntax, inputdata(string)   

	* Read in data
	import delimited "`inputdata'", clear


	/*  Overall model accuracy  */

	* Brier score
	gen brier_p_str = string(round(brier_p, 0.001))
	replace brier_p_str = "=0"+brier_p_str
	replace brier_p_str = "<0.001" if brier_p_str=="=00"
	replace brier_p_str = ">0.99"  if brier_p_str=="=01"

	gen brier_str = "0" + string(brier) + " (p"+brier_p_str + ")"
	drop brier_p_str brier brier_p


	/*  Discrimination  */

	* C-statistic
	gen c_p_str = string(round(c_stat_p, 0.001))
	replace c_p_str = "=0"+c_p_str
	replace c_p_str = "<0.001" if c_p_str=="=00"

	gen cstat_str = string(round(100*c_stat, 0.1)) + " (p"+c_p_str + ")"
	drop c_stat c_stat_p c_p_str


	/*  Calibration  */

	* Hosmer=Lemeshow
	gen hl_p_str = string(round(hl_p, 0.001))
	replace hl_p_str = "=0"+hl_p_str
	replace hl_p_str = "<0.001" if hl_p_str=="=00"
	replace hl_p_str = ">0.99"  if hl_p_str=="=01"

	gen hl_str = string(round(hl, 0.1)) + " (p"+hl_p_str + ")"
	drop hl_p_str hl hl_p

	* Mean calibration
	gen pc_obs_risk  = "0"+string(100*mean_obs)
	gen pc_pred_risk = "0"+string(100*mean_pred)
	drop mean_obs mean_pred

	* Calibration intercept
	gen calib_inter_p_str = string(round(calib_inter_p, 0.001))
	replace calib_inter_p_str = "=0"+calib_inter_p_str
	replace calib_inter_p_str = "<0.001" if calib_inter_p_str=="=00"

	foreach var of varlist calib_inter calib_inter_cl calib_inter_cu {
		gen `var'_str = string(round(`var', 0.01))
		replace `var'_str = "0"+`var'_str if substr(`var'_str, 1, 1)=="."
		replace `var'_str = "-0."+substr(`var'_str, 3, .) if substr(`var'_str, 1, 2)=="-."
	}
	gen calib_inter_all_str = 	calib_inter_str + " (" 			///
								+ calib_inter_cl_str + ", " 	///
								+ calib_inter_cu_str + "), p" 	///
								+ calib_inter_p_str 
						
	drop calib_inter_str calib_inter_cl_str calib_inter_cu_str calib_inter_p_str ///
			calib_inter calib_inter_cl calib_inter_cu calib_inter_p calib_inter_se 


	* Calibration slope
	gen calib_slope_p_str = string(round(calib_slope_p, 0.001))
	replace calib_slope_p_str = "=0"+calib_slope_p_str
	replace calib_slope_p_str = "<0.001" if calib_slope_p_str=="=00"

	foreach var of varlist calib_slope calib_slope_cl calib_slope_cu {
		gen `var'_str = string(round(`var', 0.01))
		replace `var'_str = "0"+`var'_str if substr(`var'_str, 1, 1)=="."
		replace `var'_str = "-0."+substr(`var'_str, 3, .) if substr(`var'_str, 1, 2)=="-."
	}
	gen calib_slope_all_str = 	calib_slope_str + " (" 			///
								+ calib_slope_cl_str + ", " 	///
								+ calib_slope_cu_str + "), p" 	///
								+ calib_slope_p_str 
						
	drop calib_slope_str calib_slope_cl_str calib_slope_cu_str calib_slope_p_str ///
			calib_slope calib_slope_cl calib_slope_cu calib_slope_p calib_slope_se 

end




************************************
*  Approach A: 28 day validation   *
************************************


model_meas_tidy, inputdata("output\approach_a_validation_28day.out")  
		
/*  Tidy dataset  */

gen 	model = 1 if prediction=="pred_a_cox_nos"
replace model = 2 if prediction=="pred_a_roy_nos"
replace model = 3 if prediction=="pred_a_weibull_nos"
replace model = 4 if prediction=="pred_a_gamma_nos"
label define model 1 "Cox" 2 "Royston-Parmar" 3 "Weibull" 4 "Gamma"
label values model model
drop prediction

gen 	vp = 1 if period=="vp1"
replace vp = 2 if period=="vp2"
replace vp = 3 if period=="vp3"
drop period
	  
	  
sort vp model
order 	approach vp model		 	///
		brier_str 					///
		cstat_str					///
		pc_obs_risk pc_pred_risk 	///
		hl_str 			 			///
		calib_inter_all_str			///
		calib_slope_all_str			

outsheet using "output/approach_a_validation_28day_tidy.out", replace






*****************************************
*  Approach A: Full period validation   *
*****************************************


model_meas_tidy, inputdata("output\approach_a_validation_full_period.out")  

		
/*  Tidy dataset  */

gen 	model = 1 if prediction=="pred_a_cox_nos"
replace model = 2 if prediction=="pred_a_roy_nos"
replace model = 3 if prediction=="pred_a_weibull_nos"
replace model = 4 if prediction=="pred_a_gamma_nos"
label define model 1 "Cox" 2 "Royston-Parmar" 3 "Weibull" 4 "Gamma"
label values model model
drop prediction
drop period

sort model
order 	approach model			 	///
		brier_str 					///
		cstat_str					///
		pc_obs_risk pc_pred_risk 	///
		hl_str 			 			///
		calib_inter_all_str			///
		calib_slope_all_str			

outsheet using "output/approach_a_validation_full_period_tidy.out", replace