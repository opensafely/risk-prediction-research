
use "data/cr_base_cohort", clear


* ONS death
gen onscoviddeath = (uniform()<0.20)
replace died_date_onscovid = d(1/3/2020)+floor(69*uniform()) if onscoviddeath==1
replace days_until_coviddeath = died_date_onscovid - d(1/3/2020) + 1 if onscoviddeath==1
replace died_date_onscovid = . if onscoviddeath!=1
replace days_until_coviddeath = . if onscoviddeath!=1
drop onscoviddeath

* Other death
gen onsotherdeath = (uniform()<0.20)
replace died_date_onsother = d(1/3/2020)+floor(69*uniform()) if onsotherdeath==1
replace days_until_otherdeath = died_date_onsother - d(1/3/2020) + 1  if onsotherdeath==1
replace died_date_onsother = . if onsotherdeath!=1
replace days_until_otherdeath = . if onsotherdeath!=1
drop onsotherdeath


* Ethnicity - too much missingness
replace ethnicity = 1 if uniform()<0.2 & ethnicity>=.
replace ethnicity = 2 if uniform()<0.4 & ethnicity>=.
replace ethnicity = 3 if uniform()<0.6 & ethnicity>=.
replace ethnicity = 4 if uniform()<0.8 & ethnicity>=.
replace ethnicity = 5 if uniform()<0.9 & ethnicity>=.

* Ethnicity - too much missingness
replace ethnicity = 1 if uniform()<0.2 & ethnicity<.
replace ethnicity = 2 if uniform()<0.3 & ethnicity<.
replace ethnicity = 3 if uniform()<0.4 & ethnicity<.
replace ethnicity = 4 if uniform()<0.5 & ethnicity<.
replace ethnicity = 5 if uniform()<0.6 & ethnicity<.
replace ethnicity = 6 if uniform()<0.7 & ethnicity<.
replace ethnicity = 7 if uniform()<0.8 & ethnicity<.
replace ethnicity = 8 if uniform()<1   & ethnicity<.

* Asthma - should not have missingness
recode asthma .=0


save "data/cr_base_cohort.dta", replace

