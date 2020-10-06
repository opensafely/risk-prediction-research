********************************************************************************
*
*	Do-file:		0000_cr_define_covariates.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		None
*
*	Data created:   None
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		This do-file contains a program which extracts the 
*					"current" covariate values given a cohort start date.
*
*	Note:			The program is very dataset-specific.
*  
********************************************************************************



	
capture program drop define_covs
program define define_covs

	syntax, [ date(string) dateno(integer 9999)]

    * First date at which participants are at risk
	if "`date'"!= "" {
		local first_date = d(`date')
	}
	else {
		local first_date = `dateno'
		local date =  string(day(`dateno'))+"/"		///
					+ string(month(`dateno'))+"/"	///
					+ string(year(`dateno'))
	}
	
	* Time lags required for variable definintion (cancer)
	local year1ago   	= `first_date' - 365.25
	local year5ago 		= `first_date' - 5*365.25

	

	**************************
	*  "Ever" comorbidities  *
	**************************
	
	* Replace dates with binary indicators 
	foreach var of varlist	hypertension_date				///
							respiratory_date	 			///
							cf_date	 						///
							cardiac_date 					///
							diabetes_date 					///
							af_date 						///
							dvt_pe_date						///
							pad_date						///
							stroke_date						///
							dementia_date		 			///
							neuro_date 						///
							liver_date 						///
							transplant_date 				///	
							hiv_date 						///
							perm_immuno_date 				///
							spleen_date						///
							autoimmune_date 				///
							ibd_date 						///
							smi_date 						///
							ld_date 						///
						{
		local newvar =  substr("`var'", 1, length("`var'") - 5)
		gen `newvar' = (`var'< `first_date')
		order `newvar', after(`var')
		drop `var'
	}
	
	
	************
	*  Cancer  *
	************

	* Haematological malignancies
	gen     cancerHaem = 4 if 											///
				inrange(cancerHaem_date, d(1/1/1900), `year5ago')
	replace cancerHaem = 3 if 											///
				inrange(cancerHaem_date, `year5ago', `year1ago')
	replace cancerHaem = 2 if											///
				inrange(cancerHaem_date, `year1ago', `first_date')
	recode  cancerHaem . = 1


	* All other cancers (non-haematological malignancies)
	gen     cancerExhaem = 4 if 										///
				inrange(cancerExhaem_date, d(1/1/1900), `year5ago')
	replace cancerExhaem = 3 if 										///
				inrange(cancerExhaem_date, `year5ago', `year1ago')
	replace cancerExhaem = 2 if										///
				inrange(cancerExhaem_date, `year1ago', `first_date')
	recode  cancerExhaem . = 1

	* Label cancer variables
	capture label drop cancer
	label define cancer 1 "Never" 			///
						2 "Last year" 		///
						3 "2-5 years ago" 	///
						4 "5+ years"
	label values cancerExhaem   cancer
	label values cancerHaem		cancer


	* Put variables together
	order cancerExhaem cancerHaem, after(cancerExhaem_date)
	drop cancerExhaem_date cancerHaem_date


	
	********************************************************
	*  Pick out relevant other time-varying comorbidities  *
	********************************************************
	
	
	if `first_date' <= d(1/03/2020) {
		local j = 1  
	} 
	else if `first_date'  <= d(6/04/2020) {
		local j = 2
	}
	else if `first_date'  <= d(12/05/2020) {
		local j = 3
	}	
	else if `first_date' > (12/05/2020) {
		local j = 3
	}	

	

	
	/*  Fracture  */
	
	gen fracture = fracture_`j'
	order fracture, after(fracture_`j')
	drop fracture_*
	

	/*  BMI  */

	gen bmi 		= bmi_`j'
	gen bmicat 		= bmicat_`j'
	gen obesecat 	= obesecat_`j'
	
	order bmi bmicat obesecat, after(obesecat_`j')
	drop bmi_* bmicat_* obesecat_*
	label values bmicat bmicat
	label values obesecat obesecat

	
	/*  Smoking  */

	gen smoke 			= smoke_`j'
	gen smoke_nomiss 	= smoke_nomiss_`j'
	order smoke smoke_nomiss, after(smoke_nomiss_`j')
	drop smoke_? smoke_nomiss_* 
	label values smoke smoke_nomiss smoke
	
	
	/*  Asthma  */

	gen asthmacat = asthmacat_`j'
	order asthmacat, after(asthmacat_`j')
	drop asthmacat_*
	label values asthmacat asthmacat
	
	
	/*  Kidney function and dialysis  */

	gen kidneyfn = kidneyfn_`j' 
	gen dialysis = dialysis_`j'  
	order kidneyfn dialysis, after(dialysis_`j')
	drop kidneyfn_* dialysis_*
	label values kidneyfn kidneyfn

	
		
	/*  Immunosuppression  */
	
	* Permanent immunosuppression OR 
	*    temporary immunodeficiency (inc. aplastic anaemia) last year
	egen suppression = rowmax(perm_immuno temp1yr_`j')
	order suppression, after(perm_immuno)
	drop temp1yr_* perm_immuno

	
	
	/*  Diabetes control  */
		
	gen hba1ccat = hba1ccat_`j' 
	order hba1ccat, after(hba1ccat_`j')
	drop hba1ccat_*
	
	* Create diabetes, split by control/not
	gen     diabcat = 1 if diabetes==0
	replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
	replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
	replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

	capture label drop diabetes
	label define diabetes 	1 "No diabetes" 			///
							2 "Controlled diabetes"		///
							3 "Uncontrolled diabetes" 	///
							4 "Diabetes, no hba1c measure"
	label values diabcat diabetes

	* Drop unnecessary variables
	order diabcat, after(diabetes)
	drop diabetes hba1ccat
	
	
								
					
					
	********************
	*  Survival times  *
	********************
	

	* Days from cohort start date (inclusive) to 
	*    date of COVID-19 death / other death
	gen days_until_coviddeath = died_date_onscovid - `first_date' + 1
	gen days_until_otherdeath = died_date_onsother - `first_date' + 1




					
	*************************
	*  Label new variables  *
	*************************
		
	* Demographics
	label var bmi			"Body Mass Index (BMI, kg/m2)"
	label var bmicat		"Grouped BMI"
	label var obesecat		"Evidence of obesity (categories)"

	label var smoke	 		"Smoking status"
	label var smoke_nomiss	 "Smoking status (missing set to non)"
	
	
	* Comorbidities
	label var respiratory		"Respiratory disease (excl. asthma)"
	label var cf				"Cystic fibrosis"
	label var cardiac			"Heart disease"
	label var af				"Atrial fibrillation"
	label var dvt_pe			"Deep vein thrombosis/Pulmonary embolism"
	label var pad				"Surgery for peripheral arterial disease or limb amputation"
	label var diabcat			"Diabetes, by level of control"
	label var hypertension		"Date of diagnosed hypertension"
	label var stroke			"Stroke"
	label var dementia			"Dementia"
	label var neuro				"Neuro condition other than stroke/dementia"	
	label var cancerExhaem		"Non haem. cancer"
	label var cancerHaem		"Haem. cancer"
	label var liver				"Liver"
	label var transplant		"Organ transplant recipient"
	label var spleen			"Spleen problems (dysplenia, sickle cell)"
	label var autoimmune		"RA, SLE, Psoriasis (autoimmune disease)"
	label var hiv 				"HIV"
	label var suppression		"Permanent or recent temporary (inc. aa) immunosuppression"
	label var ibd				"IBD"
	label var smi 				"Serious mental illness"
	label var ld 				"Learning disability inc. Down's Syndrome"
	label var fracture			"Fragility fracture"
	label var asthmacat 		"Severity of asthma"
	label var dialysis 			"Dialysis"
	label var kidneyfn			"Kidney function"
	

	* Survival times
	label var days_until_coviddeath "Days from `date' (inc.) until ONS COVID-19 death"
	label var days_until_otherdeath	"Days from `date' (inc.) until ONS non-COVID-19 death"

end


	

