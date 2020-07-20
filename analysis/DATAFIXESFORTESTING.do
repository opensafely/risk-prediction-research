
use "data/cr_base_cohort", clear
/*

* ONS death
gen onscoviddeath = (uniform()<0.20)
replace died_date_onscovid = d(1/3/2020)+floor(69*uniform()) if onscoviddeath==1
replace died_date_onscovid = . if onscoviddeath!=1
drop onscoviddeath

* Other death
gen onsotherdeath = (uniform()<0.20)
replace died_date_onsother = d(1/3/2020)+floor(69*uniform()) if onsotherdeath==1
replace died_date_onsother = . if onsotherdeath!=1
drop onsotherdeath


* Ethnicity - too much missingness
replace ethnicity = 1 if uniform()<0.2 & ethnicity>=.
replace ethnicity = 2 if uniform()<0.4 & ethnicity>=.
replace ethnicity = 3 if uniform()<0.6 & ethnicity>=.
replace ethnicity = 4 if uniform()<0.8 & ethnicity>=.
replace ethnicity = 5 if uniform()<0.9 & ethnicity>=.

* Ethnicity - too much missingness
replace ethnicity_8 = 1 if uniform()<0.2 & ethnicity<.
replace ethnicity_8 = 2 if uniform()<0.3 & ethnicity<. & ethnicity_8>=.
replace ethnicity_8 = 3 if uniform()<0.4 & ethnicity<. & ethnicity_8>=.
replace ethnicity_8 = 4 if uniform()<0.5 & ethnicity<. & ethnicity_8>=.
replace ethnicity_8 = 5 if uniform()<0.6 & ethnicity<. & ethnicity_8>=.
replace ethnicity_8 = 6 if uniform()<0.7 & ethnicity<. & ethnicity_8>=.
replace ethnicity_8 = 7 if uniform()<0.8 & ethnicity<. & ethnicity_8>=.
replace ethnicity_8 = 8 if uniform()<1   & ethnicity<. & ethnicity_8>=.

* Asthma - should not have missingness
recode asthmacat_1 .=0
recode asthmacat_2 .=0
recode asthmacat_3 .=0
recode asthmacat_4 .=0

*/

save "data/cr_base_cohort.dta", replace

