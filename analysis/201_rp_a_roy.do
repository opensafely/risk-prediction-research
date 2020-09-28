********************************************************************************
*
*	Do-file:		201_rp_a_roy.do
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

*The following statistical models will be fitted, with time since 1st March  
*In each case the model will be fitted without taking shielding into consideration, and then splitting time at 31st March/1st April and including shielding period and any interactions identified by the lasso in the models.  
* robust std errs


* Open a log file
capture log close
log using "./output/201_rp_a_roy", text replace

use "data/cr_casecohort_models.dta", replace

*******************************
*  TO BE UPDATED/REMOVED *
*******************************
* Centre age and then create splines of centred age
qui summ age
gen agec = (age - r(mean))/r(sd)


*******************************
*  Pick up predictor list(s)  *
*******************************

do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_noshield"

*********************
*   Royston Model  *
*********************
* df(5) -> 4 knots at centile positions 20 40 60 80

timer clear 1
timer on 1
stpm2  $predictors_noshield , df(5) scale(hazard)
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
local cols2 = cols+3
mat c = b[1,`cols2'..colsof(b)]
mat list c

*  Calculate baseline survival 
gen time = 28
predict s0, survival timevar(time) zeros 
summ s0 
global base_surv = `r(min)'

* Add baseline survival to matrix (and add a matrix column name)
matrix c = [$base_surv, c]
local names: colfullnames c
local names: subinstr local names "c1" "xb0:base_surv"
mat colnames c = `names'


* Don't think needed for rp
/* Remove unneeded parameters from matrix
local np = colsof(b) - 1
matrix b = b[1,1..`np']
matrix list b
*/

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction

get_coefs, coef_matrix(c) eqname("xb0:") cons_no ///
	dataname("data/model_a_roy_noshield")
	

log close

