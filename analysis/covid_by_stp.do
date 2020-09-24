
cap log close
log using `c(pwd)'/output/covid_by_stp, replace t

import delimited `c(pwd)'/output/input_covid_by_stp.csv,clear

** Drop those without a code
drop if covid_suspected == ""

** Count patients per date and STP
collapse (count) patient_id, by(covid_suspected stp)
rename patient_id count

** Remove hyphens so that it can make valid variable names
replace covid_suspected = subinstr(covid_suspected, "-", "",.)

** Reshape
reshape wide count, i(stp) j(covid_suspected) string

save `c(pwd)'/output/covid_by_stp.dta, replace

* Close the log file
log close
