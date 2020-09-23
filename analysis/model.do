********************************************************************************
*
*	Do-file:		model.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		output/input.csv

*	Data created:	a number of analysis datasets
*
*	Other output:	-
*
********************************************************************************
*
*	Purpose:		This do-file performs the data creation and preparation 
*					do-files. 
*  
********************************************************************************



import delimited "`c(pwd)'/output/input.csv"


set more off
cd  "`c(pwd)'"
adopath + "`c(pwd)'/analysis/ado"




/*  Pre-analysis data manipulation  */


* Program to extract covariates
do "`c(pwd)'/analysis/0000_cr_define_covariates.do"

* Define base cohort
do "`c(pwd)'/analysis/000_cr_base_cohort_dataset.do"

* Create case-cohort samples for model fitting and variable selection
do "`c(pwd)'/analysis/001_cr_case_cohort.do"

* Create validation datasets
do "`c(pwd)'/analysis/002_cr_validation_datasets.do"

/*
* Create landmark (stacked) dataset
do "`c(pwd)'/analysis/003_cr_dynamic_modelling_output.do"
do "`c(pwd)'/analysis/003_cr_dynamic_modelling_output2.do"
do "`c(pwd)'/analysis/004_cr_landmark_substudies.do"

* Create daily landmark (stacked) dataset
do "`c(pwd)'/analysis/005_cr_daily_landmark_covid_substudies.do"
do "`c(pwd)'/analysis/006_cr_daily_landmark_noncovid_substudies.do"

*/


