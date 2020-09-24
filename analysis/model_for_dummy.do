********************************************************************************
*
*	Do-file:		model_for_dummy.do
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
*					do-files USING THE DUMMY DATA. 
*  
********************************************************************************


set more off
clear all


* Fizz
*cd "C:\Users\emsuewil\Documents\Work\Covid\OpenSAFELY\Risk prediction\Git\risk-prediction-research"
* John
cd "/Users/lsh1401926/Desktop/risk-prediction-research"

adopath + "analysis/ado"




/*  Pre-analysis data manipulation  */


* PRE DATA FIXES
do "`c(pwd)'/analysis/PRE_DATAFIXESFORTESTING.do"


* Define covariates
do "`c(pwd)'/analysis/0000_cr_define_covariates.do"


* Define base cohort
do "`c(pwd)'/analysis/000_cr_base_cohort_dataset.do"


* POST DATA FIXES
do "`c(pwd)'/analysis/DATAFIXESFORTESTING.do"



* Create case-cohort samples for model fitting (approach A) and variable selection
do "`c(pwd)'/analysis/001_cr_case_cohort.do"

* Create validation datasets
do "`c(pwd)'/analysis/002_cr_validation_datasets.do"


* Create landmark (stacked) dataset
do "`c(pwd)'/analysis/003_cr_dynamic_modelling_output.do"
do "`c(pwd)'/analysis/003_cr_dynamic_modelling_output2.do"
do "`c(pwd)'/analysis/004_cr_landmark_substudies.do"

* Create daily landmark (stacked) dataset
do "`c(pwd)'/analysis/005_cr_daily_landmark_covid_substudies.do"
do "`c(pwd)'/analysis/006_cr_daily_landmark_noncovid_substudies.do"


