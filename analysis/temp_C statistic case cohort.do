
*** Exploring how to obtain the C statistic from a case cohort design



*** Use of somersd command for C-statistic

* Cox model (HR)
use http://www.stata-press.com/data/r11/drugtr, clear
stcox drug age
estat concordance

* Obtain a prediction where high = good
predict hr
generate invhr=1/hr

generate censind=1-_d if _st==1
somersd _t invhr if _st==1, cenind(censind) tdist transf(c)


* Cox model (lin pred)
use http://www.stata-press.com/data/r11/drugtr, clear
stcox drug age
estat concordance

* Obtain a prediction where high = good
predict xb, xb
generate minusxb= -1*xb

generate censind=1-_d if _st==1
somersd _t minusxb if _st==1, cenind(censind) tdist transf(c)



* Weibull model (median time to event)
use http://www.stata-press.com/data/r11/drugtr, clear
streg drug age, dist(weibull)

* Obtain a prediction where high = good
predict median

generate censind=1-_d if _st==1
somersd _t median if _st==1, cenind(censind) tdist transf(c)



* Weibull model (median time to event)
use http://www.stata-press.com/data/r11/drugtr, clear
streg drug age, dist(weibull)

* Obtain a prediction where high = good
predict xb, xb
generate minusxb= -1*xb

generate censind=1-_d if _st==1
somersd _t minusxb if _st==1, cenind(censind) tdist transf(c)




*************************
*  Case-cohort setting  *
*************************

* Weight:
*   Controls by 1/SF
*   Case by 1

* So...  need to 

* Open case-cohort data (with 2 lines for subcohort cases)

* Fit model
stcox drug age
streg drug age, dist(weibull)

* Predict linear predictor and take -1 (so high = good) 
predict xb, xb
generate minusxb= -1*xb

* Set to missing in first row of data for non-subcohort cases
replace minusxb = . if non_subcohort_case & datarow = noncase

* Reset _t0 to start for non-subcohort cases (just in case!)
replace _t0 = 0 if non_subcohort_case & datarow = noncase

* Generate censoring indicator
generate censind=1-_d if _st==1

* Estimate Harrel's C-statistic using importance weights
somersd _t invhr if _st==1 [iweight=sf_weight], cenind(censind) tdist transf(c)

*** Will need to upload somersd ado file to analysis folder also



