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

<<<<<<< Updated upstream
* Program to define covariates
do "`c(pwd)'/analysis/0000_cr_define_covariates.do"

* Split into training and evaluation
do "`c(pwd)'/analysis/001_cr_data_splitting.do"
=======
* Create case-cohort samples for model fitting and variable selection
do "`c(pwd)'/analysis/001_cr_case_cohort.do"
>>>>>>> Stashed changes

* Create case-cohort samples for model fitting and variable selection
do "`c(pwd)'/analysis/002_cr_case_cohort.do"





