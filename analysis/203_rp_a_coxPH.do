********************************************************************************
*
*	Do-file:		203_rp_a_coxPH.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  203_rp_a_coxPH.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Cox PH
*					Model 
*  
********************************************************************************

* Open a log file
capture log close
log using "./output/203_rp_a_coxPH", text replace

use "data/cr_casecohort_models.dta", replace

*******************
*   CoxPH Model   *
*******************

timer clear 1
timer on 1
stcox  age1 age2 age3 male , vce(robust)
estat ic
timer off 1
timer list 1

************************
*   Model Performance  *
************************
* Keep copy of stset variables
gen time = _t 
gen fail = _d 

* Predict/generate relevant measures
predict  xb, xb
predict basesurv, basesurv
predict hr 
generate invhr=1/hr 

****************************************
*  Move from 2 lines to 1 for metrics  *
****************************************
cap drop 
bysort patient_id: egen maxwt = max(sf_wts)
bysort patient_id (_t): keep if _n==_N

* Only keep variables for output
keep patient_id _d _t _st xb basesurv hr invhr sf_wts onscoviddeath subcohort time fail _t0

tempname output
postfile `output' str12(model) str5(period) risk_mean obs_risk brier_score brier_p hosmer_p cal_slope cal_slope_p cal_slope_cl cal_slop_cu cal_inter cal_inter_p cal_inter_cl cal_inter_cu c_stat using "output\rp_a_coxPH_output.dta", replace

forvalues v = 1/4 {

* Drop patients not alive at start of the validation period 
* Whole Period
if `v' == 1 {

	local period_end = 70 // 0 - 70
	local period = "whole"
}
* Validation period 1
if `v' == 2 {
	local period_end = 28 // 0 - 28
	local period = "vp1"
}
* Validation period 2
if `v' == 3 {
	local baseline = 28
	local period_end = 58 // 29 - 58 
	local period = "vp2"
	drop if time < 28
}
* Validation period 3
if `v' == 4 {
	local baseline = 41
	local period_end = 70 // 42 - 70
	local period = "vp3"
	drop if time < 41
}

replace _d = fail
replace _t = time 

replace  _d = 0 if time > `period_end'
replace _t = `period_end' if time > `period_end'

* Observed survival at 28 days (note: no censoring)
cap drop obs 
gen obs = (_t < `period_end')
summ obs
local obs_risk = r(mean)

* Survival in validation period (vp) 
if `v' <= 2 {
	summ basesurv if _t <= `period_end'
	local base = r(min) // baseline survival decreases over time
}

if `v' > 2 {
sum basesurv if _t <= `baseline'
}

cap drop pred
gen pred  = `base'^exp(xb)

* Absolute risk 
cap drop risk
gen risk  = 1 - pred

* Summarise
summ risk

****** Output metrics
summ risk
local risk_mean = r(mean)

******************
*  Brier Score   *
******************

summ sf_wts
local sumweight = r(sum)

cap drop diffsq
gen diffsq = (obs - pred)^2
summ diffsq [iweight=sf_wts]
local bs = r(sum)/`sumweight'

* Expected value and variance
cap drop t_exp t_var
gen t_exp = pred*(1-pred)
gen t_var = pred*(1-pred)*(1 - 2*pred)^2

qui sum t_exp [iweight=sf_wts]
local exp = r(sum)/`sumweight'
qui count if pred<.
local N = r(N)
qui sum t_var [iweight=sf_wts]
local var = r(sum)/(`sumweight'^2)

local z = (`bs' - `exp')/sqrt(`var')
local p = 2*(1-normal(`z'))

****** Output metrics
local brier_score `bs'
local brier_p `p'

****************
*  Calibration *
****************

cc_calib obs pred, weight(sf_wts) data(internal)

****** Output metrics
local hosmer_p 		`r(p_chi)'
local cal_slope     `r(calib_slope)'
local cal_slope_p  	`r(calib_slope_p)'
local cal_slope_cl 	`r(calib_slope_cl)'
local cal_slope_cu 	`r(calib_slope_cu)'
local cal_inter     `r(calib_inter)'
local cal_inter_p   `r(calib_inter_p)'
local cal_inter_cl  `r(calib_inter_cl)'
local cal_inter_cu  `r(calib_inter_cu)'

****************************
*  Harrell's C-Statistic  *
****************************
* Generate censoring indicator
cap drop censind
generate censind = 1 - _d if _st == 1

* Estimate Harrell's C-statistic using importance weights
somersd _t invhr if _st==1 [iweight=sf_wts], cenind(censind) tdist transf(c)

****** Output metrics
mat def a = r(table)
local c_stat = a[1,1]

	post `output' ("coxPH") ("`period'") (`risk_mean') (`obs_risk') (`brier_score') (`brier_p') (`hosmer_p') (`cal_slope') (`cal_slope_p') (`cal_slope_cl') (`cal_slope_cu') (`cal_inter') (`cal_inter_p') (`cal_inter_cl') (`cal_inter_cu') (`c_stat')
	
}

postclose `output'


use "output\rp_a_coxPH_output.dta", replace

log close

