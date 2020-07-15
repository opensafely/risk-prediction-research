
* cd needs to be the overall repo folder
* data/ and output/ need to be added to file paths

import delimited "output/input.csv", clear
set more off


foreach var of varlist temporary_immunodeficiency ///
					fracture aplastic_anaemia ///
					transplant_kidney 			///
					smoking_status bmi ///
					creatinine ///
					hba1c_mmol_per_mol ///
					hba1c_percentage ///
					asthma_severity ///
					dialysis ///
					{
						rename `var' `var'_1
					}