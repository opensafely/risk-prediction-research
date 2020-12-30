********************************************************************************
*
*	Do-file:		000_cr_base_cohort_dataset.do
*
*	Programmed by:	Fizz & Krishnan & John
*
*	Data used:		Data in memory (from input.csv)
*
*	Data created:   data/cr_base_cohort.dta (full base cohort dataset)
*
*	Other output:	Log file:  000_cr_analysis_dataset.log
*
********************************************************************************
*
*	Purpose:		This do-file contains a program to calculate the COVID-AGE
*					using the variables available in OpenSAFELY.
*
*		NB: This uses the 10th update of COVID-AGE
*		Website: https://alama.org.uk/covid-19-medical-risk-assessment/
*		Accessed 22th Dec 2020
*  
********************************************************************************



capture program drop covidage
program define covidage



	gen covid_age = age

	* Sex
	replace covid_age = covid_age - 5 if male==0

	* Ethnicity
	replace covid_age = covid_age + 5 if inlist(ethnicity_8, 2, 3, 4) 	// Asian
	replace covid_age = covid_age + 7 if inlist(ethnicity_8, 5, 6) 		// Black
	replace covid_age = covid_age + 4 if inlist(ethnicity_8, 7) 		// Chinese
	replace covid_age = covid_age + 4.5 if inlist(ethnicity_8, 8) 		// Other
		   
	* BMI
	replace covid_age = covid_age + 7  if  obesecat==3 & inrange(age, 10, 24)
	replace covid_age = covid_age + 6  if  obesecat==3 & inrange(age, 25, 37)
	replace covid_age = covid_age + 5  if  obesecat==3 & inrange(age, 38, 46)
	replace covid_age = covid_age + 4  if  obesecat==3 & inrange(age, 47, 52)
	replace covid_age = covid_age + 3  if  obesecat==3 & inrange(age, 53, 60)
	replace covid_age = covid_age + 2  if  obesecat==3 & inrange(age, 61, 70)
	replace covid_age = covid_age + 1  if  obesecat==3 & inrange(age, 71, 110)

	replace covid_age = covid_age + 19  if  obesecat==4 & inrange(age, 10, 22)
	replace covid_age = covid_age + 18  if  obesecat==4 & inrange(age, 23, 36)
	replace covid_age = covid_age + 17 	if  obesecat==4 & inrange(age, 27, 30)
	replace covid_age = covid_age + 16 	if  obesecat==4 & inrange(age, 31, 34)
	replace covid_age = covid_age + 15  if  obesecat==4 & inrange(age, 35, 39)
	replace covid_age = covid_age + 14  if  obesecat==4 & inrange(age, 40, 43)
	replace covid_age = covid_age + 13  if  obesecat==4 & inrange(age, 44, 47)
	replace covid_age = covid_age + 12  if  obesecat==4 & inrange(age, 48, 50)
	replace covid_age = covid_age + 11  if  obesecat==4 & inrange(age, 51, 53)
	replace covid_age = covid_age + 10  if  obesecat==4 & inrange(age, 54, 57)
	replace covid_age = covid_age + 9  	if  obesecat==4 & inrange(age, 58, 60)
	replace covid_age = covid_age + 8  	if  obesecat==4 & inrange(age, 61, 63)
	replace covid_age = covid_age + 7  	if  obesecat==4 & inrange(age, 64, 66)
	replace covid_age = covid_age + 6  	if  obesecat==4 & inrange(age, 67, 68)
	replace covid_age = covid_age + 5  	if  obesecat==4 & inrange(age, 69, 71)
	replace covid_age = covid_age + 4  	if  obesecat==4 & inrange(age, 72, 73)
	replace covid_age = covid_age + 3  	if  obesecat==4 & inrange(age, 74, 110)

	replace covid_age = covid_age + 25  if  obesecat==5 & inrange(age, 10, 21)
	replace covid_age = covid_age + 24  if  obesecat==5 & inrange(age, 22, 24)
	replace covid_age = covid_age + 23 	if  obesecat==5 & inrange(age, 25, 27)
	replace covid_age = covid_age + 22 	if  obesecat==5 & inrange(age, 28, 30)
	replace covid_age = covid_age + 21  if  obesecat==5 & inrange(age, 31, 33)
	replace covid_age = covid_age + 20  if  obesecat==5 & inrange(age, 34, 35)
	replace covid_age = covid_age + 19  if  obesecat==5 & inrange(age, 36, 38)
	replace covid_age = covid_age + 18  if  obesecat==5 & inrange(age, 39, 40)
	replace covid_age = covid_age + 17  if  obesecat==5 & inrange(age, 41, 43)
	replace covid_age = covid_age + 16  if  obesecat==5 & inrange(age, 44, 46)
	replace covid_age = covid_age + 15 	if  obesecat==5 & inrange(age, 47, 48)
	replace covid_age = covid_age + 14 	if  obesecat==5 & inrange(age, 49, 51)
	replace covid_age = covid_age + 13 	if  obesecat==5 & inrange(age, 52, 53)
	replace covid_age = covid_age + 12 	if  obesecat==5 & inrange(age, 54, 56)
	replace covid_age = covid_age + 11 	if  obesecat==5 & inrange(age, 57, 59)
	replace covid_age = covid_age + 10 	if  obesecat==5 & inrange(age, 60, 62)
	replace covid_age = covid_age + 9  	if  obesecat==5 & inrange(age, 63, 65)
	replace covid_age = covid_age + 8  	if  obesecat==5 & inrange(age, 66, 67)
	replace covid_age = covid_age + 7  	if  obesecat==5 & inrange(age, 68, 70)
	replace covid_age = covid_age + 6  	if  obesecat==5 & inrange(age, 71, 72)
	replace covid_age = covid_age + 5  	if  obesecat==5 & inrange(age, 73, 110)


	* Hypertension
	replace covid_age = covid_age + 12  if  hypertension==1 & inrange(age, 10, 26)
	replace covid_age = covid_age + 11  if  hypertension==1 & inrange(age, 27, 33)
	replace covid_age = covid_age + 10  if  hypertension==1 & inrange(age, 34, 39)
	replace covid_age = covid_age + 9  	if  hypertension==1 & inrange(age, 40, 44)
	replace covid_age = covid_age + 8  	if  hypertension==1 & inrange(age, 45, 49)
	replace covid_age = covid_age + 7  	if  hypertension==1 & inrange(age, 50, 54)
	replace covid_age = covid_age + 6  	if  hypertension==1 & inrange(age, 55, 570)
	replace covid_age = covid_age + 5  	if  hypertension==1 & inrange(age, 58, 61)
	replace covid_age = covid_age + 4  	if  hypertension==1 & inrange(age, 62, 64)
	replace covid_age = covid_age + 3  	if  hypertension==1 & inrange(age, 65, 67)
	replace covid_age = covid_age + 2  	if  hypertension==1 & inrange(age, 68, 70)
	replace covid_age = covid_age + 1  	if  hypertension==1 & inrange(age, 71, 72)
	replace covid_age = covid_age + 0  	if  hypertension==1 & inrange(age, 73, 110)


	* Chronic heart disease
	replace covid_age = covid_age + 20  if cardiac==1 & inrange(age, 10, 25)
	replace covid_age = covid_age + 19  if cardiac==1 & inrange(age, 26, 30)
	replace covid_age = covid_age + 18 	if cardiac==1 & inrange(age, 31, 33)
	replace covid_age = covid_age + 17 	if cardiac==1 & inrange(age, 34, 37)
	replace covid_age = covid_age + 16  if cardiac==1 & inrange(age, 38, 40)
	replace covid_age = covid_age + 15  if cardiac==1 & inrange(age, 41, 43)
	replace covid_age = covid_age + 14  if cardiac==1 & inrange(age, 44, 46)
	replace covid_age = covid_age + 13  if cardiac==1 & inrange(age, 47, 50)
	replace covid_age = covid_age + 12  if cardiac==1 & inrange(age, 51, 54)
	replace covid_age = covid_age + 11  if cardiac==1 & inrange(age, 55, 56)
	replace covid_age = covid_age + 10 	if cardiac==1 & inrange(age, 57, 58)
	replace covid_age = covid_age + 9 	if cardiac==1 & inrange(age, 59, 60)
	replace covid_age = covid_age + 8 	if cardiac==1 & inrange(age, 61, 62)
	replace covid_age = covid_age + 7 	if cardiac==1 & inrange(age, 63, 64)
	replace covid_age = covid_age + 6 	if cardiac==1 & inrange(age, 65, 66)
	replace covid_age = covid_age + 5 	if cardiac==1 & inrange(age, 67, 69)
	replace covid_age = covid_age + 4  	if cardiac==1 & inrange(age, 70, 72)
	replace covid_age = covid_age + 3  	if cardiac==1 & inrange(age, 73, 110)

	* Cerebrovascular disease (stroke or dementia)
	replace covid_age = covid_age + 17  if max(dementia, stroke)==1 & inrange(age, 10, 22)
	replace covid_age = covid_age + 16  if max(dementia, stroke)==1 & inrange(age, 23, 36)
	replace covid_age = covid_age + 15  if max(dementia, stroke)==1 & inrange(age, 37, 46)
	replace covid_age = covid_age + 14  if max(dementia, stroke)==1 & inrange(age, 47, 52)
	replace covid_age = covid_age + 13  if max(dementia, stroke)==1 & inrange(age, 53, 57)
	replace covid_age = covid_age + 12  if max(dementia, stroke)==1 & inrange(age, 58, 62)
	replace covid_age = covid_age + 11  if max(dementia, stroke)==1 & inrange(age, 63, 67)
	replace covid_age = covid_age + 10  if max(dementia, stroke)==1 & inrange(age, 68, 71)
	replace covid_age = covid_age + 9   if max(dementia, stroke)==1 & inrange(age, 72, 110)



	* Asthma
	replace covid_age = covid_age + 1  if  asthmacat==2 

	replace covid_age = covid_age + 15  if  asthmacat==3 & inrange(age, 10, 25)
	replace covid_age = covid_age + 14  if  asthmacat==3 & inrange(age, 26, 32)
	replace covid_age = covid_age + 13  if  asthmacat==3 & inrange(age, 33, 37)
	replace covid_age = covid_age + 12  if  asthmacat==3 & inrange(age, 38, 42)
	replace covid_age = covid_age + 11  if  asthmacat==3 & inrange(age, 43, 46)
	replace covid_age = covid_age + 10 	if  asthmacat==3 & inrange(age, 47, 49)
	replace covid_age = covid_age + 9 	if  asthmacat==3 & inrange(age, 50, 53)
	replace covid_age = covid_age + 8 	if  asthmacat==3 & inrange(age, 54, 56)
	replace covid_age = covid_age + 7 	if  asthmacat==3 & inrange(age, 57, 59)
	replace covid_age = covid_age + 6 	if  asthmacat==3 & inrange(age, 60, 61)
	replace covid_age = covid_age + 5 	if  asthmacat==3 & inrange(age, 62, 63)
	replace covid_age = covid_age + 4  	if  asthmacat==3 & inrange(age, 64, 67)
	replace covid_age = covid_age + 3  	if  asthmacat==3 & inrange(age, 68, 72)
	replace covid_age = covid_age + 2  	if  asthmacat==3 & inrange(age, 73, 110)

	* Other respiratory
	replace covid_age = covid_age + 17  if  max(respiratory, cf)==1 & inrange(age, 10, 24)
	replace covid_age = covid_age + 16  if  max(respiratory, cf)==1 & inrange(age, 25, 30)
	replace covid_age = covid_age + 15  if  max(respiratory, cf)==1 & inrange(age, 31, 35)
	replace covid_age = covid_age + 14  if  max(respiratory, cf)==1 & inrange(age, 36, 40)
	replace covid_age = covid_age + 13  if  max(respiratory, cf)==1 & inrange(age, 41, 46)
	replace covid_age = covid_age + 12  if  max(respiratory, cf)==1 & inrange(age, 47, 51)
	replace covid_age = covid_age + 11  if  max(respiratory, cf)==1 & inrange(age, 52, 55)
	replace covid_age = covid_age + 10 	if  max(respiratory, cf)==1 & inrange(age, 56, 58)
	replace covid_age = covid_age + 9 	if  max(respiratory, cf)==1 & inrange(age, 59, 61)
	replace covid_age = covid_age + 8 	if  max(respiratory, cf)==1 & inrange(age, 62, 64)
	replace covid_age = covid_age + 7 	if  max(respiratory, cf)==1 & inrange(age, 65, 69)
	replace covid_age = covid_age + 6 	if  max(respiratory, cf)==1 & inrange(age, 70, 110)



	* Diabetes
	replace covid_age = covid_age + 24  if  diabetes==2 & inrange(age, 10, 25)
	replace covid_age = covid_age + 23  if  diabetes==2 & inrange(age, 26, 31)
	replace covid_age = covid_age + 22  if  diabetes==2 & inrange(age, 32, 36)
	replace covid_age = covid_age + 21  if  diabetes==2 & inrange(age, 37, 41)
	replace covid_age = covid_age + 20  if  diabetes==2 & inrange(age, 42, 46)
	replace covid_age = covid_age + 19  if  diabetes==2 & inrange(age, 47, 48)
	replace covid_age = covid_age + 18  if  diabetes==2 & inrange(age, 49, 51)
	replace covid_age = covid_age + 17  if  diabetes==2 & inrange(age, 52, 53)
	replace covid_age = covid_age + 16  if  diabetes==2 & inrange(age, 54, 56)
	replace covid_age = covid_age + 15  if  diabetes==2 & inrange(age, 57, 58)
	replace covid_age = covid_age + 14  if  diabetes==2 & inrange(age, 59, 60)
	replace covid_age = covid_age + 13  if  diabetes==2 & inrange(age, 61, 62)
	replace covid_age = covid_age + 12  if  diabetes==2 & inrange(age, 63, 64)
	replace covid_age = covid_age + 11  if  diabetes==2 & inrange(age, 65, 67)
	replace covid_age = covid_age + 10  if  diabetes==2 & inrange(age, 68, 70)
	replace covid_age = covid_age + 9   if  diabetes==2 & inrange(age, 71, 72)
	replace covid_age = covid_age + 8   if  diabetes==2 & inrange(age, 73, 110)

	replace covid_age = covid_age + 27  if  diabetes==3 & inrange(age, 10, 25)
	replace covid_age = covid_age + 26  if  diabetes==3 & inrange(age, 26, 31)
	replace covid_age = covid_age + 25  if  diabetes==3 & inrange(age, 32, 37)
	replace covid_age = covid_age + 24  if  diabetes==3 & inrange(age, 38, 42)
	replace covid_age = covid_age + 23  if  diabetes==3 & inrange(age, 43, 46)
	replace covid_age = covid_age + 22  if  diabetes==3 & inrange(age, 47, 49)
	replace covid_age = covid_age + 21  if  diabetes==3 & inrange(age, 50, 51)
	replace covid_age = covid_age + 20  if  diabetes==3 & inrange(age, 52, 53)
	replace covid_age = covid_age + 19  if  diabetes==3 & inrange(age, 54, 56)
	replace covid_age = covid_age + 18  if  diabetes==3 & inrange(age, 57, 58)
	replace covid_age = covid_age + 17  if  diabetes==3 & inrange(age, 59, 60)
	replace covid_age = covid_age + 16  if  diabetes==3 & inrange(age, 61, 62)
	replace covid_age = covid_age + 15  if  diabetes==3 & inrange(age, 63, 64)
	replace covid_age = covid_age + 14  if  diabetes==3 & inrange(age, 65, 67)
	replace covid_age = covid_age + 13  if  diabetes==3 & inrange(age, 68, 70)
	replace covid_age = covid_age + 12  if  diabetes==3 & inrange(age, 71, 73)
	replace covid_age = covid_age + 11  if  diabetes==3 & inrange(age, 74, 110)

	replace covid_age = covid_age + 29  if  diabetes==4 & inrange(age, 10, 24)
	replace covid_age = covid_age + 28  if  diabetes==4 & inrange(age, 25, 32)
	replace covid_age = covid_age + 27  if  diabetes==4 & inrange(age, 33, 37)
	replace covid_age = covid_age + 26  if  diabetes==4 & inrange(age, 38, 41)
	replace covid_age = covid_age + 25  if  diabetes==4 & inrange(age, 42, 45)
	replace covid_age = covid_age + 24  if  diabetes==4 & inrange(age, 46, 48)
	replace covid_age = covid_age + 23  if  diabetes==4 & inrange(age, 49, 51)
	replace covid_age = covid_age + 22  if  diabetes==4 & inrange(age, 52, 53)
	replace covid_age = covid_age + 21  if  diabetes==4 & inrange(age, 54, 55)
	replace covid_age = covid_age + 20  if  diabetes==4 & inrange(age, 56, 57)
	replace covid_age = covid_age + 19  if  diabetes==4 & inrange(age, 58, 59)
	replace covid_age = covid_age + 18  if  diabetes==4 & inrange(age, 60, 61)
	replace covid_age = covid_age + 17  if  diabetes==4 & inrange(age, 62, 63)
	replace covid_age = covid_age + 16  if  diabetes==4 & inrange(age, 64, 65)
	replace covid_age = covid_age + 15  if  diabetes==4 & inrange(age, 66, 67)
	replace covid_age = covid_age + 14  if  diabetes==4 & inrange(age, 68, 70)
	replace covid_age = covid_age + 13  if  diabetes==4 & inrange(age, 71, 72)
	replace covid_age = covid_age + 12  if  diabetes==4 & inrange(age, 73, 110)


	* Reduced kidney function
	replace covid_age = covid_age + 42  if  kidneyfn==2 & inrange(age, 10, 20)
	replace covid_age = covid_age + 41  if  kidneyfn==2 & age==21
	replace covid_age = covid_age + 40  if  kidneyfn==2 & age==22
	replace covid_age = covid_age + 39  if  kidneyfn==2 & age==23
	replace covid_age = covid_age + 38  if  kidneyfn==2 & age==24
	replace covid_age = covid_age + 37  if  kidneyfn==2 & inrange(age, 25, 26)
	replace covid_age = covid_age + 36  if  kidneyfn==2 & age==27
	replace covid_age = covid_age + 35  if  kidneyfn==2 & age==28
	replace covid_age = covid_age + 34  if  kidneyfn==2 & age==29
	replace covid_age = covid_age + 33  if  kidneyfn==2 & age==30
	replace covid_age = covid_age + 32  if  kidneyfn==2 & inrange(age, 31, 32)
	replace covid_age = covid_age + 31  if  kidneyfn==2 & age==33
	replace covid_age = covid_age + 30  if  kidneyfn==2 & age==34
	replace covid_age = covid_age + 29  if  kidneyfn==2 & age==35
	replace covid_age = covid_age + 28  if  kidneyfn==2 & age==36
	replace covid_age = covid_age + 27  if  kidneyfn==2 & age==37
	replace covid_age = covid_age + 26  if  kidneyfn==2 & inrange(age, 38, 39)
	replace covid_age = covid_age + 25  if  kidneyfn==2 & age==40
	replace covid_age = covid_age + 24  if  kidneyfn==2 & age==41
	replace covid_age = covid_age + 23  if  kidneyfn==2 & age==42
	replace covid_age = covid_age + 22  if  kidneyfn==2 & age==43
	replace covid_age = covid_age + 21  if  kidneyfn==2 & age==44
	replace covid_age = covid_age + 20  if  kidneyfn==2 & age==45
	replace covid_age = covid_age + 19  if  kidneyfn==2 & inrange(age, 46, 47)
	replace covid_age = covid_age + 18  if  kidneyfn==2 & inrange(age, 48, 49)
	replace covid_age = covid_age + 17  if  kidneyfn==2 & age==50
	replace covid_age = covid_age + 16  if  kidneyfn==2 & inrange(age, 51, 52)
	replace covid_age = covid_age + 15  if  kidneyfn==2 & age==53
	replace covid_age = covid_age + 14  if  kidneyfn==2 & inrange(age, 54, 55)
	replace covid_age = covid_age + 13  if  kidneyfn==2 & inrange(age, 56, 57)
	replace covid_age = covid_age + 12  if  kidneyfn==2 & age==58
	replace covid_age = covid_age + 11  if  kidneyfn==2 & inrange(age, 59, 60)
	replace covid_age = covid_age + 10  if  kidneyfn==2 & age==61
	replace covid_age = covid_age + 9  if  kidneyfn==2 & inrange(age, 62, 63)
	replace covid_age = covid_age + 8  if  kidneyfn==2 & inrange(age, 64, 65)
	replace covid_age = covid_age + 7  if  kidneyfn==2 & inrange(age, 66, 67)
	replace covid_age = covid_age + 6  if  kidneyfn==2 & inrange(age, 68, 69)
	replace covid_age = covid_age + 5  if  kidneyfn==2 & inrange(age, 70, 71)
	replace covid_age = covid_age + 4  if  kidneyfn==2 & inrange(age, 72, 73)
	replace covid_age = covid_age + 3  if  kidneyfn==2 & inrange(age, 74, 110)


	replace covid_age = covid_age + 53  if  kidneyfn==3 & inrange(age, 10, 20)
	replace covid_age = covid_age + 52  if  kidneyfn==3 & age==21
	replace covid_age = covid_age + 51  if  kidneyfn==3 & age==22
	replace covid_age = covid_age + 50  if  kidneyfn==3 & inrange(age, 23, 24)
	replace covid_age = covid_age + 49  if  kidneyfn==3 & age==25
	replace covid_age = covid_age + 48  if  kidneyfn==3 & age==26
	replace covid_age = covid_age + 47  if  kidneyfn==3 & age==27
	replace covid_age = covid_age + 46  if  kidneyfn==3 & inrange(age, 28, 29)
	replace covid_age = covid_age + 45  if  kidneyfn==3 & age==30
	replace covid_age = covid_age + 44  if  kidneyfn==3 & inrange(age, 31, 32)
	replace covid_age = covid_age + 43  if  kidneyfn==3 & age==33
	replace covid_age = covid_age + 42  if  kidneyfn==3 & age==34
	replace covid_age = covid_age + 41  if  kidneyfn==3 & age==35
	replace covid_age = covid_age + 40  if  kidneyfn==3 & age==36
	replace covid_age = covid_age + 39  if  kidneyfn==3 & age==37
	replace covid_age = covid_age + 38  if  kidneyfn==3 & age==38
	replace covid_age = covid_age + 37  if  kidneyfn==3 & age==39
	replace covid_age = covid_age + 36  if  kidneyfn==3 & age==40
	replace covid_age = covid_age + 35  if  kidneyfn==3 & inrange(age, 41, 42)
	replace covid_age = covid_age + 34  if  kidneyfn==3 & age==43
	replace covid_age = covid_age + 33  if  kidneyfn==3 & inrange(age, 44, 45)
	replace covid_age = covid_age + 32  if  kidneyfn==3 & inrange(age, 46, 47)
	replace covid_age = covid_age + 31  if  kidneyfn==3 & age==48
	replace covid_age = covid_age + 30  if  kidneyfn==3 & inrange(age, 49, 50)
	replace covid_age = covid_age + 29  if  kidneyfn==3 & age==51
	replace covid_age = covid_age + 28  if  kidneyfn==3 & inrange(age, 52, 53)
	replace covid_age = covid_age + 27  if  kidneyfn==3 & age==54
	replace covid_age = covid_age + 26  if  kidneyfn==3 & inrange(age, 55, 56)
	replace covid_age = covid_age + 25  if  kidneyfn==3 & age==57
	replace covid_age = covid_age + 24  if  kidneyfn==3 & age==58
	replace covid_age = covid_age + 23  if  kidneyfn==3 & inrange(age, 59, 60)
	replace covid_age = covid_age + 22  if  kidneyfn==3 & inrange(age, 61, 62)
	replace covid_age = covid_age + 21  if  kidneyfn==3 & age==63
	replace covid_age = covid_age + 20  if  kidneyfn==3 & inrange(age, 64, 65)
	replace covid_age = covid_age + 19  if  kidneyfn==3 & inrange(age, 66, 67)
	replace covid_age = covid_age + 18  if  kidneyfn==3 & inrange(age, 68, 69)
	replace covid_age = covid_age + 17  if  kidneyfn==3 & inrange(age, 70, 71)
	replace covid_age = covid_age + 16  if  kidneyfn==3 & inrange(age, 72, 73)
	replace covid_age = covid_age + 15  if  kidneyfn==3 & inrange(age, 74, 110)



	* Non-haematological cancer
	replace covid_age = covid_age + 34  if  cancerExhaem==2 & inrange(age, 10, 20)
	replace covid_age = covid_age + 33  if  cancerExhaem==2 & inrange(age, 21, 22)
	replace covid_age = covid_age + 32  if  cancerExhaem==2 & inrange(age, 23, 24)
	replace covid_age = covid_age + 31  if  cancerExhaem==2 & inrange(age, 25, 26)
	replace covid_age = covid_age + 30  if  cancerExhaem==2 & inrange(age, 27, 28)
	replace covid_age = covid_age + 29  if  cancerExhaem==2 & inrange(age, 29, 30)
	replace covid_age = covid_age + 28  if  cancerExhaem==2 & inrange(age, 31, 32)
	replace covid_age = covid_age + 27  if  cancerExhaem==2 & inrange(age, 33, 34)
	replace covid_age = covid_age + 26  if  cancerExhaem==2 & inrange(age, 35, 36)
	replace covid_age = covid_age + 25  if  cancerExhaem==2 & inrange(age, 37, 38)
	replace covid_age = covid_age + 24  if  cancerExhaem==2 & inrange(age, 39, 40)
	replace covid_age = covid_age + 23  if  cancerExhaem==2 & inrange(age, 41, 42)
	replace covid_age = covid_age + 22  if  cancerExhaem==2 & inrange(age, 43, 44)
	replace covid_age = covid_age + 21  if  cancerExhaem==2 & inrange(age, 45, 46)
	replace covid_age = covid_age + 20  if  cancerExhaem==2 & inrange(age, 47, 48)
	replace covid_age = covid_age + 19  if  cancerExhaem==2 & inrange(age, 49, 50)
	replace covid_age = covid_age + 18  if  cancerExhaem==2 & inrange(age, 51, 52)
	replace covid_age = covid_age + 17  if  cancerExhaem==2 & age==53
	replace covid_age = covid_age + 16  if  cancerExhaem==2 & inrange(age, 54, 55)
	replace covid_age = covid_age + 15  if  cancerExhaem==2 & inrange(age, 56, 56)
	replace covid_age = covid_age + 14  if  cancerExhaem==2 & inrange(age, 58, 59)
	replace covid_age = covid_age + 13  if  cancerExhaem==2 & inrange(age, 60, 61)
	replace covid_age = covid_age + 12  if  cancerExhaem==2 & inrange(age, 62, 63)
	replace covid_age = covid_age + 11  if  cancerExhaem==2 & inrange(age, 64, 65)
	replace covid_age = covid_age + 10  if  cancerExhaem==2 & inrange(age, 66, 67)
	replace covid_age = covid_age + 9   if  cancerExhaem==2 & inrange(age, 68, 70)
	replace covid_age = covid_age + 8   if  cancerExhaem==2 & inrange(age, 71, 73)
	replace covid_age = covid_age + 7   if  cancerExhaem==2 & inrange(age, 74, 110)


	replace covid_age = covid_age + 25  if  cancerExhaem==3 & inrange(age, 10, 22)
	replace covid_age = covid_age + 24  if  cancerExhaem==3 & inrange(age, 23, 25)
	replace covid_age = covid_age + 23  if  cancerExhaem==3 & inrange(age, 26, 27)
	replace covid_age = covid_age + 22  if  cancerExhaem==3 & inrange(age, 28, 30)
	replace covid_age = covid_age + 21  if  cancerExhaem==3 & inrange(age, 31, 33)
	replace covid_age = covid_age + 20  if  cancerExhaem==3 & inrange(age, 34, 35)
	replace covid_age = covid_age + 19  if  cancerExhaem==3 & inrange(age, 36, 37)
	replace covid_age = covid_age + 18  if  cancerExhaem==3 & inrange(age, 38, 40)
	replace covid_age = covid_age + 17  if  cancerExhaem==3 & inrange(age, 41, 42)
	replace covid_age = covid_age + 16  if  cancerExhaem==3 & inrange(age, 43, 45)
	replace covid_age = covid_age + 15  if  cancerExhaem==3 & inrange(age, 46, 47)
	replace covid_age = covid_age + 14  if  cancerExhaem==3 & inrange(age, 48, 48)
	replace covid_age = covid_age + 13  if  cancerExhaem==3 & inrange(age, 49, 50)
	replace covid_age = covid_age + 12  if  cancerExhaem==3 & inrange(age, 51, 51)
	replace covid_age = covid_age + 11  if  cancerExhaem==3 & inrange(age, 52, 53)
	replace covid_age = covid_age + 10  if  cancerExhaem==3 & inrange(age, 54, 55)
	replace covid_age = covid_age + 9   if  cancerExhaem==3 & inrange(age, 56, 57)
	replace covid_age = covid_age + 8   if  cancerExhaem==3 & inrange(age, 58, 60)
	replace covid_age = covid_age + 7   if  cancerExhaem==3 & inrange(age, 61, 63)
	replace covid_age = covid_age + 6   if  cancerExhaem==3 & inrange(age, 64, 66)
	replace covid_age = covid_age + 5   if  cancerExhaem==3 & inrange(age, 67, 68)
	replace covid_age = covid_age + 4   if  cancerExhaem==3 & inrange(age, 69, 70)
	replace covid_age = covid_age + 3   if  cancerExhaem==3 & inrange(age, 71, 73)
	replace covid_age = covid_age + 2   if  cancerExhaem==3 & inrange(age, 74, 110)

	replace covid_age = covid_age + 18  if  cancerExhaem==4 & inrange(age, 10, 23)
	replace covid_age = covid_age + 17  if  cancerExhaem==4 & inrange(age, 24, 26)
	replace covid_age = covid_age + 16  if  cancerExhaem==4 & inrange(age, 27, 29)
	replace covid_age = covid_age + 15  if  cancerExhaem==4 & inrange(age, 30, 32)
	replace covid_age = covid_age + 14  if  cancerExhaem==4 & inrange(age, 33, 34)
	replace covid_age = covid_age + 13  if  cancerExhaem==4 & inrange(age, 35, 36)
	replace covid_age = covid_age + 12  if  cancerExhaem==4 & inrange(age, 37, 38)
	replace covid_age = covid_age + 11  if  cancerExhaem==4 & inrange(age, 39, 41)
	replace covid_age = covid_age + 10  if  cancerExhaem==4 & inrange(age, 42, 44)
	replace covid_age = covid_age + 9   if  cancerExhaem==4 & inrange(age, 45, 47)
	replace covid_age = covid_age + 8   if  cancerExhaem==4 & inrange(age, 48, 50)
	replace covid_age = covid_age + 7   if  cancerExhaem==4 & inrange(age, 51, 53)
	replace covid_age = covid_age + 6   if  cancerExhaem==4 & inrange(age, 54, 56)
	replace covid_age = covid_age + 5   if  cancerExhaem==4 & inrange(age, 57, 58)
	replace covid_age = covid_age + 4   if  cancerExhaem==4 & inrange(age, 59, 60)
	replace covid_age = covid_age + 3   if  cancerExhaem==4 & inrange(age, 61, 62)
	replace covid_age = covid_age + 2   if  cancerExhaem==4 & inrange(age, 63, 64)
	replace covid_age = covid_age + 1   if  cancerExhaem==4 & inrange(age, 65, 68)
	replace covid_age = covid_age + 0   if  cancerExhaem==4 & inrange(age, 69, 110)

	* Hematological malignancy
	replace covid_age = covid_age + 33   if  cancerHaem==2 & inrange(age, 10, 21)
	replace covid_age = covid_age + 32   if  cancerHaem==2 & inrange(age, 22, 25)
	replace covid_age = covid_age + 31   if  cancerHaem==2 & inrange(age, 26, 29)
	replace covid_age = covid_age + 30   if  cancerHaem==2 & inrange(age, 30, 33)
	replace covid_age = covid_age + 29   if  cancerHaem==2 & inrange(age, 34, 37)
	replace covid_age = covid_age + 28   if  cancerHaem==2 & inrange(age, 38, 41)
	replace covid_age = covid_age + 27   if  cancerHaem==2 & inrange(age, 42, 44)
	replace covid_age = covid_age + 26   if  cancerHaem==2 & inrange(age, 45, 47)
	replace covid_age = covid_age + 25   if  cancerHaem==2 & inrange(age, 48, 49)
	replace covid_age = covid_age + 24   if  cancerHaem==2 & inrange(age, 50, 51)
	replace covid_age = covid_age + 23   if  cancerHaem==2 & inrange(age, 52, 53)
	replace covid_age = covid_age + 22   if  cancerHaem==2 & inrange(age, 54, 55)
	replace covid_age = covid_age + 21   if  cancerHaem==2 & inrange(age, 56, 57)
	replace covid_age = covid_age + 20   if  cancerHaem==2 & inrange(age, 58, 59)
	replace covid_age = covid_age + 19   if  cancerHaem==2 & inrange(age, 60, 61)
	replace covid_age = covid_age + 18   if  cancerHaem==2 & inrange(age, 62, 62)
	replace covid_age = covid_age + 17   if  cancerHaem==2 & inrange(age, 63, 64)
	replace covid_age = covid_age + 16   if  cancerHaem==2 & inrange(age, 65, 66)
	replace covid_age = covid_age + 15   if  cancerHaem==2 & inrange(age, 67, 68)
	replace covid_age = covid_age + 14   if  cancerHaem==2 & inrange(age, 69, 70)
	replace covid_age = covid_age + 13   if  cancerHaem==2 & inrange(age, 71, 72)
	replace covid_age = covid_age + 12   if  cancerHaem==2 & inrange(age, 73, 74)
	replace covid_age = covid_age + 11   if  cancerHaem==2 & inrange(age, 75, 110)

	replace covid_age = covid_age + 32   if  cancerHaem==3 & inrange(age, 10, 20)
	replace covid_age = covid_age + 31   if  cancerHaem==3 & inrange(age, 21, 23)
	replace covid_age = covid_age + 30   if  cancerHaem==3 & inrange(age, 24, 26)
	replace covid_age = covid_age + 29   if  cancerHaem==3 & inrange(age, 27, 29)
	replace covid_age = covid_age + 28   if  cancerHaem==3 & inrange(age, 30, 32)
	replace covid_age = covid_age + 27   if  cancerHaem==3 & inrange(age, 33, 35)
	replace covid_age = covid_age + 26   if  cancerHaem==3 & inrange(age, 36, 37)
	replace covid_age = covid_age + 25   if  cancerHaem==3 & inrange(age, 38, 40)
	replace covid_age = covid_age + 24   if  cancerHaem==3 & inrange(age, 41, 42)
	replace covid_age = covid_age + 23   if  cancerHaem==3 & inrange(age, 43, 44)
	replace covid_age = covid_age + 22   if  cancerHaem==3 & inrange(age, 45, 49)
	replace covid_age = covid_age + 21   if  cancerHaem==3 & inrange(age, 50, 53)
	replace covid_age = covid_age + 20   if  cancerHaem==3 & inrange(age, 54, 56)
	replace covid_age = covid_age + 19   if  cancerHaem==3 & inrange(age, 57, 58)
	replace covid_age = covid_age + 18   if  cancerHaem==3 & inrange(age, 59, 60)
	replace covid_age = covid_age + 17   if  cancerHaem==3 & inrange(age, 61, 62)
	replace covid_age = covid_age + 16   if  cancerHaem==3 & inrange(age, 63, 64)
	replace covid_age = covid_age + 15   if  cancerHaem==3 & inrange(age, 65, 66)
	replace covid_age = covid_age + 14   if  cancerHaem==3 & inrange(age, 67, 68)
	replace covid_age = covid_age + 13   if  cancerHaem==3 & inrange(age, 69, 70)
	replace covid_age = covid_age + 12   if  cancerHaem==3 & inrange(age, 71, 72)
	replace covid_age = covid_age + 11   if  cancerHaem==3 & inrange(age, 73, 110)


	replace covid_age = covid_age + 21   if  cancerHaem==4 & inrange(age, 10, 24)
	replace covid_age = covid_age + 20   if  cancerHaem==4 & inrange(age, 25, 30)
	replace covid_age = covid_age + 19   if  cancerHaem==4 & inrange(age, 31, 34)
	replace covid_age = covid_age + 18   if  cancerHaem==4 & inrange(age, 35, 38)
	replace covid_age = covid_age + 17   if  cancerHaem==4 & inrange(age, 39, 42)
	replace covid_age = covid_age + 16   if  cancerHaem==4 & inrange(age, 43, 45)
	replace covid_age = covid_age + 15   if  cancerHaem==4 & inrange(age, 46, 47)
	replace covid_age = covid_age + 14   if  cancerHaem==4 & inrange(age, 48, 49)
	replace covid_age = covid_age + 13   if  cancerHaem==4 & inrange(age, 50, 50)
	replace covid_age = covid_age + 12   if  cancerHaem==4 & inrange(age, 51, 52)
	replace covid_age = covid_age + 11   if  cancerHaem==4 & inrange(age, 53, 54)
	replace covid_age = covid_age + 10   if  cancerHaem==4 & inrange(age, 55, 57)
	replace covid_age = covid_age + 9   if  cancerHaem==4 & inrange(age, 58, 60)
	replace covid_age = covid_age + 8   if  cancerHaem==4 & inrange(age, 61, 63)
	replace covid_age = covid_age + 7   if  cancerHaem==4 & inrange(age, 64, 67)
	replace covid_age = covid_age + 6   if  cancerHaem==4 & inrange(age, 68, 71)
	replace covid_age = covid_age + 5   if  cancerHaem==4 & inrange(age, 72, 75)

	* Liver disease
	replace covid_age = covid_age + 32   if  liver==1 & inrange(age, 10, 20)
	replace covid_age = covid_age + 31   if  liver==1 & inrange(age, 21, 22)
	replace covid_age = covid_age + 30   if  liver==1 & inrange(age, 23, 24)
	replace covid_age = covid_age + 29   if  liver==1 & inrange(age, 25, 26)
	replace covid_age = covid_age + 28   if  liver==1 & inrange(age, 27, 28)
	replace covid_age = covid_age + 27   if  liver==1 & inrange(age, 29, 30)
	replace covid_age = covid_age + 26   if  liver==1 & inrange(age, 31, 32)
	replace covid_age = covid_age + 25   if  liver==1 & inrange(age, 33, 34)
	replace covid_age = covid_age + 24   if  liver==1 & inrange(age, 35, 36)
	replace covid_age = covid_age + 23   if  liver==1 & inrange(age, 37, 38)
	replace covid_age = covid_age + 22   if  liver==1 & inrange(age, 39, 40)
	replace covid_age = covid_age + 21   if  liver==1 & inrange(age, 41, 42)
	replace covid_age = covid_age + 20   if  liver==1 & inrange(age, 43, 44)
	replace covid_age = covid_age + 19   if  liver==1 & inrange(age, 45, 46)
	replace covid_age = covid_age + 18   if  liver==1 & inrange(age, 47, 47)
	replace covid_age = covid_age + 17   if  liver==1 & inrange(age, 48, 49)
	replace covid_age = covid_age + 16   if  liver==1 & inrange(age, 50, 50)
	replace covid_age = covid_age + 15   if  liver==1 & inrange(age, 51, 52)
	replace covid_age = covid_age + 14   if  liver==1 & inrange(age, 53, 54)
	replace covid_age = covid_age + 13   if  liver==1 & inrange(age, 55, 56)
	replace covid_age = covid_age + 12   if  liver==1 & inrange(age, 57, 58)
	replace covid_age = covid_age + 11   if  liver==1 & inrange(age, 59, 61)
	replace covid_age = covid_age + 10   if  liver==1 & inrange(age, 61, 62)
	replace covid_age = covid_age + 9    if  liver==1 & inrange(age, 63, 64)
	replace covid_age = covid_age + 8    if  liver==1 & inrange(age, 65, 66)
	replace covid_age = covid_age + 7    if  liver==1 & inrange(age, 67, 68)
	replace covid_age = covid_age + 6    if  liver==1 & inrange(age, 69, 71)
	replace covid_age = covid_age + 5    if  liver==1 & inrange(age, 72, 73)
	replace covid_age = covid_age + 4    if  liver==1 & inrange(age, 74, 110)


	* Other neurological (other than stroke and dementia)
	replace covid_age = covid_age + 23   if  neuro==1 & inrange(age, 10, 21)
	replace covid_age = covid_age + 22   if  neuro==1 & inrange(age, 22, 31)
	replace covid_age = covid_age + 21   if  neuro==1 & inrange(age, 32, 38)
	replace covid_age = covid_age + 20   if  neuro==1 & inrange(age, 39, 45)
	replace covid_age = covid_age + 19   if  neuro==1 & inrange(age, 46, 49)
	replace covid_age = covid_age + 18   if  neuro==1 & inrange(age, 50, 53)
	replace covid_age = covid_age + 17   if  neuro==1 & inrange(age, 54, 56)
	replace covid_age = covid_age + 16   if  neuro==1 & inrange(age, 57, 60)
	replace covid_age = covid_age + 15   if  neuro==1 & inrange(age, 61, 63)
	replace covid_age = covid_age + 14   if  neuro==1 & inrange(age, 64, 67)
	replace covid_age = covid_age + 13   if  neuro==1 & inrange(age, 68, 71)
	replace covid_age = covid_age + 12   if  neuro==1 & inrange(age, 72, 110)

	* Organ transplant
	replace covid_age = covid_age + 25   if  transplant==1 & inrange(age, 10, 21)
	replace covid_age = covid_age + 24   if  transplant==1 & inrange(age, 22, 29)
	replace covid_age = covid_age + 23   if  transplant==1 & inrange(age, 30, 35)
	replace covid_age = covid_age + 22   if  transplant==1 & inrange(age, 36, 41)
	replace covid_age = covid_age + 21   if  transplant==1 & inrange(age, 42, 46)
	replace covid_age = covid_age + 20   if  transplant==1 & inrange(age, 47, 49)
	replace covid_age = covid_age + 19   if  transplant==1 & inrange(age, 50, 52)
	replace covid_age = covid_age + 18   if  transplant==1 & inrange(age, 53, 55)
	replace covid_age = covid_age + 17   if  transplant==1 & inrange(age, 56, 57)
	replace covid_age = covid_age + 16   if  transplant==1 & inrange(age, 58, 59)
	replace covid_age = covid_age + 15   if  transplant==1 & inrange(age, 60, 61)
	replace covid_age = covid_age + 14   if  transplant==1 & inrange(age, 62, 63)
	replace covid_age = covid_age + 13   if  transplant==1 & inrange(age, 64, 65)
	replace covid_age = covid_age + 12   if  transplant==1 & inrange(age, 66, 67)
	replace covid_age = covid_age + 11   if  transplant==1 & inrange(age, 68, 69)
	replace covid_age = covid_age + 10   if  transplant==1 & inrange(age, 70, 71)
	replace covid_age = covid_age + 9   if  transplant==1 & inrange(age, 72, 73)
	replace covid_age = covid_age + 8   if  transplant==1 & inrange(age, 74, 110)


	* Spleen
	replace covid_age = covid_age + 14  if  spleen==1 & inrange(age, 10, 21)
	replace covid_age = covid_age + 13  if  spleen==1 & inrange(age, 22, 32)
	replace covid_age = covid_age + 12  if  spleen==1 & inrange(age, 33, 39)
	replace covid_age = covid_age + 11  if  spleen==1 & inrange(age, 40, 45)
	replace covid_age = covid_age + 10  if  spleen==1 & inrange(age, 46, 49)
	replace covid_age = covid_age + 9   if  spleen==1 & inrange(age, 50, 52)
	replace covid_age = covid_age + 8   if  spleen==1 & inrange(age, 53, 56)
	replace covid_age = covid_age + 7   if  spleen==1 & inrange(age, 57, 59)
	replace covid_age = covid_age + 6   if  spleen==1 & inrange(age, 60, 62)
	replace covid_age = covid_age + 5   if  spleen==1 & inrange(age, 63, 66)
	replace covid_age = covid_age + 4   if  spleen==1 & inrange(age, 67, 68)
	replace covid_age = covid_age + 3   if  spleen==1 & inrange(age, 69, 70)
	replace covid_age = covid_age + 2   if  spleen==1 & inrange(age, 71, 72)
	replace covid_age = covid_age + 1   if  spleen==1 & inrange(age, 73, 74)
	replace covid_age = covid_age + 0   if  spleen==1 & inrange(age, 75, 110)

	* RA/SLE/Psoriasis
	replace covid_age = covid_age + 2   if  autoimmune==1 

	* Immunosuppressive condition
	replace covid_age = covid_age + 30  if  max(hiv, suppression==1) & inrange(age, 10, 21)
	replace covid_age = covid_age + 29  if  max(hiv, suppression==1) & inrange(age, 22, 23)
	replace covid_age = covid_age + 28  if  max(hiv, suppression==1) & inrange(age, 24, 25)
	replace covid_age = covid_age + 27  if  max(hiv, suppression==1) & inrange(age, 26, 27)
	replace covid_age = covid_age + 26  if  max(hiv, suppression==1) & inrange(age, 28, 29)
	replace covid_age = covid_age + 25  if  max(hiv, suppression==1) & inrange(age, 30, 31)
	replace covid_age = covid_age + 24  if  max(hiv, suppression==1) & inrange(age, 32, 33)
	replace covid_age = covid_age + 23  if  max(hiv, suppression==1) & inrange(age, 34, 35)
	replace covid_age = covid_age + 22  if  max(hiv, suppression==1) & inrange(age, 36, 37)
	replace covid_age = covid_age + 21  if  max(hiv, suppression==1) & inrange(age, 38, 39)
	replace covid_age = covid_age + 20  if  max(hiv, suppression==1) & inrange(age, 40, 41)
	replace covid_age = covid_age + 19  if  max(hiv, suppression==1) & inrange(age, 42, 43)
	replace covid_age = covid_age + 18  if  max(hiv, suppression==1) & inrange(age, 44, 44)  
	replace covid_age = covid_age + 17  if  max(hiv, suppression==1) & inrange(age, 45, 46)
	replace covid_age = covid_age + 16  if  max(hiv, suppression==1) & inrange(age, 47, 48)
	replace covid_age = covid_age + 15  if  max(hiv, suppression==1) & inrange(age, 49, 51)
	replace covid_age = covid_age + 14  if  max(hiv, suppression==1) & inrange(age, 52, 53)
	replace covid_age = covid_age + 13  if  max(hiv, suppression==1) & inrange(age, 54, 56)
	replace covid_age = covid_age + 12  if  max(hiv, suppression==1) & inrange(age, 57, 58)
	replace covid_age = covid_age + 11  if  max(hiv, suppression==1) & inrange(age, 59, 61)
	replace covid_age = covid_age + 10  if  max(hiv, suppression==1) & inrange(age, 62, 63)
	replace covid_age = covid_age + 9  if  max(hiv, suppression==1) & inrange(age, 64, 66)
	replace covid_age = covid_age + 8  if  max(hiv, suppression==1) & inrange(age, 67, 68)
	replace covid_age = covid_age + 7  if  max(hiv, suppression==1) & inrange(age, 69, 71)
	replace covid_age = covid_age + 6  if  max(hiv, suppression==1) & inrange(age, 72, 73)
	replace covid_age = covid_age + 5  if  max(hiv, suppression==1) & inrange(age, 74, 110)

	
end
	