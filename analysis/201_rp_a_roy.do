********************************************************************************
*
*	Do-file:		201_rp_a_roy.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		data/cr_casecohort_models.dta
*
*	Data created:	data/model_a_roy.dta
*
*	Other output:	Log file:  output/201_rp_a_roy.log
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
log using "./output/201_rp_a_roy", text replace


***************************************
*  Ensure correct files for RP model  *
***************************************

capture do "analysis/ado/s/stpm2_matacode.mata"


************************************
*  Open dataset for model fitting  *
************************************

use "data/cr_casecohort_models.dta", replace



****************************
*  Pick up predictor list  *
****************************

do "analysis/103_pr_variable_selection_output_royp.do" 
noi di "$selected_vars"
noi di "$bn_terms"

*************************************************
*  Transform selected_vars for Roy Parmar model *
*************************************************

foreach var of global bn_terms {
* Remove bn
local term = subinstr("`var'", "bn", "", .)
* remove "." from name
local term = subinstr("`term'", ".", "", .)
* Check if its an interaction term and remove # if needed 
local term = subinstr("`term'", "#", "", .)
* add _
local term = "____" + "`term'" 
fvrevar `var', stub(`term')
}

********************
*   Royston Model  *
********************
* df(5) -> 4 knots at centile positions 20 40 60 80

timer clear 1
timer on 1
stpm2 $selected_vars ____* , df(5) scale(hazard) vce(robust)
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

*  Calculate baseline survivals
* 28 day
gen time = 28
predict s0, survival timevar(time) zeros 
summ s0 
global base_surv28 = `r(min)' 
drop time s0

* 100 day
gen time = 100
predict s0, survival timevar(time) zeros 
summ s0 
global base_surv100 = `r(min)' 
drop time s0

* Add baseline survival to matrix (and add a matrix column name)
matrix c = [$base_surv28, $base_surv100, c]
local names: colfullnames c
local names: subinstr local names "c1" "xb0:base_surv28"
local names: subinstr local names "c2" "xb0:base_surv100"
mat colnames c = `names'

*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction models
get_coefs, coef_matrix(c) eqname("xb0:") ///
	dataname("data/model_a_roy")
	
* Remove unnecessary coefficients	
use "data/model_a_roy", clear
drop if strpos(term,"_s0_")>0
save "data/model_a_roy", replace 

log close

