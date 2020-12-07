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

/*
do "`c(pwd)'/analysis/100_pr_variable_selection.do"
do "`c(pwd)'/analysis/102_pr_infection_funcform_landmark.do"
do "`c(pwd)'/analysis/103_pr_variable_selection_landmark.do" foi
do "`c(pwd)'/analysis/103_pr_variable_selection_landmark.do" ae
do "`c(pwd)'/analysis/103_pr_variable_selection_landmark.do" susp
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 1
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 2
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 3
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 4
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 5
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 6
do "`c(pwd)'/analysis/105_pr_variable_selection_geographical.do" 7
do "`c(pwd)'/analysis/106_pr_variable_selection_time.do"
*/
   
   

 





***********************************************
*            INTERNAL VALIDATION              *
***********************************************


/*  APPROACH A: Static case-cohort models  */

do "`c(pwd)'/analysis/200_rp_a_gamma.do"
do "`c(pwd)'/analysis/201_rp_a_roy.do"
do "`c(pwd)'/analysis/202_rp_a_weibull.do"
do "`c(pwd)'/analysis/203_rp_a_coxPH.do"
do "`c(pwd)'/analysis/204_rp_a_validation_28day.do"
do "`c(pwd)'/analysis/205_rp_a_validation_full_period.do"
do "`c(pwd)'/analysis/206_rp_a_validation_28day_agesex.do"


/*  APPROACH B: Landmark models  */

do "`c(pwd)'/analysis/300_rp_b_logistic.do" foi
do "`c(pwd)'/analysis/300_rp_b_logistic.do"	ae
do "`c(pwd)'/analysis/300_rp_b_logistic.do"	susp

do "`c(pwd)'/analysis/301_rp_b_poisson.do"	foi
do "`c(pwd)'/analysis/301_rp_b_poisson.do"	ae
do "`c(pwd)'/analysis/301_rp_b_poisson.do"	susp

do "`c(pwd)'/analysis/302_rp_b_weibull.do"	foi
do "`c(pwd)'/analysis/302_rp_b_weibull.do"	ae
do "`c(pwd)'/analysis/302_rp_b_weibull.do"	susp

do "`c(pwd)'/analysis/303_rp_b_validation_28day.do"
do "`c(pwd)'/analysis/304_rp_b_validation_28day_agesex.do"


/*  APPROACH C: Landmark models  */

   
* TO BE ADDED
* 400_rp_c_poisson.do

 

***********************************************
*       INTERNAL-EXTERNAL VALIDATION          *
***********************************************

   
/*  APPROACH A: Static case-cohort models  */

do "`c(pwd)'/analysis/500_rp_a_gamma_intext.do"
do "`c(pwd)'/analysis/501_rp_a_roy_intext.do"
do "`c(pwd)'/analysis/502_rp_a_weibull_intext.do"
do "`c(pwd)'/analysis/503_rp_a_coxPH_intext.do"
do "`c(pwd)'/analysis/504_rp_a_validation_28day_intext.do"
do "`c(pwd)'/analysis/505_rp_a_validation_full_period_intext.do"


/*  APPROACH B: Landmark models  */

do "`c(pwd)'/analysis/600_rp_b_logistic_intext.do" 	foi
do "`c(pwd)'/analysis/600_rp_b_logistic_intext.do" 	ae
do "`c(pwd)'/analysis/600_rp_b_logistic_intext.do"	susp

do "`c(pwd)'/analysis/601_rp_b_poisson_intext.do"	foi
do "`c(pwd)'/analysis/601_rp_b_poisson_intext.do"	ae
do "`c(pwd)'/analysis/601_rp_b_poisson_intext.do"	susp

do "`c(pwd)'/analysis/602_rp_b_weibull_intext.do"	foi
do "`c(pwd)'/analysis/602_rp_b_weibull_intext.do"	ae
do "`c(pwd)'/analysis/602_rp_b_weibull_intext.do"	susp

do "`c(pwd)'/analysis/603_rp_b_validation_28day_intext.do"


/*  APPROACH C: Landmark models  */

* 700 
 
 
 

***********************************************
*           SENSITIVITY ANALYSES              *
***********************************************
 

/*  Multiple imputation  */

* 800


/*  Other  */

*** Sensitivity analyses for Approach A ***

* 900  
* Simpler model
* COVID-AGE (as written)
* New COVID-AGE (i.e. COVID-AGE coefs estimated on our case-cohort A) 

* 1000
* More complex model (union of all selected vars/covs?) 
* Also add one with all full vars?? (i.e. strip off numbers and replace with i.)?

* 1100 - How much does region add to predictiveness (for A and B) 


*** Sensitivity analyses for Approach B ***

* 1200
* COVID-AGE variables with TVC


* Combining TVC (all three, or the two objective measures)
do "`c(pwd)'/analysis/1300_rp_b_logistic_combined.do" 	all
do "`c(pwd)'/analysis/1300_rp_b_logistic_combined.do" 	objective

do "`c(pwd)'/analysis/1301_rp_b_poisson_combined.do" 	all
do "`c(pwd)'/analysis/1301_rp_b_poisson_combined.do" 	objective

do "`c(pwd)'/analysis/1302_rp_b_weibull_combined.do"	all
do "`c(pwd)'/analysis/1302_rp_b_weibull_combined.do"	objective

do "`c(pwd)'/analysis/1303_rp_b_validation_28day_combined.do"


* 1400 - Approach B (no TVC, no updating, fit model + assess)
* Not updating TVC or omitting
 
 
 
 
***********************************************
*          Presentation of results            *
***********************************************
 

/*  Describe data  */

do "`c(pwd)'/analysis/1501_variables_selected.do"
do "`c(pwd)'/analysis/1502_describe_cohort.do"
do "`c(pwd)'/analysis/1503_tabulate_cohort_descriptives.do" 


/*  Describe models for infection rate over time  */

do "`c(pwd)'/analysis/1601_an_plot_burden_infection.do"
do "`c(pwd)'/analysis/1602_an_plot_baseline_rate.do"
 

/*  Tables of measures of model performance   */


do "`c(pwd)'/analysis/1701_model_performance_a.do"
do "`c(pwd)'/analysis/1702_model_performance_b.do"
*do "`c(pwd)'/analysis/1703_model_performance_c.do"
do "`c(pwd)'/analysis/1704_model_performance_a_intext.do"
*do "`c(pwd)'/analysis/1705_model_performance_b_intext.do"
*do "`c(pwd)'/analysis/1706_model_performance_c_intext.do"
* age/sex?


/*  Extract model coefficients??   */


* 18
