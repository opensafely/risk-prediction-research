********************************************************************************
*
*	Do-file:		000_cr_base_cohort_dataset.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		Data in memory (from input.csv)
*
*	Data created:   data/cr_base_cohort.dta (full base cohort dataset)
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		This do-file creates the variables required for the 
*					base cohort and saves into a Stata dataset.
*  
********************************************************************************



* Open a log file
cap log close
log using "output/000_cr_analysis_dataset", replace t



*********************
* STILL TO DO LIST  *
*********************
***************************            UPDATE            **************************************

* Events that happen before our start date (won't be there for new data extract)
confirm string variable died_date_ons
gen temp = date(died_date_ons, "YMD")
format temp %td
drop if temp < d(1/03/2020)
noi summ temp, format
drop temp


					
* Age - decide on spline approach

* Covariates to be added and cleaned:
* 	Number of adults living in the household (centred around mean and converted to spline)
* 	Whether or not school-aged children are living in the household (yes/no)
* 	Rural/urban (in here now - binary, correct?)
*
* Smoking - update input data
*
* Hypertension/high BP? separate? 
*
* Separate - cystic fibrosis + resp disease
*
* Update organ transplant (separate kidney vs other)
* Set kidney function to bad if kidney transplant or dialysis (done, needs updating)
*
* Add: 
*   atrial fibrillation
*   peripheral vascular disease
*   prior deep vein thrombosis / pulmonary embolism
*   Learning disability, 
*   Down’s syndrome
*   Serious mental illness 
*   Memory and cognitive problems
*   Osteoporosis or fragility fracture
*   (Polypharmacy - maybe)
*
***************************            UPDATE            **************************************





*************************************
*  Calculate household composition  *
*************************************

bysort household_id: egen hh_adults = count(patient_id)
gen hh_kids = (household_size > hh_adults)
* drop household_id household_size




****************************
*  Create required cohort  *
****************************

di "STARTING COUNT FROM IMPORT:"
count


* Age: Exclude children
noi di "DROPPING AGE<18:" 
drop if age<18

* Age: Exclude those with implausible ages
assert age<.
noi di "DROPPING AGE<105:" 
drop if age>105

* Sex: Exclude categories other than M and F
assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")

* STP
noi di "DROPPING IF STP MISSING:"
noi di "DROPPING IF MISSING STP" 
drop if stp==""



******************************
*  Convert strings to dates  *
******************************

rename temporary_immunodeficiency_1 temp_immuno_1
rename temporary_immunodeficiency_2 temp_immuno_2
rename temporary_immunodeficiency_3 temp_immuno_3
rename temporary_immunodeficiency_4 temp_immuno_4

* To be added: dates related to outcomes
foreach var of varlist 	hypertension					///
						chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						af 								///
						pvd								///
						diabetes 						///
						lung_cancer 					///
						haem_cancer						///
						other_cancer 					///
						chronic_liver_disease 			///
						stroke							///
						dementia		 				///
						other_neuro 					///
						transplant_notkidney 			///	
						dysplenia						///
						sickle_cell 					///
						hiv 							///
						permanent_immunodeficiency 		///
						aplastic_anaemia_1 				///
						aplastic_anaemia_2 				///
						aplastic_anaemia_3 				///
						aplastic_anaemia_4 				///
						temp_immuno_1					///
						temp_immuno_2					///
						temp_immuno_3					///
						temp_immuno_4					///
						ra_sle_psoriasis  				///
						transplant_kidney_1				///
						transplant_kidney_2				///
						transplant_kidney_3				///
						transplant_kidney_4				///
						dialysis_1 						///
						dialysis_2 						///
						dialysis_3 						///
						dialysis_4 						///
						ibd 							///
						smi 							///
						osteo							///
						fracture_1						///
						fracture_2						///
						fracture_3						///
						fracture_4						///
						{
	capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		replace `var' = `var' + "-15"
		rename `var' `var'_dstr
		replace `var'_dstr = " " if `var'_dstr == "-15"
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}





*******************************
*  Recode implausible values  *
*******************************


/* BMI */

* Only keep if within certain time period? using bmi_date_measured ?
* NB: Some BMI dates in future or after cohort entry

* Set implausible BMIs to missing:
forvalues j = 1 (1) 4 {
	replace bmi_`j' = . if !inrange(bmi_`j', 15, 50)
}


 



**********************
*  Recode variables  *
**********************


/*  Demographics  */

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex


* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"

forvalues j = 1 (1) 4 {
	gen     smoke_`j' = 1  if smoking_status_`j'=="N"
	replace smoke_`j' = 2  if smoking_status_`j'=="E"
	replace smoke_`j' = 3  if smoking_status_`j'=="S"
	replace smoke_`j' = .u if smoking_status_`j'=="M"
	replace smoke_`j' = .u if smoking_status_`j'==""
	label values smoke_`j' smoke
	drop smoking_status_`j' 
}


* Ethnicity (5 category)
replace ethnicity = .u if ethnicity==.
label define ethnicity 	1 "White"  								///
						2 "Mixed" 								///
						3 "Asian or Asian British"				///
						4 "Black"  								///
						5 "Other"								///
						.u "Unknown"
label values ethnicity ethnicity

* Ethnicity (16 category)
replace ethnicity_16 = .u if ethnicity==.
label define ethnicity_16 										///
						1 "British or Mixed British" 			///
						2 "Irish" 								///
						3 "Other White" 						///
						4 "White + Black Caribbean" 			///
						5 "White + Black African"				///
						6 "White + Asian" 						///
 						7 "Other mixed" 						///
						8 "Indian or British Indian" 			///
						9 "Pakistani or British Pakistani" 		///
						10 "Bangladeshi or British Bangladeshi" ///
						11 "Other Asian" 						///
						12 "Caribbean" 							///
						13 "African" 							///
						14 "Other Black" 						///
						15 "Chinese" 							///
						16 "Other" 								///
						.u "Unknown"  
label values ethnicity_16 ethnicity_16


* Ethnicity (8 category)
recode ethnicity_16 1 2 3 		= 1								///
					8 			= 2								///
					9 			= 3								///
					10 11 		= 4 							///
					13 14 		= 5 							///
					12 			= 6 							///
					15 			= 7								///
					4 5 6 7 16 	= 8								///
					, gen(ethnicity_8)
					
label define ethnicity_8										///
						1 "White"								///		
						2 "Indian"								///	
						3 "Pakistani"							///	
						4 "Bangladeshi/Other Asian"				///	
						5 "African/Other black"					///	
						6 "Carribean"							///	
						7 "Chinese"								///	
						8 "Mixed/Other" 	
label values ethnicity_8 ethnicity_8

drop ethnicity_date ethnicity_16_date




/*  Geographical location  */


* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old


* Region
rename region region_string
assert inlist(region_string, 								///
					"East Midlands", 						///
					"East",  								///
					"London", 								///
					"North East", 							///
					"North West", 							///
					"South East", 							///
					"South West",							///
					"West Midlands", 						///
					"Yorkshire and The Humber")
* Nine regions
gen     region_9 = 1 if region_string=="East Midlands"
replace region_9 = 2 if region_string=="East"
replace region_9 = 3 if region_string=="London"
replace region_9 = 4 if region_string=="North East"
replace region_9 = 5 if region_string=="North West"
replace region_9 = 6 if region_string=="South East"
replace region_9 = 7 if region_string=="South West"
replace region_9 = 8 if region_string=="West Midlands"
replace region_9 = 9 if region_string=="Yorkshire and The Humber"

label define region_9 	1 "East Midlands" 					///
						2 "East"  							///
						3 "London" 							///
						4 "North East" 						///
						5 "North West" 						///
						6 "South East" 						///
						7 "South West"						///
						8 "West Midlands" 					///
						9 "Yorkshire and The Humber"
label values region_9 region_9
label var region_9 "Region of England (9 regions)"

* Seven regions
recode region_9 2=1 3=2 1 8=3 4 9=4 5=5 6=6 7=7, gen(region_7)

label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"
drop region_string



		 


**************************
*  Categorise variables  *
**************************


/*  Age variables  */ 

* Create categorised age
recode 	age 			18/39.9999=1 	///
						40/49.9999=2 	///
						50/59.9999=3 	///
						60/69.9999=4 	///
						70/79.9999=5 	///
						80/max=6, 		///
						gen(agegroup) 

label define agegroup 	1 "18-<40" 		///
						2 "40-<50" 		///
						3 "50-<60" 		///
						4 "60-<70" 		///
						5 "70-<80" 		///
						6 "80+"
label values agegroup agegroup


* Check there are no missing ages
assert age<.
assert agegroup<.

***************************            UPDATE            **************************************
* Create restricted cubic splines for age  [************CONSIDER DOING AGE-18 to get meaningful numbers????]
mkspline age = age, cubic nknots(4)
***************************            UPDATE            **************************************



/*  Body Mass Index  */

label define bmicat 1 "Underweight (<18.5)" 		///
					2 "Normal (18.5-24.9)"			///
					3 "Overweight (25-29.9)"		///
					4 "Obese I (30-34.9)"			///
					5 "Obese II (35-39.9)"			///
					6 "Obese III (40+)"				///
					.u "Unknown (.u)"
					
label define obesecat 	1 "Underweight (<18.5)" 				///
						2 "No record of obesity/underweight" 	///
						3 "Obese I (30-34.9)"					///
						4 "Obese II (35-39.9)"					///
						5 "Obese III (40+)"	
						
forvalues j = 1 (1) 4 {
	* Categorised BMI (NB: watch for missingness)
    gen 	bmicat_`j' = .
	recode  bmicat_`j' . = 1 if bmi_`j'<18.5
	recode  bmicat_`j' . = 2 if bmi_`j'<25
	recode  bmicat_`j' . = 3 if bmi_`j'<30
	recode  bmicat_`j' . = 4 if bmi_`j'<35
	recode  bmicat_`j' . = 5 if bmi_`j'<40
	recode  bmicat_`j' . = 6 if bmi_`j'<.
	replace bmicat_`j' = .u if bmi_`j'>=.
	label values bmicat_`j' bmicat
	
	* Create more granular categorisation
	recode bmicat_`j' 1=1 2/3 .u = 2 4=3 5=4 6=5, gen(obesecat_`j')
	label values obesecat_`j' obesecat

}
order obesecat*, after(bmicat_4)



/*  Smoking  */

forvalues j = 1 (1) 4 {
	* Create non-missing 3-category variable for current smoking
	recode smoke_`j' .u=1, gen(smoke_nomiss_`j')
	order smoke_nomiss_`j', after(smoke_`j')
	label values smoke_nomiss_`j' smoke
}



/*  Asthma  */

label define asthmacat	1 "No" 				///
						2 "Yes, no OCS" 	///
						3 "Yes with OCS"

* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
forvalues j = 1 (1) 4 {
	rename asthma_severity_`j' asthmacat_`j'
	recode asthmacat_`j' 0=1 1=2 2=3
	label values asthmacat_`j' asthmacat
}



/*  Blood pressure   */

* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = .u if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 	1 "Normal" 			///
					2 "Elevated" 		///
					3 "High, stage I"	///
					4 "High, stage II" 	///
					.u "Unknown"
label values bpcat bpcat

recode bpcat .u=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat




/*  IMD  */

* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = .u if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .u=.u

label define imd 	1 "1 least deprived"	///
					2 "2" 					///
					3 "3" 					///
					4 "4" 					///
					5 "5 most deprived" 	///
					.u "Unknown"
label values imd imd 

noi di "DROPPING IF NO IMD" 
drop if imd>=.







***************************
*  Grouped comorbidities  *
***************************


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen_date = rowmin(dysplenia_date sickle_cell_date)
order spleen_date spleen, after(sickle_cell)
drop dysplenia_date sickle_cell_date



/*  Non-haematological malignancies  */

gen exhaem_cancer_date = min(lung_cancer_date, other_cancer_date)
order exhaem_cancer_date, after(other_cancer_date)
drop lung_cancer_date other_cancer_date


/*  Temporary immunosuppression  */

* Temporary immunodeficiency or aplastic anaemia last year
forvalues j = 1 (1) 4 {
	gen temp1yr_`j' = (temp_immuno_`j'_date<.) | (aplastic_anaemia_`j'_date<.)
	drop temp_immuno_`j'_date aplastic_anaemia_`j'_date
}




/*  Dialysis  */


* If transplant since dialysis, set dialysis to no
forvalues j = 1 (1) 4 {
	gen dialysis_`j' = (dialysis_`j'_date <.)
	gen transplant_kidney_`j' = (transplant_kidney_`j'_date <.)
	replace dialysis_`j'=0 if dialysis_`j'==1 &  transplant_kidney_`j'==1 & ///
				dialysis_`j'_date >  transplant_kidney_`j'_date
	order dialysis_`j', after(transplant_kidney_`j'_date)
	drop dialysis_`j'_date 
}



***************************            UPDATE            **************************************
* CHECK DIALYSIS/TRANSPLANT CODE ABOVE!!
***************************            UPDATE            **************************************


/*  Transplant  */

egen transplant_date = rowmin(transplant_kidney_*_date ///
							  transplant_notkidney_date)
drop transplant_kidney_*_date transplant_notkidney_date




/*  Fracture  */

forvalues j = 1 (1) 4 {
	gen fracture_`j' = (fracture_`j'_date<.)
	drop fracture_`j'_date
}






************
*   eGFR   *
************


label define kidneyfn 	1 "None" 					///
						2 "Stage 3a/3b egfr 30-60"	///
						3 "Stage 4/5 egfr<30"

					
forvalues j = 1 (1) 4 {

	* Set implausible creatinine values to missing (Note: zero changed to missing)
	replace creatinine_`j' = . if !inrange(creatinine_`j', 20, 3000) 

	* Divide by 88.4 (to convert umol/l to mg/dl)
	gen SCr_adj = creatinine_`j'/88.4

	gen 	min = .
	replace min = SCr_adj/0.7 	if male==0
	replace min = SCr_adj/0.9 	if male==1
	replace min = min^-0.329  	if male==0
	replace min = min^-0.411  	if male==1
	replace min = 1 			if min<1

	gen 	max = .
	replace max = SCr_adj/0.7 	if male==0
	replace max = SCr_adj/0.9 	if male==1
	replace max = max^-1.209
	replace max = 1 			if max>1

	gen 	egfr = min*max*141
	replace egfr = egfr*(0.993^age)
	replace egfr = egfr*1.018 if male==0

	* Categorise into CKD stages
	egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
	recode egfr_cat 0=5 15=4 30=3 45=2 60=0
	* 0 "No CKD" 2 "Stage 3a"  3 "Stage 3b" 4 "Stage 4" 5 "Stage 5"

	* Kidney function 
	recode egfr_cat 0=1 2/3=2 4/5=3, gen(kidneyfn_`j')
	replace kidneyfn_`j' = 1 if creatinine_`j'==. | creatinine_`j'==0
	label values kidneyfn_`j' kidneyfn 

	* Delete variables no longer needed
	drop min max SCr_adj creatinine_`j' egfr egfr_cat
}


* If either dialysis or kidney transplant
forvalues j = 1 (1) 4 {
	replace  kidneyfn_`j' = 3 if dialysis_`j'==1
	replace  kidneyfn_`j' = 3 if transplant_kidney_`j'==1
	drop transplant_kidney_`j'
}



 
	
****************************************
*   Hba1c:  Level of diabetic control  *
****************************************

label define hba1ccat	0 "<6.5%"  		///
						1">=6.5-7.4"  	///
						2">=7.5-7.9" 	///
						3">=8-8.9" 		///
						4">=9"



forvalues j = 1 (1) 4 {
    

	* Set zero or negative to missing
	replace hba1c_percentage_`j'   = . if hba1c_percentage_`j'   <= 0
	replace hba1c_mmol_per_mol_`j' = . if hba1c_mmol_per_mol_`j' <= 0


	/* Express  HbA1c as percentage  */ 

	* Express all values as perecentage 
	noi summ hba1c_percentage_`j' hba1c_mmol_per_mol_`j'
	gen 	hba1c_pct = hba1c_percentage_`j' 
	replace hba1c_pct = (hba1c_mmol_per_mol_`j'/10.929) + 2.15  ///
				if hba1c_mmol_per_mol_`j'<. 

	* Valid % range between 0-20  
	replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
	replace hba1c_pct = round(hba1c_pct, 0.1)


	/* Categorise hba1c and diabetes  */

	* Group hba1c
	gen 	hba1ccat_`j' = 0 if hba1c_pct <  6.5
	replace hba1ccat_`j' = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
	replace hba1ccat_`j' = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
	replace hba1ccat_`j' = 3 if hba1c_pct >= 8    & hba1c_pct < 9
	replace hba1ccat_`j' = 4 if hba1c_pct >= 9    & hba1c_pct !=.
	label values hba1ccat_`j' hba1ccat
	
	* Delete unneeded variables
	drop hba1c_pct hba1c_percentage_`j' hba1c_mmol_per_mol_`j' 
	
}



********************************
*  Outcomes and survival time  *
********************************


/*   Outcomes   */

* Format ONS death date
confirm string variable died_date_ons
rename died_date_ons died_date_ons_dstr
gen died_date_ons = date(died_date_ons_dstr, "YMD")
format died_date_ons %td
drop died_date_ons_dstr

* Date of Covid death in ONS
gen died_date_onscovid = died_date_ons if died_ons_covid_flag_any==1
gen died_date_onsother = died_date_ons if died_ons_covid_flag_any!=1
drop died_date_ons


* Delete unneeded variables
drop died_ons_covid_flag_any 






**********************
*  Rename variables  *
**********************

* (Shorter names make subsequent programming easier)

* Dates of comorbidities
rename chronic_respiratory_disease_date	respiratory_date
rename chronic_cardiac_disease_date		cardiac_date
rename other_neuro_date					neuro_date
rename haem_cancer_date					cancerExhaem_date
rename exhaem_cancer_date				cancerHaem_date
rename chronic_liver_disease_date		liver_date
rename ra_sle_psoriasis_date			autoimmune_date
rename permanent_immunodeficiency_date 	perm_immuno_date




*********************
*  Label variables  *
*********************

local t1 "(1/03/2020)"
local t2 "(1/04/2020)"
local t3 "(12/04/2020)"
local t4 "(11/05/2020)"


* Demographics
label var patient_id			"Patient ID"
label var age 					"Age (years)"
label var age1 					"Age spline 1"
label var age2 					"Age spline 2"
label var age3 					"Age spline 3"
label var agegroup				"Grouped age"
label var male 					"Male"
label var imd 					"Index of Multiple Deprivation (IMD)"
label var ethnicity				"Ethnicity"
label var ethnicity_16			"Ethnicity in 16 categories"
label var ethnicity_8			"Ethnicity in 8 categories"
label var stp 					"Sustainability and Transformation Partnership"
label var region_9 				"Geographical region (9 England regions)"
label var region_7 				"Geographical region (7 England regions)"
label var rural_urban 			"Rural/urban classification"
label var hh_adults 			"Number of adults in household"
label var hh_kids   			"Presence of children"


forvalues j = 1 (1) 4 {
	label var bmi_`j'			"Body Mass Index (BMI, kg/m2); `t`j''"
	label var bmicat_`j'		"Grouped BMI; `t`j''"
	label var obesecat_`j'		"Evidence of obesity (categories); `t`j''"

	label var smoke_`j'	 		"Smoking status; `t`j''"
	label var smoke_nomiss_`j'	 "Smoking status (missing set to non); `t`j''"

}

* Clinical measurements
label var bp_sys 				"Systolic blood pressure"
label var bp_sys_date 			"Systolic blood pressure, date"
label var bp_dias 				"Diastolic blood pressure"
label var bp_dias_date 			"Diastolic blood pressure, date"
label var bpcat 				"Grouped blood pressure"
label var bpcat_nomiss			"Grouped blood pressure (missing set to no)"

forvalues j = 1 (1) 4 {
	label var hba1ccat_`j'		"Grouped Hba1c; `t`j''"
	label var asthmacat_`j'		"Severity of asthma; `t`j''"
}

* Dates of comorbidities
label var respiratory_date		"Respiratory disease (excl. asthma), date"
label var cardiac_date			"Heart disease, date"
label var af_date				"Atrial fibrillation, date"
label var pvd_date				"PVD, date"
label var diabetes_date			"Diabetes, date"
label var hypertension_date		"Date of diagnosed hypertension"
label var stroke_date			"Stroke, date"
label var dementia_date			"Dementia, date"
label var neuro_date			"Neuro condition other than stroke/dementia, date"	
label var cancerExhaem_date		"Non haem. cancer, date"
label var cancerHaem_date		"Haem. cancer, date"
label var liver_date			"Liver, date"
label var transplant_date		"Organ transplant recipient, date"
label var spleen_date			"Spleen problems (dysplenia, sickle cell), date"
label var autoimmune_date		"RA, SLE, Psoriasis (autoimmune disease), date"
label var hiv_date 				"HIV, date"
label var perm_immuno_date		"RA, SLE, Psoriasis (autoimmune disease), date"
label var ibd_date				"IBD, date"
label var smi_date 				"Serious mental illness, date"
label var osteo_date			"Osteoporosis, date"

forvalues j = 1 (1) 4 {
	label var temp1yr_`j'		"Temporary immunosuppression in last year (inc. aa); `t`j''"	
	label var fracture_`j'		"Fragility fracture; `t`j''"
	label var dialysis_`j' 		"Dialysis; `t`j''"
	label var kidneyfn_`j'		"Kidney function; `t`j''"
}

* Outcomes 
label var  died_date_onscovid	"Date of ONS COVID-19 death"
label var  died_date_onsother 	"Date of ONS non-COVID-19 death"





*********************
*  Order variables  *
*********************

sort patient_id
order 	patient_id stp region_9 region_7 imd hh* 					///
		age age1 age2 age3 agegroup male							///
		bmi* bmicat* obesecat* smoke* smoke_nomiss*					///
		ethnicity ethnicity_16 ethnicity_8							/// 
		respiratory* asthma* cardiac* diabetes* hba1ccat* 			///
		bp_sys bp_sys_date bp_dias bp_dias_date 					///
		bpcat bpcat_nomiss hypertension*							///
		stroke* dementia* neuro* cancerExhaem* cancerHaem* 			///
		kidneyfn*			 										///
		dialysis* liver* transplant* spleen* 						///
		autoimmune* hiv* perm_immuno_date temp1yr*	ibd*			///
		smi* osteo* fracture*										///
		died_date_onscovid  died_date_onsother 	




***************
*  Save data  *
***************

sort patient_id
label data "Base cohort dataset for the COVID-19 death risk prediction work"

* Save overall dataset
save "data/cr_base_cohort.dta", replace

log close

