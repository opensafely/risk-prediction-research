********************************************************************************
*
*	Do-file:		201_rp_a_full_period_models.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	
*
*	Other output:	Log file:  201_rp_a_roy.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Royston-Parmar
*					flexible hazard modelling. 
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************



* Open a log file
capture log close
log using "./output/205_rp_a_full_period_models", text replace

**************************************
*  Ensure correct files for RP model *
**************************************

do "analysis/ado/s/stpm2_matacode.mata"


use "data/cr_casecohort_models.dta", replace

*******************************
*  Pick up predictor list(s)  *
*******************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$seleceted_vars"

*******************
*   Royston Model *
*******************
* df(5) -> 4 knots at centile positions 20 40 60 80

timer clear 1
timer on 1
stpm2 $selected_vars, df(5) scale(hazard) vce(robust)
estat ic
timer off 1
timer list 1

***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)
mat list b

local cols = (colsof(b) + 1)/2
local cols2 = `cols' +3
mat c = b[1,`cols2'..colsof(b)]
mat list c

*  Calculate baseline survival 
* 100 day
gen time = 100
predict s0, survival timevar(time) zeros 
summ s0 
global base_surv = `r(min)' 
drop time s0

* Add baseline survival to matrix (and add a matrix column name)
matrix c = [$base_surv, c]
local names: colfullnames c
local names: subinstr local names "c1" "xb0:base_surv"
mat colnames c = `names'

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction models

get_coefs, coef_matrix(c) eqname("xb0:") cons_no ///
	dataname("data/model_a_roy_fullperiod")
	
* remove unnecessary coefficients	
use "data/model_a_roy_fullperiod", clear
drop if strpos(term,"_s0_")>0
save "data/model_a_roy_fullperiod", replace 

****************************************************************
use "data/cr_casecohort_models.dta", replace

*********************
*   Weibull Model  *
*********************

timer clear 1
timer on 1
streg $selected_vars , dist(weibull) vce(robust)
estat ic
timer off 1
timer list 1

***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
local p = exp(_b[/:ln_p])
global base_surv = exp(-1*(100^(`p'))*exp(_b[_cons]))

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "_t:base_surv"
mat colnames b = `names'

* Remove unneeded parameters from matrix
local np = colsof(b) - 1
matrix b = b[1,1..`np']
matrix list b

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction

get_coefs, coef_matrix(b) eqname("_t") cons_no ///
	dataname("data/model_a_weibull_fullperiod")
	
****************************************************************
use "data/cr_casecohort_models.dta", replace

*******************
*   CoxPH Model   *
*******************

timer clear 1
timer on 1
stcox $selected_vars , vce(robust)
estat ic
timer off 1
timer list 1

***********************************************
*  Put coefficients and survival in a matrix  * 
***********************************************

* Pick up coefficient matrix
matrix b = e(b)

*  Calculate baseline survival 
predict basesurv, basesurv
summ basesurv if _t <= 100 // update to 28 days
global base_surv = r(min) // baseline survival decreases over time

* Add baseline survival to matrix (and add a matrix column name)
matrix b = [$base_surv, b]
local names: colfullnames b
local names: subinstr local names "c1" "base_surv"
mat colnames b = `names'

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(b) eqname("") cons_no ///
	dataname("data/model_a_coxPH_fullperiod")

log close
