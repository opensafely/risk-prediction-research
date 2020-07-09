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

* Remove from cohort extract (& then code below):
*	bone_marrow_transplant_date 		
*  	chemo_radio_therapy_date			
*	gi_bleed_and_ulcer
*	inflammatory_bowel_disease

drop icu_date_admitted 
drop died_date_cpns
drop gi_bleed_and_ulcer
drop inflammatory_bowel_disease
drop bone_marrow_transplant 
drop chemo_radio_therapy
							
							
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




***************************
*  Start date for cohort  *
***************************

* First date at which participants are at risk
local cohort_first_date = d(1/03/2020)

* Time lags required for variable definintion
local year1ago   	= `cohort_first_date' - 365.25
local year5ago 		= `cohort_first_date' - 5*365.25
local month18ago   	= `cohort_first_date' - 1.5*365.25




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

* To be added: dates related to outcomes
foreach var of varlist 	bp_sys_date 					///
						bp_dias_date 					///
						hba1c_percentage_date			///
						hba1c_mmol_per_mol_date			///
						hypertension					///
						bmi_date_measured				///
						chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						diabetes 						///
						lung_cancer 					///
						haem_cancer						///
						other_cancer 					///
						chronic_liver_disease 			///
						stroke							///
						dementia		 				///
						other_neuro 					///
						organ_transplant 				///	
						dysplenia						///
						sickle_cell 					///
						aplastic_anaemia 				///
						hiv 							///
						permanent_immunodeficiency 		///
						temporary_immunodeficiency		///
						ra_sle_psoriasis  				///
						dialysis 	{
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

* Name some dates more sensibly 
foreach var of varlist *date*_date {
	local length = length("`var'")
	local newlength = `length' - 5
	local newvarname = substr("`var'", 1, `newlength')
	rename `var' `newvarname'
}




*******************************
*  Recode implausible values  *
*******************************


/* BMI */

* Only keep if within certain time period? using bmi_date_measured ?
* NB: Some BMI dates in future or after cohort entry

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)

* Delete BMI date variable (not needed)
drop bmi_date_measured 


 



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

gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = .u if smoking_status=="M"
replace smoke = .u if smoking_status==""
label values smoke smoke
drop smoking_status smoking_status_date
 

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
					"East of England",  					///
					"London", 								///
					"North East", 							///
					"North West", 							///
					"South East", 							///
					"South West",							///
					"West Midlands", 						///
					"Yorkshire and the Humber")
* Nine regions
gen     region_9 = 1 if region_string=="East Midlands"
replace region_9 = 2 if region_string=="East of England"
replace region_9 = 3 if region_string=="London"
replace region_9 = 4 if region_string=="North East"
replace region_9 = 5 if region_string=="North West"
replace region_9 = 6 if region_string=="South East"
replace region_9 = 7 if region_string=="South West"
replace region_9 = 8 if region_string=="West Midlands"
replace region_9 = 9 if region_string=="Yorkshire and the Humber"

label define region_9 	1 "East Midlands" 					///
						2 "East of England"  				///
						3 "London" 							///
						4 "North East" 						///
						5 "North West" 						///
						6 "South East" 						///
						7 "South West"						///
						8 "West Midlands" 					///
						9 "Yorkshire and the Humber"
label values region_9 region_9
label var region_9 "Region of England (9 regions)"

* Seven regions
recode region_9 2=1 3=2 1 8=3 4 9=4 5=5 6=6 7=7, gen(region_7)

label define region_7 	1 "East of England"					///
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

* BMI (NB: watch for missingness)
gen 	bmicat = .
recode  bmicat . = 1 if bmi<18.5
recode  bmicat . = 2 if bmi<25
recode  bmicat . = 3 if bmi<30
recode  bmicat . = 4 if bmi<35
recode  bmicat . = 5 if bmi<40
recode  bmicat . = 6 if bmi<.
replace bmicat = .u if bmi>=.

label define bmicat 1 "Underweight (<18.5)" 		///
					2 "Normal (18.5-24.9)"			///
					3 "Overweight (25-29.9)"		///
					4 "Obese I (30-34.9)"			///
					5 "Obese II (35-39.9)"			///
					6 "Obese III (40+)"				///
					.u "Unknown (.u)"
label values bmicat bmicat

* Create more granular categorisation
recode bmicat 1/3 .u = 1 4=2 5=3 6=4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
label values obese4cat obese4cat
order obese4cat, after(bmicat)




/*  Smoking  */


* Create non-missing 3-category variable for current smoking
recode smoke .u=1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke



/*  Asthma  */


* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat




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







**************************************************
*  Create binary comorbidity indices from dates  *
**************************************************

* Comorbidities ever before 1 March 2020
foreach var of varlist	chronic_respiratory_disease_date 	///
						chronic_cardiac_disease_date 		///
						diabetes 							///
						chronic_liver_disease_date 			///
						stroke_date							///
						dementia_date						///
						other_neuro_date					///
						organ_transplant_date 				///
						aplastic_anaemia_date				///
						hypertension 						///
						dysplenia_date 						///
						sickle_cell_date 					///
						hiv_date							///
						permanent_immunodeficiency_date		///
						temporary_immunodeficiency_date		///
						ra_sle_psoriasis_date 				///
						dialysis_date						///
					{
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'< `cohort_first_date')
	order `newvar', after(`var')
}






***************************
*  Grouped comorbidities  *
***************************


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen_date = rowmin(dysplenia_date sickle_cell_date)
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen_date spleen, after(sickle_cell)
drop dysplenia sickle_cell
drop dysplenia_date sickle_cell_date



/*  Cancer  */


* Haematological malignancies
gen     cancer_haem_cat = 4 if 											///
			inrange(haem_cancer_date, d(1/1/1900), `year5ago')
replace cancer_haem_cat = 3 if 											///
			inrange(haem_cancer_date, `year5ago', `year1ago')
replace cancer_haem_cat = 2 if											///
			inrange(haem_cancer_date, `year1ago', `cohort_first_date')
recode  cancer_haem_cat . = 1


* All other cancers (non-haematological malignancies)
gen exhaem_cancer_date = min(lung_cancer_date, other_cancer_date)

gen     cancer_exhaem_cat = 4 if 										///
			inrange(exhaem_cancer_date, d(1/1/1900), `year5ago')
replace cancer_exhaem_cat = 3 if 										///
			inrange(exhaem_cancer_date, `year5ago', `year1ago')
replace cancer_exhaem_cat = 2 if										///
			inrange(exhaem_cancer_date, `year1ago', `cohort_first_date')
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


* Label cancer variables
label define cancer 1 "Never" 			///
					2 "Last year" 		///
					3 "2-5 years ago" 	///
					4 "5+ years"
label values cancer_haem_cat   cancer
label values cancer_exhaem_cat cancer


* Put variables together
order cancer_exhaem_cat cancer_haem_cat exhaem_cancer_date,	///
	after(other_cancer_date)
drop lung_cancer_date other_cancer_date



/*  Immunosuppression  */


* Temporary immunodeficiency or aplastic anaemia last year
gen temp1yr = inrange(temporary_immunodeficiency_date, 	///
					`year1ago', `cohort_first_date')
gen aa1yr = inrange(aplastic_anaemia_date, 				///
					`year1ago', `cohort_first_date')

* Either of conditions above
egen other_immunosuppression = rowmax(permanent_immunodeficiency temp1yr aa1yr)
drop temp1yr aa1yr
order other_immunosuppression, after(temporary_immunodeficiency)
drop permanent_immunodeficiency* temporary_immunodeficiency* aplastic_anaemia*



/*  Dialysis  */

* If transplant since dialysis, set dialysis to no
replace dialysis=0 if dialysis==1 &  organ_transplant==1 & ///
				dialysis_date >  organ_transplant_date
***************************            UPDATE            **************************************
* Line above: restrict to KIDNEY transplant if doing separately
***************************            UPDATE            **************************************




************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 

* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

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
label define egfr_cat 	0 "No CKD" 		///
						2 "Stage 3a" 	///
						3 "Stage 3b" 	///
						4 "Stage 4" 	///
						5 "Stage 5"
label values egfr_cat egfr_cat

* Kidney function 
recode egfr_cat 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
replace reduced_kidney_function_cat = 1 if creatinine==. | creatinine==0
label define reduced_kidney_function_catlab ///
				1 "None" 					///
				2 "Stage 3a/3b egfr 30-60"	///
				3 "Stage 4/5 egfr<30"
label values reduced_kidney_function_cat reduced_kidney_function_catlab 

* Delete variables no longer needed
drop min max SCr_adj creatinine creatinine_date


* If either dialysis or kidney transplant
replace egfr_cat = 3 if dialysis==1
***************************            UPDATE            **************************************
* replace egfr_cat = 3 if kidney_transplant==1
***************************            UPDATE            **************************************

 
	
************
*   Hba1c  *
************


/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage   <= 0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0


* Only consider measurements in last 15 months
replace hba1c_percentage   = . if hba1c_percentage_date   < `month18ago'
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol_date < `month18ago'



/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.

* Label hba1c
label define hba1ccat 	0 "<6.5%" 		///
						1">=6.5-7.4" 	///
						2">=7.5-7.9" 	///
						3">=8-8.9"		/// 
						4">=9"
label values hba1ccat hba1ccat

* Create diabetes, split by control/not
gen     diabcat = 1 if diabetes==0
replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diabetes 	1 "No diabetes" 			///
						2 "Controlled diabetes"		///
						3 "Uncontrolled diabetes" 	///
						4 "Diabetes, no hba1c measure"
label values diabcat diabetes

* Delete unneeded variables
drop hba1c_pct hba1c_percentage hba1c_mmol_per_mol	///
	hba1c_percentage_date hba1c_mmol_per_mol_date  	///
	diabetes
	
rename diabcat diabetes



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


/*  Create survival times  */

* Days from 1 March (inclusive) to date of COVID-19 death / other death
gen days_until_coviddeath = died_date_onscovid - `cohort_first_date' + 1
gen days_until_otherdeath = died_date_onsother - `cohort_first_date' + 1


* Delete unneeded variables
drop died_ons_covid_flag_any died_ons_covid_flag_underlying



/*  Do some checks  */

count if died_date_onscovid<`cohort_first_date'
count if died_date_onscovid==`cohort_first_date'

count if died_date_onsother<`cohort_first_date'
count if died_date_onsother==`cohort_first_date'




**********************
*  Rename variables  *
**********************

* (Shorter names make subsequent programming easier)

* Comorbidities
rename chronic_respiratory_disease		respiratory
rename asthmacat						asthma
rename chronic_cardiac_disease			cardiac	
rename other_neuro						neuro
rename cancer_exhaem_cat				cancerExhaem
rename cancer_haem_cat					cancerHaem
rename reduced_kidney_function_cat 		kidneyfn	
rename chronic_liver_disease			liver
rename organ_transplant 				transplant
rename ra_sle_psoriasis					autoimmune
rename other_immunosuppression			suppression

* Dates of comorbidities
rename chronic_respiratory_disease_date	respiratory_date
rename chronic_cardiac_disease_date		cardiac_date
rename other_neuro_date					neuro_date
rename haem_cancer_date					cancerExhaem_date
rename exhaem_cancer_date				cancerHaem_date
rename chronic_liver_disease_date		liver_date
rename organ_transplant_date			transplant_date
rename ra_sle_psoriasis_date			autoimmune_date






*********************
*  Label variables  *
*********************


* Demographics
label var patient_id			"Patient ID"
label var age 					"Age (years)"
label var age1 					"Age spline 1"
label var age2 					"Age spline 2"
label var age3 					"Age spline 3"
label var agegroup				"Grouped age"
label var male 					"Male"
label var bmi 					"Body Mass Index (BMI, kg/m2)"
label var bmicat 				"Grouped BMI"
label var obese4cat				"Evidence of obesity (4 categories)"
label var smoke		 			"Smoking status"
label var smoke_nomiss	 		"Smoking status (missing set to non)"
label var imd 					"Index of Multiple Deprivation (IMD)"
label var ethnicity				"Ethnicity"
label var ethnicity_16			"Ethnicity in 16 categories"
label var ethnicity_8			"Ethnicity in 8 categories"
label var stp 					"Sustainability and Transformation Partnership"
label var region_9 				"Geographical region (9 England regions)"
label var region_7 				"Geographical region (7 England regions)"

* Clinical measurements
label var bp_sys 				"Systolic blood pressure"
label var bp_sys_date 			"Systolic blood pressure, date"
label var bp_dias 				"Diastolic blood pressure"
label var bp_dias_date 			"Diastolic blood pressure, date"
label var bpcat 				"Grouped blood pressure"
label var bpcat_nomiss			"Grouped blood pressure (missing set to no)"
label var egfr					"eGFR calculated using CKD-EPI formula (with no ethnicity)"
label var egfr_cat				"Grouped eGFR calculated using CKD-EPI formula (with no ethnicity)"
label var hba1ccat				"Grouped Hba1c"

* Comorbidities
label var respiratory			"Respiratory disease (excl. asthma)"
label var asthma				"Asthma, grouped by severity (OCS use)"
label var cardiac				"Heart disease"
label var diabetes				"Diabetes, grouped by control"
label var hypertension			"Diagnosed hypertension"
label var stroke				"Stroke"
label var dementia				"Dementia"
label var neuro					"Neuro condition other than stroke/dementia"	
label var cancerExhaem			"Cancer (exc. haematological), grouped by time since diagnosis"
label var cancerHaem			"Haematological malignancy, grouped by time since diagnosis"
label var kidneyfn				"Reduced kidney function" 
label var dialysis				"Dialysis"
label var liver					"Chronic liver disease"
label var transplant 			"Organ transplant recipient"
label var spleen				"Spleen problems (dysplenia, sickle cell)"
label var autoimmune			"RA, SLE, Psoriasis (autoimmune disease)"
label var hiv 					"HIV"
label var suppression			"Immunosuppressed (combination algorithm)"


* Dates of comorbidities
label var respiratory_date		"Respiratory disease (excl. asthma), date"
label var cardiac_date			"Heart disease, date"
label var diabetes_date			"Diabetes, date"
label var hypertension_date		"Date of diagnosed hypertension"
label var stroke_date			"Stroke, date"
label var dementia_date			"Dementia, date"
label var neuro_date			"Neuro condition other than stroke/dementia, date"	
label var cancerExhaem_date		"Non haem. cancer, date"
label var cancerHaem_date		"Haem. cancer, date"
label var dialysis_date			"Dialysis, date"
label var liver_date			"Liver, date"
label var transplant_date		"Organ transplant recipient, date"
label var spleen_date			"Spleen problems (dysplenia, sickle cell), date"
label var autoimmune_date		"RA, SLE, Psoriasis (autoimmune disease), date"
label var hiv_date 				"HIV, date"

* Outcomes 
label var  died_date_onscovid	"Date of ONS COVID-19 death"
label var  died_date_onsother 	"Date of ONS non-COVID-19 death"

* Survival times
label var days_until_coviddeath "Days from 1 March 2020 (inc.) until ONS COVID-19 death"
label var days_until_otherdeath	"Days from 1 March 2020 (inc.) until ONS non-COVID-19 death"



*********************
*  Order variables  *
*********************

sort patient_id
order 	patient_id stp region_9 region_7 imd						///
		age age1 age2 age3 agegroup male							///
		bmi bmicat obese4cat smoke smoke_nomiss						///
		ethnicity ethnicity_16 ethnicity_8							/// 
		respiratory* asthma* cardiac* diabetes* hba1ccat 			///
		bp_sys bp_sys_date bp_dias bp_dias_date 					///
		bpcat bpcat_nomiss hypertension*							///
		stroke* dementia* neuro* cancerExhaem* cancerHaem* 			///
		kidneyfn egfr egfr_cat 										///
		dialysis* liver* transplant* spleen* 						///
		autoimmune* hiv* suppression*								///
		died_date_onscovid days_until_coviddeath 					///
		died_date_onsother days_until_otherdeath	




***************
*  Save data  *
***************

sort patient_id
label data "Base cohort dataset for the COVID-19 death risk prediction work"

* Save overall dataset
save "data/cr_base_cohort.dta", replace

log close

