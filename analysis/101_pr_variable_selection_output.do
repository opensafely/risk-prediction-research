********************************************************************************
*
*	Do-file:			100_pr_variable_selection.do
*
*	Written by:			Fizz & John
*
*	Data used:			None / (data containing results of lasso?)
*
*	Data created:		None
*
*	Other output:		Global macros (used in subsequent analysis do-files)
*							$predictors (contains predictors for risk models)
*
********************************************************************************
*
*	Purpose:			This do-file takes the predictors selected in the 
*						previous do-file (from a lasso procedure) and stores
*						the predictors in a global macro.
*
********************************************************************************




****************************************
*  Model selected via lasso procedure  *
****************************************


global predictors "age1 age2 age3 i.male i.cardiac i.dementia i.dialysis i.transplant i.hiv i.ethnicity_8 i.obesecat i.smoke_nomiss i.diabcat i.asthmacat i.cancerExhaem i.cancerHaem i.kidneyfn i.respiratory i.stroke i.neuro i.liver i.autoimmune i.suppression i.shield i.stroke#i.shield"


noi di "$predictors"


global predictors_noshield "age1 age2 age3 c.age1#i.male i.cardiac i.dementia i.dialysis i.transplant i.hiv i.ethnicity_8 i.obesecat i.smoke_nomiss i.diabcat i.asthmacat i.cancerExhaem i.cancerHaem i.kidneyfn i.respiratory i.stroke i.neuro i.liver i.autoimmune i.suppression"

noi di "$predictors"




************************
*  Parsimonious model  *
************************

**?



