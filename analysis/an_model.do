********************************************************************************
*
*	Do-file:		an_model.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		Many, see individual files

*	Data created:	Many, see individual files
*
*	Other output:	Many, see individual files
*
********************************************************************************
*
*	Purpose:		This do-file performs the analysis do-files. To be run 
*					after model.do.
*  
********************************************************************************




********************************
*  Variable Selection - lasso  *
********************************

*do "`c(pwd)'/analysis/100_pr_variable_selection.do"
*do "`c(pwd)'/analysis/100_pr_variable_selection_output.do"
*do "`c(pwd)'/analysis/102_pr_infection_funcform_landmark.do
*do "`c(pwd)'/analysis/103_pr_variable_selection_landmark.do"



*******************************************
*  APPROACH A: Static case-cohort models  *
*******************************************

do "`c(pwd)'/analysis/200_rp_a_gamma.do"
do "`c(pwd)'/analysis/201_rp_a_roy.do"
do "`c(pwd)'/analysis/202_rp_a_weibull.do"
do "`c(pwd)'/analysis/203_rp_a_coxPH.do"
do "`c(pwd)'/analysis/204_rp_a_validation_28day.do"
do "`c(pwd)'/analysis/205_rp_a_validation_full_period.do"






*********************************
*  APPROACH B: Landmark models  *
*********************************

do "`c(pwd)'/analysis/300_rp_b_logistic.do"
do "`c(pwd)'/analysis/301_rp_b_poisson.do"
do "`c(pwd)'/analysis/301_rp_b_poisson2.do"
do "`c(pwd)'/analysis/302_rp_b_weibull.do"
do "`c(pwd)'/analysis/303_rp_b_validation_28day.do"




