


capture program drop cc_calib
program define cc_calib, rclass

	syntax varlist(min=2 max=2), 				///
		[weight(varname) pctile nq(integer 10)] ///
		data(string)
	
	
	***********************
	*  Pick up variables  *
	***********************
	
	tokenize `varlist'
	local observed `1' 
	local predicted `2'
	
	assert inlist("`data'", "internal", "external")
	
	if "`weight'"!= "" {
		local weightopti = "[iweight=`weight']"
		local weightoptp = "[pweight=`weight']"
	}
	else {
		local weightopti = " "
		local weightoptp = " "		
	}
	
	
	
	
	**************************
	*  Obtain GOF statistic  *
	**************************
	
	* Obtain groups by deciles (in orig cohort, i.e. weighted)
	tempvar gp_coh 
	qui xtile `gp_coh' = `predicted' `weightoptp', nq(`nq')

	*  Obtain estimates of observed and expected in each group in orig cohort (weighted)
	qui tempvar obs_events exp_events pbar n cons
	qui gen `obs_events'	= .
	qui gen `exp_events' 	= .
	qui gen `pbar'  		= .
	qui gen `n' 			= .
	qui gen `cons' 			= 1

	forvalues i = 1 (1) 10 {
		qui summ `predicted' if `gp_coh'==`i' `weightopti'
		qui replace `exp_events' = r(sum)  if `gp_coh'==`i'
		qui replace `pbar'       = r(mean) if `gp_coh'==`i'
		
		qui summ `observed' if `gp_coh'==`i' `weightopti'
		qui replace `obs_events' = r(sum) if `gp_coh'==`i'
		
		qui summ `cons' if `gp_coh'==`i' `weightopti'
		qui replace `n' = r(sum) if `gp_coh'==`i'
	}
	tempvar tag chi_term
	
	* Sum chi-squared (O-E)^2/p(1-p) over groups
	qui egen `tag' = tag(`gp_coh')
	qui gen `chi_term' = (`obs_events' - `exp_events')^2/(`n'*`pbar'*(1-`pbar'))	///
		if `tag'==1 
	qui summ `chi_term'
	local chi = r(sum)
		

	* Obtain degrees of freedom (for chi-squared distribution)
	if "`data'"=="internal" {
		local df = `nq' - 2 
	} 
	else {
	    local df = `nq'
	}
		
	* Refer to chi-sq
	local p_chi = chi2tail(`df', `chi')
	
	
	**********************
	*  Mean calibration  *
	**********************

	* Overall mean outcome (weighted back to original cohort)
	qui summ `observed' `weightopti'
	local mean_obs = r(mean)
	
	* Overall mean prediction (weighted back to original cohort)
	qui summ `predicted' `weightopti'
	local mean_pred = r(mean)
		
	
	
	*************************************
	*  Calibration intercept and slope  *
	*************************************

	* Intercept (include logit of predicted risk as intercept)
	tempvar lp
	qui gen `lp' = ln(`predicted'/(1 - `predicted'))
	qui logit `observed' `weightoptp', offset(`lp')
	local calib_inter = _b[_cons]
	local calib_inter_se = _se[_cons]
	local calib_inter_cl = `calib_inter' - invnormal(0.975)*`calib_inter_se'
	local calib_inter_cu = `calib_inter' + invnormal(0.975)*`calib_inter_se'
	local calib_inter_p  = 2*(1-normal(abs(`calib_inter')/`calib_inter_se')) 
	
	* Slope 
	qui logit `observed' `lp' `weightoptp'
	local calib_slope = _b[`lp']
	local calib_slope_se = _se[_cons]
	local calib_slope_cl = `calib_slope' - invnormal(0.975)*`calib_inter_se'
	local calib_slope_cu = `calib_slope' + invnormal(0.975)*`calib_inter_se'
	local calib_slope_p  = 2*(1-normal(abs(`calib_slope')/`calib_inter_se')) 
	
	
	
	*********************
	*  Display results  *
	*********************
	
	noi di _n "HOSMER LEMESHOW"
	noi di _n "Observed binary outcome:  " 	_col(50) "`observed'"
	noi di "Predicted risk:  "          	_col(50) "`predicted'"
	noi di _n "Case-cohort weights" 		_col(50) "`weight'"
	
	noi di _n "Number of groups"  			_col(50) `nq'
	noi di "Chi-squared statistic = "		_col(50) `chi'
	noi di "P = "							_col(50) `p_chi'
	
	noi di _n "MEAN CALIBRATION"
	noi di _n "Mean observed risk:	" 		_col(50) `mean_obs'
	noi di "Mean predicted risk:	" 		_col(50) `mean_pred'

 	noi di _n "CALIBRATION INTERCEPT AND SLOPE"
	noi di _n "Calibration intercept:	" 	_col(50) `calib_inter'			///
					"   ("`calib_inter_cl' ", " `calib_inter_cu' "),  p=" 	///
					`calib_inter_p'
	noi di "Calibration slope:	" 	   _col(50) `calib_slope'				///
					"   ("`calib_slope_cl' ", " `calib_slope_cu' "),  p=" 	///
					`calib_slope_p'



	********************
	*  Return results  *
	********************
	
	* Hosmer-Lemeshow
	return scalar chi   = `chi'
	return scalar p_chi = `p_chi'
	
	* Mean calibration
	return scalar mean_obs  = `mean_obs'
	return scalar mean_pred = `mean_pred'
	
	* Calibration intercept and slope
	return scalar calib_inter 		= `calib_inter'
	return scalar calib_inter_se 	= `calib_inter_se'
	return scalar calib_inter_cl 	= `calib_inter_cl'
	return scalar calib_inter_cu 	= `calib_inter_cu'
	return scalar calib_inter_p  	= `calib_inter_p'
	
	return scalar calib_slope 		= `calib_slope'
	return scalar calib_slope_se 	= `calib_slope_se'
	return scalar calib_slope_cl 	= `calib_slope_cl'
	return scalar calib_slope_cu 	= `calib_slope_cu'
	return scalar calib_slope_p  	= `calib_slope_p'
	
	
	
	
	************************************
	*  Save groups used, if requested  *
	************************************

	if "`pctile'"!="" {
	    qui gen group_gof 	= `gp_coh'
		qui gen obs_events 	= `obs_events'
		qui gen exp_events 	= `exp_events'
		qui gen pbar 		= `pbar'
		qui gen n			= `n'
		qui gen chi_term	= `chi_term'
	}
	
end





/*  EXAMPLE USE: 

webuse lbw, clear

gen case = (low==1)
gen     weight = 1   if case==1
replace weight = 1 if case==0

logistic low age lwt i.race smoke ptl ht ui [pweight=weight]
predict phat

cc_calib low phat, weight(weight) data(internal) pctile

use: 	
Need to specify outcome and prediction (in that order) 
Need to specify case-cohort weights in the weight option
Data has to be "internal" or "external" (i.e. same data model fitted on or not)
nq is an integer - number of groups used for Hosmer-Lemeshow GOF (default 10)
pctile is an option which keeps a copy of the variables used to create the HL (mostly for debugging)


*/

