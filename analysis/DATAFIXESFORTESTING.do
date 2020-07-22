
use "data/cr_base_cohort", clear


* ONS death
replace onscoviddeath = (uniform()<0.20)
replace died_date_onscovid = d(1/3/2020)+floor(99*uniform()) if onscoviddeath==1
replace died_date_onscovid = . if onscoviddeath!=1

* Other death
gen onsotherdeath = (uniform()<0.10)
replace died_date_onsother = d(1/3/2020)+floor(99*uniform()) if onsotherdeath==1
replace died_date_onsother = . if onsotherdeath!=1
drop onsotherdeath

* Survival time
replace	stime = (died_date_onscovid - d(1/03/2020) + 1) if onscoviddeath==1
replace stime = (d(8/06/2020)       - d(1/03/2020) + 1)	if onscoviddeath==0





* Ethnicity - too much missingness
replace ethnicity_5 = 1 if uniform()<0.2 & ethnicity_5>=.
replace ethnicity_5 = 2 if uniform()<0.4 & ethnicity_5>=.
replace ethnicity_5 = 3 if uniform()<0.6 & ethnicity_5>=.
replace ethnicity_5 = 4 if uniform()<0.8 & ethnicity_5>=.
replace ethnicity_5 = 5 if uniform()<0.9 & ethnicity_5>=.


* Ethnicity - too much missingness
replace ethnicity_8 = 1 if uniform()<0.2 & ethnicity_5<.
replace ethnicity_8 = 2 if uniform()<0.3 & ethnicity_5<. & ethnicity_8>=.
replace ethnicity_8 = 3 if uniform()<0.4 & ethnicity_5<. & ethnicity_8>=.
replace ethnicity_8 = 4 if uniform()<0.5 & ethnicity_5<. & ethnicity_8>=.
replace ethnicity_8 = 5 if uniform()<0.6 & ethnicity_5<. & ethnicity_8>=.
replace ethnicity_8 = 6 if uniform()<0.7 & ethnicity_5<. & ethnicity_8>=.
replace ethnicity_8 = 7 if uniform()<0.8 & ethnicity_5<. & ethnicity_8>=.
replace ethnicity_8 = 8 if uniform()<1   & ethnicity_5<. & ethnicity_8>=.

* Asthma - should not have missingness
recode asthmacat_1 .=0
recode asthmacat_2 .=0
recode asthmacat_3 .=0



save "data/cr_base_cohort.dta", replace

