********************************************************************************
*
*	Do-file:		an_model.do
*
*	Programmed by:	Fizz & John
*
*	Data used:		

*	Data created:
*
*
*	Other output:	
*
********************************************************************************
*
*	Purpose:		This do-file performs the analysis do-files. To be run 
*					after model.do.
*  
********************************************************************************


* Blocks can be done in parallel

********************************
*  BLOCK 1: DYNAMIC POISSON	   *
********************************

* In sequence:
*do "cr_dynamic_modelling_output.do"
*do "rp_dynamic_poisson.do"



****************************
*  BLOCK 2: CLUSTERING	   *
****************************

*do "Multimorbidity_cluster_analysis.do"



************************
*  BLOCK 3: LASSO	   *
************************

* This needs:
* cr_create_analysis_dataset

* And the bottom bit needs 
* cr_create_analysis_dataset_STSET_onscoviddeath

* Just run half-way if only the first is there

*do "Multimorbidity_variable_selection.do"






*********************************
*  APPROACH B: LANDMARK MODELS  *
*********************************

do "`c(pwd)'/analysis/300_rp_b_logistic"
do "`c(pwd)'/analysis/301_rp_b_poisson"
do "`c(pwd)'/analysis/301_rp_b_poisson2"
do "`c(pwd)'/analysis/302_rp_b_weibull"
do "`c(pwd)'/analysis/303_rp_b_predict_all"




