********************************************************************************
*
*	Do-file:		model.do
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
*	Purpose:		This do-file performs the data creation and preparation 
*					do-files. 
*  
********************************************************************************

import delimited "`c(pwd)'/analysis/input.csv"


set more off
cd  "`c(pwd)'"
adopath + "`c(pwd)'/analysis/ado"




/*  Pre-analysis data manipulation  */

***************************************************
*  IF PARALLEL WORKING - THIS MUST BE RUN FIRST   *
***************************************************

do "`c(pwd)'/analysis/000_cr_base_cohort_dataset.do"




/*  Run analyses  */

************************************************************************
*  IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL *
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				   *
************************************************************************


* Cluster analyses

