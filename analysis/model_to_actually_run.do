


* Blocks can be done in parallel

********************************
*  BLOCK 1: DYNAMIC POISSON	   *
********************************

* In sequence:
do "cr_dynamic_modelling_output.do"
do "rp_dynamic_poisson.do"



****************************
*  BLOCK 2: CLUSTERING	   *
****************************

do "Multimorbidity_cluster_analysis.do"



************************
*  BLOCK 3: LASSO	   *
************************

* This needs:
* cr_create_analysis_dataset

* And the bottom bit needs 
* cr_create_analysis_dataset_STSET_onscoviddeath

* Just run half-way if only the first is there

do "Multimorbidity_variable_selection.do"

