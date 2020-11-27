********************************************************************************
*
*	Do-file:			903_an_plot_baseline_rate.do
*
*	Written by:			Fizz & John
*
*	Data used:			data/
*							cr_base_cohort.dta
*							foi_coefs.dta
*							ae_coefs.dta
*							susp_coefs.dta
*
*	Data created:		None
*
*	Other output:		Graphs on screen

********************************************************************************
*
*	Purpose:			This do-file graphs the estimated baseline rate using
*						the three different time-varying measures of infection
*						burden: force of infection, A&E attendances and GP
*						suspected cases. 
*
********************************************************************************





*******************************
*  Create landmark datasets   *
*******************************


* Load do-file which extracts covariates 
qui do "analysis/0000_cr_define_covariates.do"


	
/* Open base cohort   */ 
	
use "data/cr_base_cohort.dta", replace


/* Complete case for ethnicity  */ 

drop ethnicity_5 ethnicity_16
drop if ethnicity_8>=.



/* Just keep required variables  */ 

keep patient_id died_date_onscovid died_date_onsother onscoviddeath ///
	age stp_combined region_7
noi count
noi tab onscoviddeath

save "cohort_temp", replace


* Create separate landmark substudies (with only age, region and STP)
forvalues i = 1 (1) 73 {

	use "cohort_temp", clear

	* Date landmark substudy i starts
	local date_in = d(1/03/2020) + `i' - 1
			
	* Drop people who have died prior to day i 
	qui drop if died_date_onscovid < `date_in'
	qui drop if died_date_onsother < `date_in'

	
	/*  Event indicator for the 28 day period  */
	
	* Date this landmark started: d(1/03/2020) + `i' - 1
	* Days until death:  died_date_onscovid - {d(1/03/2020) + `i' - 1} + 1
	
	* Survival time (must be between 1 and 28)
	qui gen stime28 = (died_date_onscovid - (d(1/03/2020) + `i' - 1) + 1) ///
			if died_date_onscovid < .
	
	* Mark people who have an event in the relevant 28 day period
	qui replace onscoviddeath = 0 if onscoviddeath==1 & stime28>28
	qui drop stime28 died_date_*
	
	
	
	/* Collapse by age, sex, STP and region  */
	
	recode age 18/24=1 25/29=2 30/34=3 35/39=4 40/44=5 45/49=6 	///
		50/54=7 55/59=8 60/64=9 65/69=10 70/74=11 75/max=12, 	///
		gen(agegroupfoi)
	drop age
	
	collapse (count) patient_id, by(agegroupfoi region_7 ///
								stp_combined onscoviddeath)

								
	
	/* Tidy and save dataset  */
	
	qui gen time = `i'
	qui label var time "First day of landmark substudy"
	qui save time_`i', replace
}





**********************
*  Stack substudies  *
**********************

* Stack datasets
qui use time_1.dta, clear
forvalues i = 2 (1) 73 {
	qui append using time_`i'
}

* Delete unneeded datasets
forvalues i = 1 (1) 73 {
	qui erase time_`i'.dta
}

erase "cohort_temp.dta"





*******************
*  Collapse data  *
*******************

collapse (sum) patient_id, 			///
	by(agegroupfoi region_7 		///
	stp_combined onscoviddeath time)

rename patient_id fweight



****************************************
*  Add in time-varying infection data  *
****************************************


* Merge in the force of infection data
merge m:1 time agegroupfoi region_7 using "data/foi_coefs", ///
	assert(match using) keep(match) nogen 
drop foi_c_cons foi_c_day foi_c_daysq foi_c_daycu


* Merge in the A&E STP count data
merge m:1 time stp_combined using "data/ae_coefs", ///
	assert(match using) keep(match) nogen
drop ae_c_cons ae_c_day ae_c_daysq ae_c_daycu


* Merge in the GP suspected COVID case data
merge m:1 time stp_combined using "data/susp_coefs", ///
	assert(match using) keep(match) nogen
drop susp_c_cons susp_c_day susp_c_daysq susp_c_daycu






******************************************
*  Create time-varying variables needed  *
******************************************


/*  FOI  */

* Create time variables to be fed into the variable selection process
gen logfoi		= log(foi)
gen foiqd		= foi_q_day/foi_q_cons
gen foiqds		= foi_q_daysq/foi_q_cons
gen foiqint		= foiqd*foiqds
gen foiqd2		= foiqd^2
gen foiqds2		= foiqds^2


* Create lagged measures of FOI
bysort agegroupfoi region_7 (time): gen foilag7 = foi[_n-7]
replace foilag7 = 0 if foilag7>=.

bysort agegroupfoi region_7 (time): gen foilag10= foi[_n-10]
replace foilag10 = 0 if foilag10>=.

bysort agegroupfoi region_7 (time): gen foilag12 = foi[_n-12]
replace foilag12 = 0 if foilag12>=.

* Take logged lagged measures
qui summ foi if foi>0
gen logfoilag7  = log(max(foilag7, r(min)/2))
gen logfoilag10 = log(max(foilag10, r(min)/2))
gen logfoilag12 = log(max(foilag12, r(min)/2))





/*  A&E attendances  */

gen aepos = aerate
qui summ aerate if aerate>0 
replace aepos = aepos + r(min)/2 if aepos==0

* Create time variables to be fed into the variable selection process
gen logae		= log(aepos)
gen aeqd		= ae_q_day/ae_q_cons
gen aeqds 		= ae_q_daysq/ae_q_cons

replace aeqd  = 0 if ae_q_cons==0
replace aeqds = 0 if ae_q_cons==0

gen aeqint 		= aeqd*aeqds
gen aeqd2		= aeqd^2
gen aeqds2		= aeqds^2




/*  GP suspected cases  */


gen susppos = susp_rate
qui summ susp_rate if susp_rate>0 
replace susppos = susppos + r(min)/2 if susppos==0

* Create time variables to be fed into the variable selection process
gen logsusp	 	= log(susppos)
gen suspqd	 	= susp_q_day/susp_q_cons
gen suspqds 	= susp_q_daysq/susp_q_cons

replace suspqd  = 0 if susp_q_cons==0
replace suspqds = 0 if susp_q_cons==0

gen suspqint   	= suspqd*suspqds
gen suspqd2 	= suspqd^2
gen suspqds2	= suspqds^2




save funcform_temp, replace






**********************************
*  Draw graphs of baseline rate  *
**********************************

use funcform_temp, clear

* Create numerical version of stp
encode stp_combined, gen(stp)

* Count numbers of people in each agegroup and stp
bysort stp time agegroupfoi: egen fweightsum=sum(fweight)
bysort stp time agegroupfoi: replace fweightsum = . if _n>1 
mkmat 	stp region_7 											///
		time agegroupfoi fweightsum								///
		logfoi foi_q_day foi_q_daysq foiqd foiqds				///
		logae ae_q_day ae_q_daysq aeqd aeqds aeqds2				///
		logsusp susp_q_day susp_q_daysq suspqd suspqds suspqds2	///
	, nomissing matrix(pop)

	
*************************************************************
*  Pick up estimates from models age-only adjusted models   *
*************************************************************

* Crude
poisson onscoviddeath i.agegroupfoi i.stp i.time 	///
	[fweight=fweight]
matrix b = e(b)
matrix cr_age  = b[1, 1..12]
matrix cr_stp  = b[1, 13..37]
matrix cr_time = b[1, 38..110]
matrix cr_cons = b[1, 111]



* FOI
poisson onscoviddeath 	i.agegroupfoi logfoi 					///
						c.foi_q_day c.foi_q_daysq 				///
						foiqd foiqds							///
						[fweight=fweight]
matrix b = e(b)
matrix foi_age  = b[1, 1..12]
matrix foi_foi  = b[1, 13..17]
matrix foi_cons = b[1, 18]


* A&E attendances
poisson onscoviddeath 	i.agegroupfoi 							///
						logae c.ae_q_day c.ae_q_daysq 			///
						aeqd aeqds aeqds2						///			
						[fweight=fweight]
matrix b = e(b)
matrix ae_age  = b[1, 1..12]
matrix ae_ae   = b[1, 13..18]
matrix ae_cons = b[1, 19]

* Suspected cases
poisson onscoviddeath 	i.agegroupfoi 							///
						logsusp c.susp_q_day c.susp_q_daysq 	///
						suspqd suspqds suspqds2					///
						[fweight=fweight]
matrix b = e(b)
matrix susp_age  = b[1, 1..12]
matrix susp_susp = b[1, 13..18]
matrix susp_cons = b[1, 19]



********************************************************************
*  Create dataset with population by age-group and STP over time   *
********************************************************************


clear
svmat pop

rename pop1 stp
rename pop2 region_7 
rename pop3 time 
rename pop4 agegroupfoi 
rename pop5 popsize 
rename pop6 logfoi 
rename pop7 foi_q_day 
rename pop8 foi_q_daysq 
rename pop9 foiqd 
rename pop10 foiqds
rename pop11 logae 
rename pop12 ae_q_day 
rename pop13 ae_q_daysq 
rename pop14 aeqd 
rename pop15 aeqds 
rename pop16 aeqds2
rename pop17 logsusp 
rename pop18 susp_q_day 
rename pop19 susp_q_daysq 
rename pop20 suspqd 
rename pop21 suspqds 
rename pop22 suspqds2	
		

label define age 	1 "18-24" 	///
					2 "25-29" 	///
					3 "30-34" 	///
					4 "35-39" 	///
					5 "40-44" 	///
					6 "45-49" 	///
					7 "50-54" 	///
					8 "55-59" 	///
					9 "60-64" 	///
					10 "65-69" 	///
					11 "70-74" 	///
					21 "75+" 
label values agegroupfoi age
					
label define stp 	1  "E54000005"				///
					2  "E54000006"				///
					3  "E54000007/E54000008"	///
					4  "E54000009"				///
					5  "E54000010/E54000012"	///
					6  "E54000013"				///
					7  "E54000014"				///
					8  "E54000015"				///
					9  "E54000016"				///
					10 "E54000017"				///
					11 "E54000020"				///
					12 "E54000021"				///
					13 "E54000022"				///
					14 "E54000023"				///
					15 "E54000024"				///
					16 "E54000025"				///
					17 "E54000026"				///
					18 "E54000027/E54000029"	///
					19 "E54000033/E54000035"	///
					20 "E54000036/E54000037"	///	
					21 "E54000040"				///
					22 "E54000041"				///
					23 "E54000042/E54000044"	///
					24 "E54000043"				///
					25 "E54000049"
label values stp stp


gen stpname	= ""
replace stpname = "West Yorkshire"  if stp==1
replace stpname = "Humber, Coast and Vale	"  if stp==2
replace stpname = "Manchester/Cheshire/Merseyside"  if stp==3
replace stpname = "South Yorkshire and Bassetlaw"  if stp==4
replace stpname = "Staffordshire/Derbyshire"  if stp==5
replace stpname = "Lincolnshire"  if stp==6
replace stpname = "Nottinghamshire"  if stp==7
replace stpname = "Leicester, Leicestershire and Rutland"  if stp==8
replace stpname = "The Black Country"  if stp==9
replace stpname = "Birmingham and Solihull"  if stp==10
replace stpname = "Northamptonshire"  if stp==11
replace stpname = "Cambridgeshire and Peterborough"  if stp==12
replace stpname = "Norfolk and Waveney"  if stp==13
replace stpname = "Suffolk and North East Essex"  if stp==14
replace stpname = "Milton Keynes, Bedfordshire and Luton"  if stp==15
replace stpname = "Hertfordshire and West Essex"  if stp==16
replace stpname = "Mid and South Essex"  if stp==17
replace stpname = "London"  if stp==18
replace stpname = "Sussex and Surrey"  if stp==19
replace stpname = "Devon/Cornwall"  if stp==20
replace stpname = "Bath, Swindon and Wiltshire"  if stp==21
replace stpname = "Dorset"  if stp==22
replace stpname = "Buckinghamshire, Oxfordshire and Berkshire, Hampshire, IoW"  if stp==23
replace stpname = "Gloucestershire"  if stp==24
replace stpname = "Cumbria and North East"  if stp==25








************************************************************************
*  Use coefficients to estimate rates by age-group and STP over time   *
************************************************************************


/*  Crude model  */

* Expected number for each STP, for each agegroup and time
gen ln_cr_rate = cr_cons[1,1] 
forvalues i = 1 (1) 25 {
	replace ln_cr_rate = ln_cr_rate + cr_stp[1,`i']  if stp==`i'
}
forvalues j = 1 (1) 73 {
	replace ln_cr_rate = ln_cr_rate + cr_time[1,`j'] if time==`j'
}
forvalues k = 1 (1) 12 {
    replace ln_cr_rate = ln_cr_rate + cr_age[1,`k']  if agegroupfoi==`k' 
}
gen cr_rate = exp(ln_cr_rate)
gen exp_cr_n = cr_rate*popsize
drop ln_cr_rate




/*  FOI model  */

gen ln_foi_rate = foi_cons[1,1] 
forvalues k = 1 (1) 12 {
    replace ln_foi_rate = ln_foi_rate + foi_age[1,`k']  if agegroupfoi==`k' 
}
replace ln_foi_rate = ln_foi_rate + foi_foi[1,1]*logfoi
replace ln_foi_rate = ln_foi_rate + foi_foi[1,2]*foi_q_day
replace ln_foi_rate = ln_foi_rate + foi_foi[1,3]*foi_q_daysq
replace ln_foi_rate = ln_foi_rate + foi_foi[1,4]*foiqd
replace ln_foi_rate = ln_foi_rate + foi_foi[1,5]*foiqds

gen foi_rate = exp(ln_foi_rate)
gen exp_foi_n = foi_rate*popsize
drop ln_foi_rate




/*  A&E model  */

gen ln_ae_rate = ae_cons[1,1] 
forvalues k = 1 (1) 12 {
    replace ln_ae_rate = ln_ae_rate + ae_age[1,`k']  if agegroupfoi==`k' 
}
replace ln_ae_rate = ln_ae_rate + ae_ae[1,1]*logae
replace ln_ae_rate = ln_ae_rate + ae_ae[1,2]*ae_q_day
replace ln_ae_rate = ln_ae_rate + ae_ae[1,3]*ae_q_daysq
replace ln_ae_rate = ln_ae_rate + ae_ae[1,4]*aeqd
replace ln_ae_rate = ln_ae_rate + ae_ae[1,5]*aeqds
replace ln_ae_rate = ln_ae_rate + ae_ae[1,6]*aeqds2

gen ae_rate = exp(ln_ae_rate)
gen exp_ae_n = ae_rate*popsize
drop ln_ae_rate




/*  GP suspected cases model  */

gen ln_susp_rate = susp_cons[1,1] 
forvalues k = 1 (1) 12 {
    replace ln_susp_rate = ln_susp_rate + susp_age[1,`k']  if agegroupfoi==`k' 
}
replace ln_susp_rate = ln_susp_rate + susp_susp[1,1]*logsusp
replace ln_susp_rate = ln_susp_rate + susp_susp[1,2]*susp_q_day
replace ln_susp_rate = ln_susp_rate + susp_susp[1,3]*susp_q_daysq
replace ln_susp_rate = ln_susp_rate + susp_susp[1,4]*suspqd
replace ln_susp_rate = ln_susp_rate + susp_susp[1,5]*suspqds
replace ln_susp_rate = ln_susp_rate + susp_susp[1,6]*suspqds2

gen susp_rate = exp(ln_susp_rate)
gen exp_susp_n = susp_rate*popsize
drop ln_susp_rate






*****************************************************
*  Graph expected numbers by STP:  Agegroup 50-54   *
*****************************************************

replace stpname = "Buckinghams., Oxfords., Berks., Hamps., IoW" if ///
	 stpname=="Buckinghamshire, Oxfordshire and Berkshire, Hampshire, IoW"

	 
* East of England
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==1, 								///
		by(stpname, note("") title("East")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg1_age7.svg", as(svg) replace


* London
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==2, 								///
		by(stpname, note("") title("London")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (5) 15, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg2_age7.svg", as(svg) replace

* Midlands
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==3, 								///
		by(stpname, note("") title("Midlands")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg3_age7.svg", as(svg) replace

* North East/Yorkshire
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==4, 								///
		by(stpname, note("") title("North East/Yorkshire")) 			///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 12, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg4_age7.svg", as(svg) replace

* North West
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==5, 								///
		by(stpname, note("") title("North West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg5_age7.svg", as(svg) replace

* South East
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==6, 								///
		by(stpname, note("") title("South East")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg6_age7.svg", as(svg) replace

* South West
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==7 & region_7==7, 								///
		by(stpname, note("") title("South West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg7_age7.svg", as(svg) replace



	
		

*****************************************************
*  Graph expected numbers by STP:  Agegroup 70-74   *
*****************************************************


* East of England
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==1, 								///
		by(stpname, note("") title("East")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg1_age11.svg", as(svg) replace

* London
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==2, 								///
		by(stpname, note("") title("London")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 60, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg2_age11.svg", as(svg) replace

* Midlands
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==3, 								///
		by(stpname, note("") title("Midlands")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg3_age11.svg", as(svg) replace

* North East/Yorkshire
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==4, 								///
		by(stpname, note("") title("North East/Yorkshire")) 			///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 60, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg4_age11.svg", as(svg) replace

* North West
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==5, 								///
		by(stpname, note("") title("North West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected number of cases")								///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg5_age11.svg", as(svg) replace

* South East
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==6, 								///
		by(stpname, note("") title("South East")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected no cases")										///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg6_age11.svg", as(svg) replace

* South West
twoway 	(scatter exp_cr_n   time) 										///
		(scatter exp_foi_n  time) 										///
		(scatter exp_ae_n   time)	 									///
		(scatter exp_susp_n time) 										///
		if agegroupfoi==11 & region_7==7, 								///
		by(stpname, note("") title("South West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		ytitle("Expected no cases")										///
		yscale(range(0 6)) ylabel(0 (10) 40, angle(0))					///
		legend(order(1 2 3 4) 											///
		label(1 "Crude") label(2 "Force of infection") 					///
		label(3 "Smoothed A & E rate") label(4 "GP suspected case rate"))
graph export "output/graphs/tvcmod_reg7_age11.svg", as(svg) replace
		
		

