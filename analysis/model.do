import delimited "`c(pwd)'/analysis/input.csv"


set more off
cd  "`c(pwd)'/analysis"




/*  Pre-analysis data manipulation  */

***************************************************
*  IF PARALLEL WORKING - THIS MUST BE RUN FIRST   *
***************************************************

do "cr_create_analysis_dataset.do"




/*  Run analyses  */

************************************************************************
*  IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL *
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				   *
************************************************************************


* Cluster analyses

