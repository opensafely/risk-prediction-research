********************************************************************************
*
*	Do-file:			1601_plot_burden_infection.do
*
*	Written by:			Fizz
*
*	Data used:			data/ae_rates.dta
*						data/susp_rates.dta
*						data/foi_rates.dta
*
*	Data created:		None
*
*	Other output:		Log file:  1101_plot_burden_infection.log
*						SVG graphs: output/graphs/...
*											.../ae_reg`i'.svg      (i=1...7)
*											.../susp_reg`i'.svg    (i=1...7)
*											.../foi_reg`i'.svg     (i=1...7)

*
********************************************************************************
*
*	Purpose:			To graph the time-varying proxes for infection burden
*						by STP or region.
*
********************************************************************************



* Open a log file
capture log close
log using "output/1101_plot_burden_infection", text replace





*********************
*  GP and A&E data  *
*********************

use "data/ae_rates.dta", clear
merge 1:1 stp_combined date using "data/susp_rates",
drop _m




		
******************
*  Graphs  - A&E *
******************

replace stpname = "Buckinghams., Oxfords., Berks., Hamps., IoW" if ///
	 stpname=="Buckinghamshire, Oxfordshire and Berkshire, Hampshire, IoW"

* East England
scatter aerate date  if region_7==1,									///
		by(stpname, note("") title("East")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg1.svg", as(svg) replace

		
* London
scatter aerate date  if region_7==2,									///
		by(stpname, note("") title("London")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg2.svg", as(svg) replace


* Midlands
scatter aerate date  if region_7==3,									///
		by(stpname, note("") title("Midlands")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg3.svg", as(svg) replace
	

* North East/Yorkshire
scatter aerate date  if region_7==4,									///
		by(stpname, note("") title("North East/Yorkshire")) 			///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg4.svg", as(svg) replace


* North West
scatter aerate date  if region_7==5,									///
		by(stpname, note("") title("North West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg5.svg", as(svg) replace
	

* North West
scatter aerate date  if region_7==6,									///
		by(stpname, note("") title("South East")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg6.svg", as(svg) replace
	

* North West
scatter aerate date  if region_7==7,									///
		by(stpname, note("") title("South West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 6)) ylabel(0 (2) 6, angle(0))					///
		ytitle("A&E attendance rate" "(per 100,000)")
graph export "output/graphs/ae_reg7.svg", as(svg) replace
	
		

		
		
		
******************************************
*  Graphs  - GP suspected COVID-19 cases *
******************************************


* East England
scatter susp_rate date  if region_7==1,									///
		by(stpname, note("") title("East")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg1.svg", as(svg) replace

		
* London
scatter susp_rate date  if region_7==2,									///
		by(stpname, note("") title("London")) 							///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg2.svg", as(svg) replace


* Midlands
scatter susp_rate date  if region_7==3,									///
		by(stpname, note("") title("Midlands")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg3.svg", as(svg) replace
	

* North East/Yorkshire
scatter susp_rate date  if region_7==4,									///
		by(stpname, note("") title("North East/Yorkshire")) 			///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg4.svg", as(svg) replace


* North West
scatter susp_rate date  if region_7==5,									///
		by(stpname, note("") title("North West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg5.svg", as(svg) replace
	

* North West
scatter susp_rate date  if region_7==6,									///
		by(stpname, note("") title("South East")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg6.svg", as(svg) replace
	

* North West
scatter susp_rate date  if region_7==7,									///
		by(stpname, note("") title("South West")) 						///
		subtitle(, size(small))											///
		xtitle(" ") 													///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			///
		yscale(range(0 70)) ylabel(0 (20) 70, angle(0))					///
		ytitle("Suspected case rate" "(per 100,000)")
graph export "output/graphs/susp_reg7.svg", as(svg) replace
	
		

	
		
		
*******************
*  Graphs  - FOI  *
*******************


use  "data/foi_rates", clear
keep if inrange(date, d(1feb2020), d(7jun2020))

* East of England
scatter foi date  if region_7==1,										///
		title("East") 													///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			
graph export "output/graphs/foi_reg1.svg", as(svg) replace


* London
scatter foi date  if region_7==2,										///
		title("London") 												///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			
graph export "output/graphs/foi_reg2.svg", as(svg) replace

				
* Midlands
scatter foi date  if region_7==3,										///
		title("Midlands") 												///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))			
graph export "output/graphs/foi_reg3.svg", as(svg) replace

				
* North East and Yorkshire
scatter foi date  if region_7==4,										///
		title("North East and Yorkshire") 								///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))		
graph export "output/graphs/foi_reg4.svg", as(svg) replace
		

* North West
scatter foi date  if region_7==5,										///
		title("North West") 											///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))		
graph export "output/graphs/foi_reg5.svg", as(svg) replace
		

* South East
scatter foi date  if region_7==6,										///
		title("South East") 											///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))		
graph export "output/graphs/foi_reg6.svg", as(svg) replace
			

* South West
scatter foi date  if region_7==7,										///
		title("South West") 											///
		ytitle("Estimated FOI")											///
		xtitle(" ") 													///
		yscale(range(0 0.006)) ylabel(0 (0.002) 0.006, angle(0))		///
		xlabel(21946 "1feb2020" 21975 "1mar2020" 22006 "1apr2020"		///
				22036 "1may2020" 22067 "1jun2020", angle(90))		
graph export "output/graphs/foi_reg7.svg", as(svg) replace




* Close log file
log close


