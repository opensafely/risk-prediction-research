********************************************************************************
*
*	Do-file:			Multimorbidity_cluster_analysis.do
*
*	Written by:			Fizz
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		output/cluster_desc (spreadsheet, tab delimited)
*						output/cluster.dta 
*							(the latter not to be extracted from server, 
*							  just there in case of data checking needed)
*
*	Other output:		None
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple cluster analysis by age-group
*						sex and ethnic group, to identify commonly co-occurring
*						comorbidities.
*
********************************************************************************



local numcluster = 10


* Open a log file
capture log close
log using "output/Multimorbidity_cluster_analysis", text replace



* Separately inspect subgroups of a particular age, sex and ethnic group
forvalues i = 1 (1) 6 {
	forvalues j = 0 (1) 1 {
		forvalues k = 1 (1) 5 {
		    
			use "cr_create_analysis_dataset.dta", clear
			
			* Only do a cluster analysis if at least 100 people in that group
			count if agegroup==`i' & male==`j' & ethnicity==`k' 
			if r(N) > 100 {
				keep if agegroup==`i'
				keep if male==`j'
				keep if ethnicity==`k'

				* Sub-sample (take whole subgroup or 20,000 whichever is biggest)
				qui count
				if r(N) > 20000 {
					set seed 17248
					sample 20000, count
				}


				* Create dummy variables for categorical predictors
				foreach var of varlist obese4cat smoke_nomiss imd  			///
					asthmacat diabcat cancer_exhaem_cat cancer_haem_cat		///
					reduced_kidney_function_cat		 {
						egen ord_`var' = group(`var')
						qui summ ord_`var'
						local max=r(max)
						forvalues l = 1 (1) `max' {
							gen `var'_`l' = (`var'==`l')
						}	
						drop ord_`var'
						drop `var'_1
				}

				* Create a "healthy" indicator
				gen no_condition = 1
				replace no_condition = 0 if htdiag_or_highbp==1
				replace no_condition = 0 if chronic_respiratory_disease==1
				replace no_condition = 0 if asthmacat>1
				replace no_condition = 0 if chronic_cardiac_disease==1
				replace no_condition = 0 if diabcat>1
				replace no_condition = 0 if cancer_exhaem_cat>1
				replace no_condition = 0 if cancer_haem_cat>1
				replace no_condition = 0 if chronic_liver_disease==1
				replace no_condition = 0 if stroke_dementia==1
				replace no_condition = 0 if other_neuro==1
				replace no_condition = 0 if reduced_kidney_function_cat>1
				replace no_condition = 0 if organ_transplant==1
				replace no_condition = 0 if spleen==1
				replace no_condition = 0 if ra_sle_psoriasis==1
				replace no_condition = 0 if other_immunosuppression==1


				* First cluster analysis - comorbidity and demographics
				set seed 123789
				cluster kmeans 	obese4cat_*							///
								smoke_nomiss_*						///
								imd_*								///
								htdiag_or_highbp					///
								chronic_respiratory_disease 		///
								asthmacat_* 						///
								chronic_cardiac_disease 			///
								diabcat_* 							///
								cancer_exhaem_cat_* 				///
								cancer_haem_cat_*	  				///
								chronic_liver_disease 				///
								stroke_dementia		 				///
								other_neuro							///
								reduced_kidney_function_cat_*		///
								organ_transplant 					///
								spleen 								///
								ra_sle_psoriasis  					///
								other_immunosuppression 			///
						,  k(`numcluster') measure(Jaccard) 		///
						name(group1_`numcluster')
						
				* Second cluster analysis - comorbidity only
				set seed 123789
				cluster kmeans 	obese4cat_*							///
								htdiag_or_highbp					///
								chronic_respiratory_disease 		///
								asthmacat_* 						///
								chronic_cardiac_disease 			///
								diabcat_* 							///
								cancer_exhaem_cat_* 				///
								cancer_haem_cat_*	  				///
								chronic_liver_disease 				///
								stroke_dementia		 				///
								other_neuro							///
								reduced_kidney_function_cat_*		///
								organ_transplant 					///
								spleen 								///
								ra_sle_psoriasis  					///
								other_immunosuppression 			///
						,  k(`numcluster') measure(Jaccard) 		///
						name(group2_`numcluster')

				* Third cluster analysis - comorbidity only, excl. obesity and hyper
				set seed 123789
				cluster kmeans 	chronic_respiratory_disease 		///
								asthmacat_* 						///
								chronic_cardiac_disease 			///
								diabcat_* 							///
								cancer_exhaem_cat_* 				///
								cancer_haem_cat_*	  				///
								chronic_liver_disease 				///
								stroke_dementia		 				///
								other_neuro							///
								reduced_kidney_function_cat_*		///
								organ_transplant 					///
								spleen 								///
								ra_sle_psoriasis  					///
								other_immunosuppression 			///
						,  k(`numcluster') measure(Jaccard) 		///
						name(group3_`numcluster')

				preserve
				keep patient_id agegroup male ethnicity	///
					group1_`numcluster' group2_`numcluster' group3_`numcluster' 
				save cluster_`i'_`j'_`k', replace
				restore
				
				* Summarise characteristics by group, first grouping
				tempname temp
				postfile `temp' agegroup male ethnicity  	///
					clustering_type cluster str30(var) pc 	///
					using cluster_desc_`i'_`j'_`k', replace

					* Cycle over the three groupings
					forvalues l = 1 (1) 3 {
						* Cycle over the difference clusters found
						forvalues m = 1 (1) `numcluster' {
							
							* Size of group 
							qui count
							local N=r(N)
							qui count if group`l'_`numcluster'==`m' 
							local pgp = r(N)/`N'
						
							post `temp' (`i') (`j') (`k') (`l') (`m') ("N") (`pgp')
												
							foreach var of varlist obese4cat_*			///
									smoke_nomiss_*						///
									imd_*								///
									htdiag_or_highbp					///
									chronic_respiratory_disease 		///
									asthmacat_* 						///
									chronic_cardiac_disease 			///
									diabcat_* 							///
									cancer_exhaem_cat_* 				///
									cancer_haem_cat_*	  				///
									chronic_liver_disease 				///
									stroke_dementia		 				///
									other_neuro							///
									reduced_kidney_function_cat_*		///
									organ_transplant 					///
									spleen 								///
									ra_sle_psoriasis  					///
									other_immunosuppression 			///
									no_condition {
									
									qui summ `var' if group`l'_`numcluster'==`m'	
									post `temp' (`i') (`j') (`k') (`l') (`m') ///
											("`var'") (r(mean))
							}	
						}
					}

				postclose `temp'
			}
		}
	}
}


* Combine clustering (in case useful for later)
forvalues i = 1 (1) 6 {
	forvalues j = 0 (1) 1 {
		forvalues k = 1 (1) 5 {
			if `i'==1 & `j'==0 & `k'==1 {
				use cluster_`i'_`j'_`k'.dta, clear
			}
			else {
				capture append using cluster_`i'_`j'_`k'.dta
			}
			erase cluster_`i'_`j'_`k'.dta
		}
	}
}
label var group1 "Clustering inc. IMD/Smoking"
label var group2 "Clustering on comorbidity only"
label var group3 "Clustering on comorbidity, excl. obesity & hypertension"
save "output/cluster.dta", replace


* Combine descriptions
use cluster_desc_1_1_1, clear

* Combine descriptions of clusters
forvalues i = 1 (1) 6 {
	forvalues j = 0 (1) 1 {
		forvalues k = 1 (1) 5 {
			if `i'==1 & `j'==0 & `k'==1 {
				use cluster_desc_`i'_`j'_`k'.dta, clear
			}
			else {
				append using cluster_desc_`i'_`j'_`k'.dta
			}
			capture erase cluster_desc_`i'_`j'_`k'.dta
		}
	}
}
reshape wide pc, i( agegroup ethnicity male var cluster) j(clustering_type)
rename pc1 pc_all 
rename pc2 pc_demog_all
rename pc3 pc_demog_small
label var pc_all 		 "Clustering on demographics and comorbidities"
label var pc_demog_all 	 "Clustering on comorbidities (inc. obesity)"
label var pc_demog_small "Clustering on demographics  (exc. hypertension and obesity)"
reshape wide pc_all pc_demog_all pc_demog_small, ///
	i( agegroup ethnicity male var) j(cluster)
order agegroup male ethnicity var pc_all* pc_demog_all* pc_demog_small*
save "output/cluster_desc", replace

* Save to tab delimited dataset
use "output/cluster_desc", clear
outsheet using "output/cluster_desc", replace
erase "output/cluster_desc.dta"



	
* Close the log file
log close


