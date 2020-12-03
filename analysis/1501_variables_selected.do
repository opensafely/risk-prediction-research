********************************************************************************
*
*	Do-file:			1501_variables_selected.do
*
*	Written by:			Fizz & John
*
*	Data used:			output/cr_all_selected_models.out
* 
*	Data created:		output/graphs/
*							.../varselect_all.png
*							.../varselect_demog.png
*							.../varselect_cardiac.png
*							.../varselect_resp.png
*							.../varselect_neuro.png
*							.../varselect_kidneyliv.png
*							.../varselect_cancer.png
*							.../varselect_immuno.png
*							.../varselect_other.png
*
*
*	Other output:		Global macros (used in subsequent analysis do-files)
*							$selectedvars (contains predictors for approach A)
*
********************************************************************************
*
*	Purpose:			This do-file graphs the predictors selected in the 
*						previous do-files (from a lasso procedure).
*
********************************************************************************



/*
ssc install palettes, replace
ssc install colrspace, replace
ssc install heatplot, replace
*/



clear

* Read in the data
import delimited "output/cr_all_selected_models.out", ///
	encoding(ISO-8859-2) 



/*  Type: Main/interaction/tvc  */

gen     tvc = 1 if regexm(variable, "foi")
replace tvc = 1 if regexm(variable, "ae_q")
replace tvc = 1 if regexm(variable, "aeq")
replace tvc = 1 if regexm(variable, "logae")
replace tvc = 1 if regexm(variable, "susp")

recode tvc .=0


gen type = 1
replace type = 2 if regexm(variable, ".male#")
replace type = 3 if regexm(variable, "#c.age")
replace type = . if tvc==1




/*  Variable groupings  */

gen vargroup = .

* Demographic
replace vargroup = 1 if regexm(variable, "age")  & !regexm(variable, "#c.age")
replace vargroup = 2 if regexm(variable, "male") & !regexm(variable, ".male#")
replace vargroup = 3 if regexm(variable, "ethnicity")
replace vargroup = 4 if regexm(variable, "obesecat")
replace vargroup = 5 if regexm(variable, "smoke")
replace vargroup = 6 if regexm(variable, "imd")
replace vargroup = 7 if regexm(variable, "rural")
replace vargroup = 8 if regexm(variable, "hh_num") | regexm(variable, "hh_child") 

* Cardiac
replace vargroup = 14 if regexm(variable, "hypertension") 
replace vargroup = 15 if regexm(variable, "bpcat") 
replace vargroup = 16 if regexm(variable, "diab") 
replace vargroup = 17 if regexm(variable, "cardiac") 
replace vargroup = 18 if regexm(variable, "af") 
replace vargroup = 19 if regexm(variable, "dvt") 
replace vargroup = 20 if regexm(variable, "pad") 

* Respiratory
replace vargroup = 26 if regexm(variable, "asthma") 
replace vargroup = 27 if regexm(variable, "respiratory") 
replace vargroup = 28 if regexm(variable, "cf") 

* Stroke and neurological conditions
replace vargroup = 34 if regexm(variable, "stroke") 
replace vargroup = 35 if regexm(variable, "dementia") 
replace vargroup = 36 if regexm(variable, "neuro") 

* Kidney and liver problems
replace vargroup = 42 if regexm(variable, "kidney") 
replace vargroup = 43 if regexm(variable, "dialysis") 
replace vargroup = 44 if regexm(variable, "liver") 
replace vargroup = 45 if regexm(variable, "transplant") 

* Cancer
replace vargroup = 51 if regexm(variable, "cancerExhaem") 
replace vargroup = 52 if regexm(variable, "cancerHaem") 

* Immunosuppression
replace vargroup = 58 if regexm(variable, "spleen") 
replace vargroup = 59 if regexm(variable, "autoimmune") 
replace vargroup = 60 if regexm(variable, "suppression") 
replace vargroup = 61 if regexm(variable, "hiv") 
replace vargroup = 62 if regexm(variable, "ibd") 

* Other
replace vargroup = 68 if regexm(variable, "fracture") 
replace vargroup = 69 if regexm(variable, "ld") 
replace vargroup = 70 if regexm(variable, "smi") 



* Label variables
label define vargroup 	1 "Age" 					///
						2 "Male"					///
						3 "Ethnicity"				///
						4 "Obesity"					///
						5 "Smoking"					///
						6 "IMD"						///
						7 "Rural/Urban"				///
						8 "Household composition"	///
						14 "Hypertension"			///
						15 "Blood pressure"			///
						16 "Diabetes"				///
						17 "Cardiac disease"		///
						18 "AF"						///
						19 "DVT/PE"					///
						20 "PAD/amputation"			///
						26 "Asthma"					///
						27 "Respiratory"			///
						28 "CF"						///
						34 "Stroke"					///
						35 "Dementia"				///
						36 "Neuro"					///
						42 "Kidney"					///
						43 "Dialysis"				///
						44 "Liver"					///
						45 "Transplant"				///
						51 "Cancer Ex"				///
						52 "Cancer Heam"			///
						58 "Spleen"					///
						59 "Autoimmune"				///
						60 "Suppression"			///
						61 "HIV"					///
						62 "IBD"					///
						68 "Fracture"				///
						69 "LD"						///
						70 "SMI"				
label values vargroup vargroup						




* Label variables
recode vargroup 1/8=1 14/20=2 26/28=3 34/36=4 42/45=5 	///
				51/52=6 58/62=7 68/70=8,				///
				gen(vargp)
label define vargp 	1 "Demographic"		///
					2 "Cardiac"			///
					3 "Respiratory"		///
					4 "Neurological"	///
					5 "Kidney/liver"	///
					6 "Cancer"			///
					7 "Immuno"			///
					8 "Other"	
label values vargp vargp


* Add a zero variable
save temp, replace
clear
set obs 70
gen vargroup = _n
merge 1:m vargroup using temp
gen zero = 0
erase temp.dta

 
 
 
*******************
*  Overall graph  *
*******************
 

* Recode according to vargp
foreach var of varlist select* {
	gen `var'_all = .
	forvalues i = 1 (1) 8 {
		replace `var'_all = `i'/8 if vargp==`i' & `var'==1
	}
	recode `var'_all .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	zero 					///
		select_all 				///
		select_geog1_all		///
		select_geog2_all		///
		select_geog4_all 		///	
		select_geog5_all 		///
		select_geog6_all 		///
		select_geog7_all 		///
		select_time_all 		///
		select_foi_all 			///
		select_ae_all 			///
		select_susp_all if tvc!= 1, matrix(A)
	
* Draw heatplot	
heatplot A ,																///
		cuts(0.1 0.13 0.3 0.4 0.55 0.65 0.8 0.9) 							///
		colors(black sunflowerlime yellow midgreen blue red brown magenta orange) 	///
		ramp(right label(	.115 	"Demographic" 				///
							.215 	"Cardiac" 					///
							.35 	"Respiratory" 				///
							.475 	"Neurological"				///	
							.6 		"Kidney"					///
							.725	"Cancer"					///
							.85 	"Immunosuppression"			///
							.95 	"Other", labsize(tiny))		///
							subtitle(""))	///
		xlabel(	2 "A" 						///
				3 "A{subscript:-1}"			///
				4 "A{subscript:-2}" 		///
				5 "A{subscript:-4}" 		///
				6 "A{subscript:-5}" 		///
				7 "A{subscript:-6}" 		///
				8 "A{subscript:-7}" 		///
				9 "A{subscript:-time}"	 	///
				10 "B{subscript:FOI}" 		///
				11 "B{subscript:A&E}" 		///
				12 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_all.png", as(png) replace


* Delete unneeded variables 
drop *_all



			
				
***********************
*  Demographic graph  *
***********************

local v = 1

* Categories to label (out of the 18 total):
local labellist = "1 2 4 7 10 13 16 18"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'

* Categories to label (out of the 18 total):
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}
local lab`j' = (4*r(max) - 1)/(4*r(max))



* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v'				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v'		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v'			///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')					 		///
		colors(		black 									///
					gold yellow			 					///
					midgreen midgreen*0.5 midgreen*0.7		///
					blue blue*0.5 blue*0.7  				///
					red red*0.5 red*0.7 					///
					brown brown*0.5 brown*0.7 				///
					magenta magenta*0.5 magenta*0.7 		///
					orange) 								///
		ramp(right 	label(	`lab1' 	"Age" 				///
							`lab2' 	"Male" 				///
							`lab3'	"Ethnicity" 		///
							`lab4' 	"Obesity"			///	
							`lab5'	"Smoking"			///
							`lab6'	"IMD"				///
							`lab7'	"Rural"				///
							`lab8' 	"Household", 		///
							labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_demog.png", as(png) replace

	
* Delete unneeded variables 
drop *_`v' temp*




				
				
**************************
*  Cardiovascular graph  *
**************************

local v = 2

* Categories to label (out of 19 total):
local labellist = "1 3 6 9 12 15 18"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')					 		///
		colors(		black 									///
					yellow*0.5 yellow*0.7 					///
					midgreen*0.5 midgreen*0.7				///
					blue blue*0.5 blue*0.7  				///
					red red*0.5 red*0.7 					///
					brown brown*0.5 brown*0.7 				///
					magenta magenta*0.5 magenta*0.7 		///
					orange orange*0.5 orange*0.7)  			///
		ramp(right 	label(	`lab1' 	"Hypertension" 			///
							`lab2' 	"BP cat" 				///
							`lab3'	"Diabetes" 				///
							`lab4' 	"Cardiac"				///	
							`lab5'	"AF"					///
							`lab6'	"DVT/PE"				///
							`lab7'	"PAD", labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_cardiac.png", as(png) replace
							
* Delete unneeded variables 
drop *_`v' temp*




	
				
***********************
*  Respiratory graph  *
***********************

local v = 3

* Categories to label (out of 9 total):
local labellist = "2 5 8"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')							///
		colors(		black 									///
					yellow yellow*0.5 yellow*0.7 			///
					midgreen midgreen*0.5 midgreen*0.7		///
					blue blue*0.5 blue*0.7)					///
		ramp(right	label(	`lab1' 	"Asthma" 				///
							`lab2' 	"Respiratory" 			///
							`lab3'	"CF", labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_resp.png", as(png) replace

							
* Delete unneeded variables 
drop *_`v' temp*



	
				
************************
*  Neurological graph  *
************************

local v = 4

* Categories to label (out of 9 total):
local labellist = "2 5 8"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')							///
		colors(		black 									///
					yellow yellow*0.5 yellow*0.7 			///
					midgreen midgreen*0.5 midgreen*0.7		///
					blue blue*0.5 blue*0.7)					///
		ramp(right	label(	`lab1' 	"Stroke" 				///
							`lab2' 	"Dementia" 				///
							`lab3'	"Other neuro.", 		///
							labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_neuro.png", as(png) replace

							
* Delete unneeded variables 
drop *_`v' temp*





	
				
************************
*  Kidney/liver graph  *
************************

local v = 5

* Categories to label (out of 12 total):
local labellist = "2 5 8 11"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')							///
		colors(		black 									///
					yellow yellow*0.5 yellow*0.7 			///
					midgreen midgreen*0.5 midgreen*0.7		///
					blue blue*0.5 blue*0.7					///
					red red*0.5 red*0.7) 					///
		ramp(right	label(	`lab1' 	"Kidney" 				///
							`lab2' 	"Dialysis" 				///
							`lab3'	"Liver"			 		///
							`lab4'	"Transplant", 			///
							labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_kidneyliv.png", as(png) replace

							
* Delete unneeded variables 
drop *_`v' temp*







				
******************
*  Cancer graph  *
******************

local v = 6

* Categories to label (out of 6 total):
local labellist = "2 5"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')							///
		colors(		black 									///
					yellow yellow*0.5 yellow*0.7 			///
					midgreen midgreen*0.5 midgreen*0.7)		///
		ramp(right	label(	`lab1' 	"Cancer, Ex Haem"		///
							`lab2' 	"Cancer, Haem", 		///
							labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_cancer.png", as(png) replace
 
							
* Delete unneeded variables 
drop *_`v' temp*



				
*****************************
*  Immunosuppression graph  *
*****************************

local v = 7

* Categories to label (out of 19 total):
local labellist = "2 4 7 9 11"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')					 		///
		colors(		black 									///
					yellow yellow*0.5 yellow*0.7 			///
					midgreen*0.5 midgreen*0.7				///
					blue blue*0.5 blue*0.7  				///
					red*0.5 red*0.7 						///
					magenta*0.5 magenta*0.7)				///
		ramp(right label(	`lab1' 	"Spleen" 				///
							`lab2' 	"RA/SLE/Psor." 			///
							`lab3'	"Immunosuppression" 	///
							`lab4' 	"HIV"					///	
							`lab5'	"IBD",					///
							labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_immuno.png", as(png) replace
 

							
* Delete unneeded variables 
drop *_`v' temp*



	
				
*****************
*  Other graph  *
*****************

local v = 8

* Categories to label (out of 9 total):
local labellist = "2 5 8"

* Mark categories of interest (finer categorisation incorporating type)
capture drop temp
egen temp = group(vargroup type) if vargp==`v'
qui sum temp
local ncat = r(max)

* List of "cuts" (category boundaries)
local st  = (1 - 1/2)/r(max)
local end = (r(max) - 1/2)/r(max)
local gap = (1/r(max))
noi di `st' (`gap') `end'
noi di "Cats" `ncat'


* Categories to label:
qui sum temp
local j = 1
forvalues i = 1 (1) `ncat' {
	local temp : list i in labellist
	if `temp'==1 {
		local lab`j' = `i'/r(max)
		local j = `j'+1
	}
}


* Recode according to vargp 
capture drop *_`v'
foreach var of varlist select* {
	gen `var'_`v' = .
	forvalues i = 1 (1) `ncat' {
		replace `var'_`v' = `i'/`ncat' if temp==`i' & `var'==1
	}
	recode `var'_`v' .= 0 
} 

* Put relevant variables in a matrix
sort vargroup type
mkmat 	select_`v' 				///
		select_geog1_`v'		///
		select_geog2_`v'		///
		select_geog4_`v' 		///
		select_geog5_`v' 		///
		select_geog6_`v' 		///
		select_geog7_`v' 		///
		select_time_`v'			///
		select_foi_`v' 			///
		select_ae_`v' 			///
		select_susp_`v' 		///
		if temp!=., matrix(M_`v')
	
heatplot M_`v',												///
		cuts(`st' (`gap') `end')							///
		colors(		black 									///
					yellow yellow*0.5 yellow*0.7 			///
					midgreen midgreen*0.5 midgreen*0.7		///
					blue blue*0.5 blue*0.7)					///
		ramp(right	label(	`lab1' 	"Fracture" 				///
							`lab2' 	"Intel. dis" 			///
							`lab3'	"SMI", labsize(tiny))	///
							subtitle(""))	///
		xlabel(	1 "A" 						///
				2 "A{subscript:-1}"			///
				3 "A{subscript:-2}" 		///
				4 "A{subscript:-4}" 		///
				5 "A{subscript:-5}" 		///
				6 "A{subscript:-6}" 		///
				7 "A{subscript:-7}" 		///
				8 "A{subscript:-time}"	 	///
				9 "B{subscript:FOI}" 		///
				10 "B{subscript:A&E}" 		///
				11 "B{subscript:Susp}") 	///
				ylabel(none)				
graph export "output\graphs\varselect_other.png", as(png) replace
 
							
* Delete unneeded variables 
drop *_`v' temp*


