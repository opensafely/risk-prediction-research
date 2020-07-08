********************************************************************************
*
*	Do-file:			100_pr_variable_selection.do
*
*	Written by:			Fizz & John
*
*	Data used:			cr_create_analysis_dataset.dta
*						cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:		None
*
*	Other output:		output/Multimorbidity_variable_selection
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple lasso model on a sample of 
*						data (all cases, random sample of controls) to variable
*						select from all possible pairwise interactions.
*
********************************************************************************
* copy and paste models from previous code

* global macros with the pre/post shield models and parsimonious

* Open a log file
capture log close
log using "output/100_pr_variable_selection.do", text replace


******************************************

* Close the log file
log close

