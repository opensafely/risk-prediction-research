********************************************************************************
*
*	Do-file:			1801_tablecontent_HRtable.do
*
*	Written by:			Fizz & John
*
*	Data used:			output/models/
*								coefs_a_cox.ster
*								coefs_a_roy.ster
*								coefs_a_weib.ster
*								coefs_a_gamma.ster
*
*
*	Data created:		output/
*								table_hr_a_cox.txt
*								table_hr_a_roy.txt
*								table_hr_a_weib.txt
*								table_hr_a_gamma.txt
*
*	Other output:		Programs defined in this do-file: 	
*							outputHR_cat  - writes categorical HR to file
*							outputHR_cts  - writes continuous HR to file
*							term_to_text  - converts Stata variable name to text 
*
********************************************************************************
*
*	Purpose:			This do-file reads in model estimates in Stata format
*						and formats them nicely for Word tables.
*
********************************************************************************


***********************************
*  Program: Output Hazard Ratios  *
***********************************

* Generic code to ouput the HRs across outcomes for all levels of a particular
* variable, in the right shape for table
capture program drop outputHR_cat
program define outputHR_cat

	syntax, variable(string) vartext(string)

	* Put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents ("`vartext'") _tab
		
	* Write the hazard ratios to the output file
	capture lincom `variable', eform
	file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) (", ") %4.2f (r(ub)) (")") 

end


* Generic code to ouput the HRs across outcomes for all levels of a particular
* variable, in the right shape for table
capture program drop outputHR_cts
program define outputHR_cts

	syntax, variable(string)  vartext(string)

	* Put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents ("`vartext'")   _tab
		
	* Write the hazard ratios to the output file
	capture lincom c.`variable', eform
	file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) (",") %4.2f (r(ub)) (")")  

end






********************************************
*  Program: Obtain text for term in model  *
********************************************


capture program drop term_to_text
program define term_to_text, rclass
	syntax, term(string)

		
	* Age interactions
	if regexm("`term'", "#c.agec") {
		local term = subinstr("`term'", "#c.agec", " (Per unit age increase) ", . )
	}
	* Sex interactions
	if regexm("`term'", "1.male#") | regexm("`term'", "1bn.male#") {
		local term = subinstr("`term'", "1bn.male#", " (In males) ", . )
		local term = subinstr("`term'", "1.male#", " (In males) ", . )
	}
	if regexm("`term'", "0.male#") | regexm("`term'", "0bn.male#") {
		local term = subinstr("`term'", "0bn.male#", " (In females) ", . )
		local term = subinstr("`term'", "0.male#", " (In females) ", . )
	}
	* Sex
	if regexm("`term'", "0.male") | regexm("`term'", "0bn.male")  {
		local term = subinstr("`term'", "0.male", "Female", . )
		local term = subinstr("`term'", "0bn.male", "Female", . )
	}
	if regexm("`term'", "1.male") | regexm("`term'", "1bn.male") {
		local term = subinstr("`term'", "1.male", "Male", . )
		local term = subinstr("`term'", "1bn.male", "Male", . )
	}
	* Rural/urban
	if regexm("`term'", "0.rural") | regexm("`term'", "0bn.rural")  {
		local term = subinstr("`term'", "0.rural", "Urban", . )
		local term = subinstr("`term'", "0bn.rural", "Urban", . )
	}
	if regexm("`term'", "1.rural") | regexm("`term'", "1bn.rural")  {
		local term = subinstr("`term'", "1.rural", "Rural", . )
		local term = subinstr("`term'", "1bn.rural", "Rural", . )
	}
	* Yes/No variables
	local text_hypertension	= "Hypertension"
	local text_cardiac 		= "Cardiac disease"
	local text_af 			= "Atrial Fibrillation"
	local text_dvt_pe  		= "DVT/PE"
	local text_pad 			= "Surgery for PAD"
	local text_stroke		= "Stroke"
	local text_dementia 	= "Dementia"
	local text_neuro 		= "Other neurological"
	local text_cf 			= "Cystic Fibrosis"
	local text_respiratory	= "Respiratory"
	local text_liver 		= "Liver disease"
	local text_dialysis 	= "Dialysis"
	local text_transplant 	= "Organ transplant"
	local text_autoimmune 	= "RA/SLE/Psoriasis"
	local text_spleen 		= "Asplenia"
	local text_suppression 	= "Immunosuppression"
	local text_hiv 			= "HIV"
	local text_ibd 			= "IBD"
	local text_ld 			= "Intellectual disability"
	local text_smi 			= "Serious mental illness"
	local text_fracture  	= "Fracture"
	local text_hh_children 	= "Children in house"

	foreach var in  							///
		hypertension	 						///
		cardiac af dvt_pe pad stroke			/// 
		dementia neuro cf respiratory			///
		liver dialysis transplant 				///
		autoimmune spleen suppression 			///
		hiv ibd ld smi fracture  				///
		hh_children  {
			if regexm("`term'", "0.`var'") | regexm("`term'", "0bn.`var'")  {
				local term = subinstr("`term'", "0.`var'", "No "+lower("`text_`var''"), . )
				local term = subinstr("`term'", "0bn.`var'", "No "+lower("`text_`var''"), . )
			}
			if regexm("`term'", "1.`var'") | regexm("`term'", "1bn.`var'") {
				local term = subinstr("`term'", "1.`var'", "`text_`var''", . )
				local term = subinstr("`term'", "1bn.`var'", "`text_`var''", . )
			}
		}

	* Continuous variables
	local text_agec 	= "Age"
	local text_hh_numc 	= "Number in household"
	local text_hh_num2 	= "Number in household (spl 2)"
	local text_hh_num3 	= "Number in household (spl 3)"
	local text_age2 	= "Age (spl 2)"
	local text_age3 	= "Age (spl 3)"
	
	foreach var in agec hh_numc hh_num2 hh_num3 age2 age3 {
		local term = subinstr("`term'", "c.`var'", "`text_`var''", . )
		local term = subinstr("`term'", "`var'", "`text_`var''", . )
	}
		


	* Deprivation
	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'.imd") | regexm("`term'", "`i'bn.imd")  {
			local term = subinstr("`term'", "`i'.imd", "IMD `i'", . )
			local term = subinstr("`term'", "`i'bn.imd", "IMD `i'", . )
		}
	}
 	
	* Ethnicity
	local text_eth_1 = "Ethnicity: White"
	local text_eth_2 = "Ethnicity: Indian"
	local text_eth_3 = "Ethnicity: Pakistani"
	local text_eth_4 = "Ethnicity: Bangladeshi"
	local text_eth_5 = "Ethnicity: African"
	local text_eth_6 = "Ethnicity: Caribbean"
	local text_eth_7 = "Ethnicity: Chinese"
	local text_eth_8 = "Ethnicity: Mixed"

	forvalues i= 1 (1) 8 {
		if regexm("`term'", "`i'.ethnicity_8") | regexm("`term'", "`i'bn.ethnicity_8")  {
			local term = subinstr("`term'", "`i'.ethnicity_8", 	"`text_eth_`i''", . )
			local term = subinstr("`term'", "`i'bn.ethnicity_8", "`text_eth_`i''", . )
		}
	}
 
	* Obesity
	local text_obese_1 = "BMI: Underweight"
	local text_obese_2 = "BMI: Normal/overweight"
	local text_obese_3 = "BMI: Obese I "
	local text_obese_4 = "BMI: Obese II"
	local text_obese_5 = "BMI: Obese III"

	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'.obesecat") | regexm("`term'", "`i'bn.obesecat")  {
			local term = subinstr("`term'", "`i'.obesecat", 	"`text_obese_`i''", . )
			local term = subinstr("`term'", "`i'bn.obesecat", "`text_obese_`i''", . )
		}
	}
	
	* Smoking
	local text_smoke_1 = "Never smoker"
	local text_smoke_2 = "Former smoker"
	local text_smoke_3 = "Current smoker"

	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'.smoke") | regexm("`term'", "`i'bn.smoke")  {
			local term = subinstr("`term'", "`i'.smoke", 	"`text_smoke_`i''", . )
			local term = subinstr("`term'", "`i'bn.smoke", "`text_smoke_`i''", . )
		}
	}
 
	* Blood pressure
	local text_bp_1 = "BP Normal"
	local text_bp_2 = "BP Elevated"
	local text_bp_3 = "BP Stage I"
	local text_bp_4 = "BP Stage II"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.bpcat") | regexm("`term'", "`i'bn.bpcat")  {
			local term = subinstr("`term'", "`i'.bpcat_nomiss", 	"`text_bp_`i''", . )
			local term = subinstr("`term'", "`i'bn.bpcat_nomiss", "`text_bp_`i''", . )
			local term = subinstr("`term'", "`i'.bpcat", 	"`text_bp_`i''", . )
			local term = subinstr("`term'", "`i'bn.bpcat", "`text_bp_`i''", . )
		}
	}
 
  
	* Diabetes
	local text_diab_1 = "Diabetes: None"
	local text_diab_2 = "Diabetes: Controlled"
	local text_diab_3 = "Diabetes: Uncontrolled"
	local text_diab_4 = "Diabetes: Control unknown"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.diabcat") | regexm("`term'", "`i'bn.diabcat")  {
			local term = subinstr("`term'", "`i'.diabcat", 	"`text_diab_`i''", . )
			local term = subinstr("`term'", "`i'bn.diabcat", "`text_diab_`i''", . )
		}
	}
 
   
	* Asthma
	local text_asthma_1 = "Asthma: None"
	local text_asthma_2 = "Asthma: Without OCS"
	local text_asthma_3 = "Asthma: With OCS"

	forvalues i= 1 (1) 3 {
		if regexm("`term'", "`i'.asthmacat") | regexm("`term'", "`i'bn.asthmacat") {
			local term = subinstr("`term'", "`i'.asthmacat", 	"`text_asthma_`i''", . )
			local term = subinstr("`term'", "`i'bn.asthmacat", "`text_asthma_`i''", . )
		}
	}
	
	* Cancer, non-hematological
	local text_cancer_1 = "Never"
	local text_cancer_2 = "Last year"
	local text_cancer_3 = "2-5 years ago"
	local text_cancer_4 = "5+ years ago"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.cancerExhaem") | regexm("`term'", "`i'bn.cancerExhaem")  {
			local term = subinstr("`term'", "`i'.cancerExhaem",   "Cancer (ex haem): `text_cancer_`i''", . )
			local term = subinstr("`term'", "`i'bn.cancerExhaem", "Cancer (ex haem): `text_cancer_`i''", . )
			local term = subinstr("`term'", "`i'cancerExhaem", "Cancer (ex haem): `text_cancer_`i''", . )
		}
		if regexm("`term'", "`i'.cancerHaem") | regexm("`term'", "`i'bn.cancerHaem")  {
			local term = subinstr("`term'", "`i'.cancerHaem",   "Cancer (haem): `text_cancer_`i''", . )
			local term = subinstr("`term'", "`i'bn.cancerHaem", "Cancer (haem): `text_cancer_`i''", . )
		}
	}
	
	* Kidney function
	local text_kf_1 = "Renal impairment: None"
	local text_kf_2 = "Renal impairment: Stage 3a/3b"
	local text_kf_3 = "Renal impairment: Stage 4/5"

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'.kidneyfn") | regexm("`term'", "`i'bn.kidneyfn")  {
			local term = subinstr("`term'", "`i'.kidneyfn", 	 "`text_kf_`i''", . )
			local term = subinstr("`term'", "`i'bn.kidneyfn", "`text_kf_`i''", . )
		}
	}
 	
	
	* Other auxilliary terms
	local term = subinstr("`term'", "_cons",   "Constant", . )

	local term = subinstr("`term'", "logfoi",   	"Log(FOI)", . )
	local term = subinstr("`term'", "foi_q_daysq", 	"Qds (unstandardised)", . )
	local term = subinstr("`term'", "foi_q_day",   	"Qd (unstandardised)", . )
	local term = subinstr("`term'", "foiqds2",   	"Qds x Qds", . )
	local term = subinstr("`term'", "foiqds",   	"Qds", . )
	local term = subinstr("`term'", "foiqd",  		"Qd", . )

	local term = subinstr("`term'", "logae",   		"Log(A&E rate)", . )
	local term = subinstr("`term'", "ae_q_daysq", 	"Qds (unstandardised)", . )
	local term = subinstr("`term'", "ae_q_day",   	"Qd (unstandardised)", . )
	local term = subinstr("`term'", "aeqds2",   	"Qds x Qds", . )
	local term = subinstr("`term'", "aeqds",   		"Qds", . )
	local term = subinstr("`term'", "aeqd",  		"Qd", . )
	
	local term = subinstr("`term'", "logsusp",   	"Log(suspected rate)", . )
	local term = subinstr("`term'", "susp_q_daysq", "Qds (unstandardised)", . )
	local term = subinstr("`term'", "susp_q_day",   "Qd (unstandardised)", . )
	local term = subinstr("`term'", "suspqds2",   	"Qds x Qds", . )
	local term = subinstr("`term'", "suspqds",   	"Qds", . )
	local term = subinstr("`term'", "suspqd",  		"Qd", . )





	* Return parsed and tidied term
	return local term "`term'"

end





********************************************
*  Program: Obtain text for term in model  *
********************************************


capture program drop term_to_text_roy
program define term_to_text_roy, rclass
	syntax, term(string)

	* Remove character 1 from end
	if regexm("`term'", "__") {
		local term = substr("`term'", 1, length("`term'")-1)
	}

	* Sex 
	if regexm("`term'", "1.male") {
		local term = subinstr("`term'", "1.male", "Male", . )
	}
	if regexm("`term'", "0.male") {
		local term = subinstr("`term'", "0.male", "Female", . )
	}
	if regexm("`term'", "__0male")  {
		local term = subinstr("`term'", "__0male", " (In females) ", . )
	}
	if regexm("`term'", "__1male")  {
		local term = subinstr("`term'", "__1male", " (In males) ", . )
	}

	* Remove underscores
	local term = subinstr("`term'", "_", "", . )

	* Rural/urban
	if regexm("`term'", "0rural") {
		local term = subinstr("`term'", "0rural", "Urban ", . )
	}
	if regexm("`term'", "1rural") {
		local term = subinstr("`term'", "1rural", "Rural ", . )
	}
	* Yes/No variables
	local text_hypertension	= "Hypertension "
	local text_cardiac 		= "Cardiac disease "
	local text_af 			= "Atrial Fibrillation "
	local text_dvt_pe  		= "DVT/PE "
	local text_pad 			= "Surgery for PAD "
	local text_stroke		= "Stroke "
	local text_dementia 	= "Dementia "
	local text_neuro 		= "Other neurological "
	local text_cf 			= "Cystic Fibrosis "
	local text_respiratory	= "Respiratory "
	local text_liver 		= "Liver disease "
	local text_dialysis 	= "Dialysis "
	local text_transplant 	= "Organ transplant "
	local text_autoimmune 	= "RA/SLE/Psoriasis "
	local text_spleen 		= "Asplenia "
	local text_suppression 	= "Immunosuppression "
	local text_hiv 			= "HIV "
	local text_ibd 			= "IBD "
	local text_ld 			= "Intellectual disability "
	local text_smi 			= "Serious mental illness "
	local text_fracture  	= "Fracture "
	local text_hh_children 	= "Children in house "

	foreach var in  							///
		hypertension	 						///
		cardiac af dvt_pe pad stroke			/// 
		dementia neuro cf respiratory			///
		liver dialysis transplant 				///
		autoimmune spleen suppression 			///
		hiv ibd ld smi fracture  				///
		hh_children  {
			if regexm("`term'", "0`var'") {
				local term = subinstr("`term'", "0`var'", "No "+lower("`text_`var''"), . )
			}
			if  regexm("`term'", "1`var'") {
				local term = subinstr("`term'", "1`var'", "`text_`var''", . )
			}
			
			if regexm("`term'", "(In females)") | regexm("`term'", "(In males)")  {
				local varsht = substr("`var'", 1, 7)
				if regexm("`term'", "0`varsht'") {
					local term = subinstr("`term'", "0`varsht'", "No "+lower("`text_`var''"), . )
				}
				if  regexm("`term'", "1`varsht'") {
					local term = subinstr("`term'", "1`varsht'", "`text_`var''", . )
				}
			}
		}

	* Continuous variables
	local text_hh_numc 	= "Number in household "
	local text_hh_num2 	= "Number in household (spl 2) "
	local text_hh_num3 	= "Number in household (spl 3) "
	local text_age2 	= "Age (spl 2) "
	local text_age3 	= "Age (spl 3) "
	
	foreach var in hh_numc hh_num2 hh_num3 age2 age3 {
		local term = subinstr("`term'", "c.`var'", "`text_`var''", . )
		local term = subinstr("`term'", "`var'", "`text_`var''", . )
	}
		


	* Deprivation
	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'imd") {
			local term = subinstr("`term'", "`i'imd", "IMD `i'", . )
		}
	}


	* Ethnicity
	local text_eth_1 = "Ethnicity: White "
	local text_eth_2 = "Ethnicity: Indian "
	local text_eth_3 = "Ethnicity: Pakistani "
	local text_eth_4 = "Ethnicity: Bangladeshi "
	local text_eth_5 = "Ethnicity: African "
	local text_eth_6 = "Ethnicity: Caribbean "
	local text_eth_7 = "Ethnicity: Chinese "
	local text_eth_8 = "Ethnicity: Mixed "

	forvalues i= 1 (1) 8 {
		if regexm("`term'", "`i'ethnicity8") {
			local term = subinstr("`term'", "`i'ethnicity8", "`text_eth_`i''", . )
		}
	 	if regexm("`term'", "(In females)") | regexm("`term'", "(In males)")  {
			local varsht = substr("ethnicity8", 1, 7)
			if regexm("`term'", "`i'`varsht'") {
				local term = subinstr("`term'", "`i'`varsht'", "`text_eth_`i''", . )
			}
		}
	}
 
			
	* Obesity
	local text_obese_1 = "BMI: Underweight "
	local text_obese_2 = "BMI: Normal/overweight " 
	local text_obese_3 = "BMI: Obese I "
	local text_obese_4 = "BMI: Obese II "
	local text_obese_5 = "BMI: Obese III "

	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'obesecat") {
			local term = subinstr("`term'", "`i'obesecat", "`text_obese_`i''", . )
		}
		if regexm("`term'", "(In females)") | regexm("`term'", "(In males)")  {
			local varsht = substr("obesecat", 1, 7)
			if regexm("`term'", "`i'`varsht'") {
				local term = subinstr("`term'", "`i'`varsht'", "`text_obese_`i''", . )
			}
		}
	}
	
	* Smoking
	local text_smoke_1 = "Never smoker "
	local text_smoke_2 = "Former smoker "
	local text_smoke_3 = "Current smoker "

	forvalues i= 1 (1) 5 {
		if regexm("`term'", "`i'smokenomiss") {
			local term = subinstr("`term'", "`i'smokenomiss", "`text_smoke_`i''", . )
		}
	}
 
	* Blood pressure
	local text_bp_1 = "BP Normal "
	local text_bp_2 = "BP Elevated "
	local text_bp_3 = "BP Stage I "
	local text_bp_4 = "BP Stage II "

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'bpcat") {
			local term = subinstr("`term'", "`i'bpcat", "`text_bp_`i''", . )
		}
	}
 
  
	* Diabetes
	local text_diab_1 = "Diabetes: None "
	local text_diab_2 = "Diabetes: Controlled "
	local text_diab_3 = "Diabetes: Uncontrolled "
	local text_diab_4 = "Diabetes: Control unknown "

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'diabcat") {
			local term = subinstr("`term'", "`i'diabcat", "`text_diab_`i''", . )
		}
	}
 
   
	* Asthma
	local text_asthma_1 = "Asthma: None "
	local text_asthma_2 = "Asthma: Without OCS "
	local text_asthma_3 = "Asthma: With OCS "

	forvalues i= 1 (1) 3 {
		if regexm("`term'", "`i'asthmacat") {
			local term = subinstr("`term'", "`i'asthmacat", "`text_asthma_`i''", . )
		}
		if regexm("`term'", "(In females)") | regexm("`term'", "(In males)")  {
			local varsht = substr("asthmacat", 1, 7)
			if regexm("`term'", "`i'`varsht'") {
				local term = subinstr("`term'", "`i'`varsht'", "`text_asthma_`i''", . )
			}
		}
	}
	
	* Cancer, non-hematological
	local text_cancer_1 = "Never "
	local text_cancer_2 = "Last year "
	local text_cancer_3 = "2-5 years ago "
	local text_cancer_4 = "5+ years ago "

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'cancerExhaem") {
			local term = subinstr("`term'", "`i'cancerExhaem", "Cancer (ex haem): `text_cancer_`i''", . )
		}
		if regexm("`term'", "`i'cancerHaem") {
			local term = subinstr("`term'", "`i'cancerHaem", "Cancer (haem): `text_cancer_`i''", . )
		}
		if regexm("`term'", "(In females)") | regexm("`term'", "(In males)")  {
			local varsht = substr("cancerExhaem", 1, 7)
			if regexm("`term'", "`i'`varsht'") {
				local term = subinstr("`term'", "`i'`varsht'", "Cancer (ex haem): `text_cancer_`i''", . )
			}
			local varsht = substr("cancerHaem", 1, 7)
			if regexm("`term'", "`i'`varsht'") {
				local term = subinstr("`term'", "`i'`varsht'", "Cancer (haem): `text_cancer_`i''", . )
			}
		}
	}
	
	* Kidney function
	local text_kf_1 = "Renal impairment: None "
	local text_kf_2 = "Renal impairment: Stage 3a/3b "
	local text_kf_3 = "Renal impairment: Stage 4/5 "

	forvalues i= 1 (1) 4 {
		if regexm("`term'", "`i'kidneyfn") {
			local term = subinstr("`term'", "`i'kidneyfn", "`text_kf_`i''", . )
		}
		if regexm("`term'", "(In females)") | regexm("`term'", "(In males)")  {
			local varsht = substr("kidneyfn", 1, 7)
			if regexm("`term'", "`i'`varsht'") {
				local term = subinstr("`term'", "`i'`varsht'", "`text_kf_`i''", . )
			}
		}
	}
 	
	
	
 
	
		* Age interactions
	if "`term'"=="agec" {
		local term = "Age"
	}
	if substr("`term'", -5, 5)=="cagec" {
		local term = substr("`term'", 1, length("`term'")-5)+ "(Per unit age increase) "
	} 	
	if substr("`term'", -4, 4)=="cage" {
		local term = substr("`term'", 1, length("`term'")-4)+ "(Per unit age increase) "
	} 
	if substr("`term'", -3, 3)=="cag" {
		local term = substr("`term'", 1, length("`term'")-3)+ "(Per unit age increase) "
	} 	
	if substr("`term'", -3, 3)==" ca" {
		local term = substr("`term'", 1, length("`term'")-3)+ " (Per unit age increase) "
	} 	
	if substr("`term'", -2, 2)==" c" {
		local term = substr("`term'", 1, length("`term'")-3)+ " (Per unit age increase) "
	} 	

	
	* Other auxilliary terms
	forvalues i= 1 (1) 5 {
		local term = subinstr("`term'", "s0rcs`i'",   "Time (spl `i')", . )
	}
	local term = subinstr("`term'", "cons",   "Constant", . )
	
	* Return parsed and tidied term
	return local term "`term'"

end


				


**********************************
*  Program: Create table of HRs  *
**********************************



capture program drop crtablehr
program define crtablehr

	syntax , estimates(string) outputfile(string) [roy]

	capture file close tablecontents
	file open tablecontents using `outputfile', t w replace 

	* Extract estimates of desired model
	estimates use `estimates'
	global vars: colnames e(b)
	
	* Special treatment for Royston-Parmar model
	if "`roy'"!="" {
		matrix b = e(b)
		local cols = (colsof(b) + 1)/2
		local cols2 = `cols' +3
		mat c = b[1,`cols2'..colsof(b)]
		global vars: colnames c
	}
	
	
	local new = 0
	local currenttype=1
	
	* Loop over variables (terms) in model
	tokenize $vars
	while "`1'"!= "" {
		if !(regexm("`1'", "1o.") | regexm("`1'", "0o.")) {
			if "`roy'"=="" {
				term_to_text, term("`1'")
			}
			else {
				term_to_text_roy, term("`1'")
			}
			local termtext = r(term)

			* Mark main effects, interactions with age and sex
			if regexm("`termtext'", "(Per unit age increase)") & `currenttype'!=2 {
					local new = 1
					local currenttype =2
			}
			if (regexm("`termtext'", "(In males)") | regexm("`termtext'", "(In females)"))	///
				& `currenttype'!=3 {
					local new = 1
					local currenttype =3
			}
			if `new'==1 & `currenttype'==2 {
				file write tablecontents ("Interactions with age:")  _tab
				file write tablecontents _n		
			} 
			if `new'==1 & `currenttype'==3 {
				file write tablecontents ("Interactions with sex:")  _tab
				file write tablecontents _n
			} 


			* Print HRs and 95% CIs
			if regexm(substr("`1'", 1, 1), "[0-9]") {
				outputHR_cat, variable("`1'") vartext("`termtext'")
			}
			else {
				outputHR_cts, variable("`1'") vartext("`termtext'")
			}
			file write tablecontents _n
		}
		macro shift
		local new = 0
	}

	file close tablecontents
end







*****************************************
*  MAIN CODE TO PRODUCE TABLE CONTENTS  *
*****************************************

/*  Approach A  */

* Cox model
crtablehr, 	estimates(output/models/coefs_a_cox)		///
			outputfile(output/table_hr_a_cox.txt)

* Royston-Parmar model
crtablehr, 	estimates(output/models/coefs_a_roy)		///
			outputfile(output/table_hr_a_roy.txt) roy

* Weibull model
crtablehr, 	estimates(output/models/coefs_a_weib)		///
			outputfile(output/table_hr_a_weib.txt)

* Gamma model
crtablehr, 	estimates(output/models/coefs_a_gamma)		///
			outputfile(output/table_hr_a_gamma.txt)

			
			
			
/*  Approach B  */

foreach tvc in foi ae susp {
	* Logistic model
	crtablehr, 	estimates(output/models/coefs_b_logit_`tvc')	///
				outputfile(output/table_hr_b_logit_`tvc'.txt)

	* Royston-Parmar model
	crtablehr, 	estimates(output/models/coefs_b_pois_`tvc')		///
				outputfile(output/table_hr_b_pois_`tvc'.txt) 

	* Weibull model
	crtablehr, 	estimates(output/models/coefs_b_weib_`tvc')		///
				outputfile(output/table_hr_b_weib_`tvc'.txt)
}
