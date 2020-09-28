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

* Pick up selected variables
do "analysis/101_pr_variable_selection_output.do" 
noi di "$predictors_noshield"
noi di "$predictors"

* Provide a list of all possible categorical variables 
global allcatvars = "i.ethnicity_8 i.obesecat i.imd i.smoke_nomiss i.diabcat i.bpcat_nomiss i.asthma i.cancerExhaem i.cancerHaem i.kidneyfn i.region_9"

* Extract a list of categorical variables selected
global predictors_noshield_nocat: 	///
	list global(predictors_noshield) - global(allcatvars)
global catvars_selected: 			///
	list global(predictors_noshield) & global(allcatvars)

* Remove the "i." prefixes
global predictors_noshield_nocat 	= 	///
	subinstr("$predictors_noshield_nocat", "i.", " ",.)
global catvars_selected 			= 	///
	subinstr("$catvars_selected", "i.", " ",.)

* Create dummy variables for the categorical variables selected 
*   (assume there are at least 2 categories to each variable)
global predictors_cat_rp = " "
foreach var of varlist $catvars_selected {
		egen ord_`var' = group(`var')
		qui summ ord_`var'
		local max=r(max)
		forvalues i = 2 (1) `max' {
			gen `var'_`i' = (`var'==`i')
			global addvar = "`var'_`i'"
			noi di "$addvar"
			global predictors_cat_rp = "$predictors_rp" +  " `var'_`i'"
		}	
		drop ord_`var'
}

global allvarsselect: list global(predictors_noshield_nocat)	///
						|  global(predictors_cat_rp) 





*********************
*   Royston Model  *
*********************
* df(5) -> 4 knots at centile positions 20 40 60 80

timer clear 1
timer on 1
stpm2  $allvarsselect, df(5) scale(hazard)
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
local cols2 = `cols'+3
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



*  Save coefficients to Stata dataset  
do "analysis/0000_pick_up_coefficients.do"

* Save coeficients needed for prediction
get_coefs, coef_matrix(c) eqname("xb0:") cons_no ///
	dataname("data/model_a_roy_noshield")
	

	


************************************************
*  Re-express in same was as for other models  * 
************************************************

* Put variable expressions back in "factor-variable" language
use "data/model_a_roy_noshield", clear
gen drop = 0
qui count
local n = r(N)
forvalues i = 1 (1) `n' {
	global temp = varexpress[`i']
	global yes: list global(temp) in global(predictors_cat_rp)
	if $yes == 1 & trim(varexpress[`i'])!= "" {
		local point = length("$temp") + 1
		local hyphen = 0
		while `hyphen'== 0 {
		    local point = `point' - 1
		    local hyphen = substr("$temp", `point', 1)=="_"
		}
		global var = substr("$temp", 1, `point'-1)
		global value = substr("$temp", `point'+1, length("$temp") - `point')
		replace varexpress = "("+ "$var"+"=="+"$value"+")" in `i'
	}
	if substr("$temp", 1, 7)=="_s0_rcs" {
	    replace drop = 1 in `i'
	}
}
drop if drop==1
drop drop
save "data/model_a_roy_noshield", replace




	
	
log close

