********************************************************************************
*
*	Do-file:			1701_model_performance_measures_tidy.do
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
*	Data created:		output/
*							approach_a_validation_28day_tidy.out
*							approach_a_validation_28day_agesex_tidy.out
*							approach_a_validation_28day_intext_tidy.out
*							approach_a_validation_full_period_tidy.out
*							approach_a_validation_full_period_intext_tidy.out
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

	replace brier_str = substr(brier_str, 2, .)	///
		if regexm(substr(brier_str, 1, 3), "0[0-9].")	
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
	drop calib_slope_p

	foreach var of varlist calib_slope calib_slope_cl calib_slope_cu {
		gen `var'_str = string(round(`var', 0.01))
		replace `var'_str = "0"+`var'_str if substr(`var'_str, 1, 1)=="."
		replace `var'_str = "-0."+substr(`var'_str, 3, .) if substr(`var'_str, 1, 2)=="-."
	}
	gen calib_slope_all_str = 	calib_slope_str + " (" 			///
								+ calib_slope_cl_str + ", " 	///
								+ calib_slope_cu_str + ")" 	
						
	drop calib_slope_str calib_slope_cl_str calib_slope_cu_str  ///
			calib_slope calib_slope_cl calib_slope_cu calib_slope_se 

end




						*************************
						*  INTERNAL VALIDATION  *
						*************************

						
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



************************************
*  Approach B: 28-day validation   *
************************************


model_meas_tidy, inputdata("output\approach_b_validation_28day.out")  

		
/*  Tidy dataset  */

gen 	model = 1 if regexm(prediction, "pred_b_logit")
replace model = 2 if regexm(prediction, "pred_b_pois")
replace model = 3 if regexm(prediction, "pred_b_weib")
label define model 1 "Logistic" 2 "Poisson" 3 "Weibull" 
label values model model

gen 	tvc = 1 if regexm(prediction, "foi")
replace tvc = 2 if regexm(prediction, "ae")
replace tvc = 3 if regexm(prediction, "susp")
drop prediction

label define tvc 1 "FOI" 2 "A&E" 3 "Suspected GP" 
label values tvc tvc


gen 	vp = 1 if period=="vp1"
replace vp = 2 if period=="vp2"
replace vp = 3 if period=="vp3"
drop period

sort tvc vp model
order 	approach vp model tvc		///
		brier_str 					///
		cstat_str					///
		pc_obs_risk pc_pred_risk 	///
		hl_str 			 			///
		calib_inter_all_str			///
		calib_slope_all_str			

outsheet using "output/approach_b_validation_28day_tidy.out", replace




					****************************************
					*  INTERNAL VALIDATION BY AGE AND SEX  *
					****************************************


**************************************************
*  Approach A: 28 day validation by age and sex  *
**************************************************


model_meas_tidy, inputdata("output/approach_a_validation_28day_agesex.out")  
		
/*  Tidy dataset  */

gen 	model = 1 if prediction=="pred_a_cox"
replace model = 2 if prediction=="pred_a_roy"
replace model = 3 if prediction=="pred_a_weibull"
replace model = 4 if prediction=="pred_a_gamma"
label define model 1 "Cox" 2 "Royston-Parmar" 3 "Weibull" 4 "Gamma"
label values model model
drop prediction

gen 	vp = 1 if period=="vp1"
replace vp = 2 if period=="vp2"
replace vp = 3 if period=="vp3"
drop period

encode age, gen(agegp)
drop age

label define sex 1 "Male" 0 "Female"
label values sex sex

sort  age sex vp model
order  approach agegp sex model vp	///
		brier_str 					///
		cstat_str					///
		pc_obs_risk pc_pred_risk 	///
		hl_str 			 			///
		calib_inter_all_str			///
		calib_slope_all_str			

outsheet using "output/approach_a_validation_28day_agesex_tidy.out", replace




**************************************************
*  Approach B: 28-day validation by age and sex  *
**************************************************


model_meas_tidy, inputdata("output/approach_b_validation_28day_agesex.out")  

		
/*  Tidy dataset  */

gen 	model = 1 if regexm(prediction, "pred_b_logit")
replace model = 2 if regexm(prediction, "pred_b_pois")
replace model = 3 if regexm(prediction, "pred_b_weib")
label define model 1 "Logistic" 2 "Poisson" 3 "Weibull" 
label values model model

gen 	tvc = 1 if regexm(prediction, "foi")
replace tvc = 2 if regexm(prediction, "ae")
replace tvc = 3 if regexm(prediction, "susp")
drop prediction

label define tvc 1 "FOI" 2 "A&E" 3 "Suspected GP" 
label values tvc tvc

gen 	vp = 1 if period=="vp1"
replace vp = 2 if period=="vp2"
replace vp = 3 if period=="vp3"
drop period

encode age, gen(agegp)
drop age

label define sex 1 "Male" 0 "Female"
label values sex sex

		
sort  tvc age sex vp model
order  approach tvc agegp sex model vp	///
		brier_str 						///
		cstat_str						///
		pc_obs_risk pc_pred_risk 		///
		hl_str 			 				///
		calib_inter_all_str				///
		calib_slope_all_str			
		
outsheet using "output/approach_b_validation_28day_tidy.out", replace




					***********************************
					*  INTERNAL-EXTERNAL VALIDATION   *
					***********************************

					
******************************************************
*  Approach A: 28 day internal-external validation   *
******************************************************

model_meas_tidy, inputdata("output\approach_a_validation_28day_intext.out")  
		
gen calib_no_converge = 1 if regexm(calib_inter_all_str, "9999")
replace calib_inter_all_str = "(no convergence)" if  calib_no_converge==1
replace calib_slope_all_str = "(no convergence)" if  calib_no_converge==1
drop calib_no_converge


/*  Tidy dataset  */

gen 	model = 1 if regexm(prediction, "pred_a_cox")
replace model = 2 if regexm(prediction, "pred_a_roy")
replace model = 3 if regexm(prediction, "pred_a_weibull")
replace model = 4 if regexm(prediction, "pred_a_gamma")
label define model 1 "Cox" 2 "Royston-Parmar" 3 "Weibull" 4 "Gamma"
label values model model
drop prediction

gen 	vp = 1 if period=="vp1"
replace vp = 2 if period=="vp2"
replace vp = 3 if period=="vp3"
drop period
	  
gen 	omitted = 1 if loo=="Region 1 omitted"
replace omitted = 2 if loo=="Region 2 omitted"
replace omitted = 3 if loo=="Region 3 omitted"
replace omitted = 4 if loo=="Region 4 omitted"
replace omitted = 5 if loo=="Region 5 omitted"
replace omitted = 6 if loo=="Region 6 omitted"
replace omitted = 7 if loo=="Region 7 omitted"
replace omitted = 8 if loo=="Later time omitted"
label define omitted 	1 "Region 1"	///
						2 "Region 2"	///
						3 "Region 3"	///
						4 "Region 4"	///
						5 "Region 5"	///
						6 "Region 6"	///
						7 "Region 7"	///
						8 "Later time"
label values omitted omitted
drop loo
  
sort omitted vp model 
order 	approach vp omitted model 	///
		brier_str 					///
		cstat_str					///
		pc_obs_risk pc_pred_risk 	///
		hl_str 			 			///
		calib_inter_all_str			///
		calib_slope_all_str			

outsheet using "output/approach_a_validation_28day_intext_tidy.out", replace




******************************************************
*  Approach B: 28-day internal external validation   *
******************************************************


model_meas_tidy, inputdata("output/approach_b_validation_28day_intext.out")  


/*  Tidy dataset  */

rename model prediction
gen 	model = 1 if regexm(prediction, "logit")
replace model = 2 if regexm(prediction, "pois")
replace model = 3 if regexm(prediction, "weib")
label define model 1 "Logistic" 2 "Poisson" 3 "Weibull" 
label values model model
drop prediction

rename tvc prediction
gen 	tvc = 1 if regexm(prediction, "foi")
replace tvc = 2 if regexm(prediction, "ae")
replace tvc = 3 if regexm(prediction, "susp")
drop prediction

label define tvc 1 "FOI" 2 "A&E" 3 "Suspected GP" 
label values tvc tvc


gen 	vp = 1 if period=="vp1"
replace vp = 2 if period=="vp2"
replace vp = 3 if period=="vp3"
drop period
	  
gen 	omitted = 1 if loo=="Region 1 omitted"
replace omitted = 2 if loo=="Region 2 omitted"
replace omitted = 3 if loo=="Region 3 omitted"
replace omitted = 4 if loo=="Region 4 omitted"
replace omitted = 5 if loo=="Region 5 omitted"
replace omitted = 6 if loo=="Region 6 omitted"
replace omitted = 7 if loo=="Region 7 omitted"
replace omitted = 8 if loo=="Later time omitted"
label define omitted 	1 "Region 1"	///
						2 "Region 2"	///
						3 "Region 3"	///
						4 "Region 4"	///
						5 "Region 5"	///
						6 "Region 6"	///
						7 "Region 7"	///
						8 "Later time"
label values omitted omitted
drop loo

 
sort tvc omitted vp model 
order 	approach vp omitted model tvc	///
		brier_str 						///
		cstat_str						///
		pc_obs_risk pc_pred_risk	 	///
		hl_str 			 				///
		calib_inter_all_str				///
		calib_slope_all_str			

outsheet using "output/approach_b_validation_28day_tidy.out", replace

