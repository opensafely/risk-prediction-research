/****************************/
/* Calibration Belt Program */
/****************************/

/********************/
/* Giovanni Nattino */
/*   Version 1.4    */
/********************/

capture program drop calibrationbelt
program calibrationbelt 
	version 13
	
	syntax [varlist] [if] [, devel(string) thres(real .95) /*
	                           */ maxDeg(real 4) cLevel1(real -999) /*
							   */ cLevel2(real -999) nPoints(real 100) *]
	
	capt mata mata which mm_integrate_38()
	if _rc {
		di as error "The function mm_integrate_38() from the package -moremata- is required; type -ssc install moremata- to install the package."
		exit 499
	}

	capt mata mata which mm_root()
	if _rc {
		di as error "The function mm_root() from the package -moremata- is required; type -ssc install moremata- to install the package."
		exit 499
	}
	
	_get_gropts , graphopts(`options') gettwoway getallowed(plot)
	local twowayopts `s(twowayopts)'
	
	quietly{
		capt mata: function logistic(x) return(1:/(1:+exp(-x)))
		mata: currentArgsCalibBelt = checkArgsCalibrationBelt("`varlist'", "`devel'", `thres', /*
														   */ `maxDeg', `cLevel1', `cLevel2', /*
														   */ `nPoints', "`if'", "`twowayopts'")
		mata: calibrationBelt(currentArgsCalibBelt)
		
	}
	
	/*Printout output*/
	di as text _dup(59) "-"
	di %~59s "{ul:GiViTI Calibration Belt}"
	di ""
	
	if ("`devel'" == "internal" | "`devel'" == "") {
		di "Calibration belt and test for internal validation:"
		di "the calibration is evaluated on the training sample."
	} 
	
	if "`devel'" == "external" {
		di "Calibration belt and test for external validation:"
		di "the calibration is evaluated on an external, independent sample."
	}
	
	if "`if'"!="" {
		di ""
		di "Selection:" subinstr("`if'","if","",1)
	}
	
	di ""
	di "Sample size: " r(sampleSize)
	di "Polynomial degree: " r(m)
	di "Test statistic: " %5.2f r(calibrationStat)
	di "p-value: " %5.4f r(calibrationP)
	di as text _dup(59) "-"
	
end

mata:

function checkArgsCalibrationBelt(stringVarlist, devel, thres, 
									maxDeg, cLevel1, cLevel2, 
									nPoints, ifString, twowayopts) {
	
	vectorVarlist = tokens(stringVarlist)		
	
	/* If no variable is passed to the function: 
			calibration belt on last fitted logistic regression model*/
	
	if(length(vectorVarlist) == st_nvar()) {	
		
		/*when cb on previously fitted model, use the same sample of logit/logistic*/
		nameObsUsedFit = st_tempname()
		stata("gen " + nameObsUsedFit + " = e(sample)")

		if (ifString == "") {
		
			devel = "internal"
			
			/*If no if is specified, subset on sample of logit/logistic (with string "if" in front)*/
			ifString = ("if " + nameObsUsedFit + "==1")
			
		} else {
			
			/*If if is specified, subset on sample of logit/logistic (no "if" in front)*/
			ifString = (ifString + " & " + nameObsUsedFit + "==1")
			
			/*if calibration belt on last fitted model but "if" statement is 
			present, force the user to specify "devel" (internal/external)*/
			if( rowsum(devel :== ("internal", "external")) !=1 ) {
				_error(("The argument -devel- must be set: -devel(" + char(34) + "internal" + char(34) + ")- or -devel(" + char(34) + "external" + char(34) + ")-" ))
			};
						
		}

		nameE = ""
		nameLogite = st_tempname()
		nameO = st_global("e(depvar)")
		
		infoFromLogisticRegressionFit = 1
			
		/*else: calibration belt on variables reported*/
	}  else {
	
		if(length(vectorVarlist) != 2) {
			_error(("Two variables must be passed to -calibrationbelt-: the binary response and the predictions"))
		};
		
		if( rowsum(devel :== ("internal", "external")) !=1 ) {
			_error(("The argument -devel- must be set: -devel(" + char(34) + "internal" + char(34) + ")- or -devel(" + char(34) + "external" + char(34) + ")-" ))
		};
		
		nameE = vectorVarlist[2]
		nameLogite = st_tempname()
		nameO = vectorVarlist[1]
		
		infoFromLogisticRegressionFit = 0
	}
	
	if(thres <=0  | thres >= 1 ) {
			_error((" The argument -thres- must be a numeric value in the interval (0,1) "))
	};
	
	if(maxDeg < 1  | maxDeg > 4 ) {
			_error((" The argument -maxDeg- must be an integer value between 1 and 4 "))
	};
	
	/* Confidence levels controls  */
	/* --------------------------- */
	
	/* If not provided neither cLevel1 and cLevel2 => default */
	if(cLevel1==-999 & cLevel2==-999) {
		cLevel1 = .95 
		cLevel2 = .80
	}
	
	/* If only cLevel2 provided: ERROR */
	if(cLevel1==-999 & cLevel2!=-999) {
		_error((" The argument -cLevel2- is provided without specifying the argument -cLevel1- "))
	}
	
	/* If only cLevel1 provided: single CB */
	if(cLevel1!=-999 & cLevel2==-999) {
		cLevel2 = cLevel1 
	}
	
	if(cLevel1 <=0  | cLevel1 >= 1 | cLevel2 <=0  | cLevel2 >= 1) {
			_error((" The arguments -cLevel1- and -cLevel2- must be numeric values in the interval (0,1) "))
	};
	
	cLevel = (cLevel1, cLevel2)
	cLevel = uniqrows(cLevel')'
	
	currentArgsCalibBelt = argsCalibBelt(nameO, nameE, nameLogite, infoFromLogisticRegressionFit, 
										devel, thres, maxDeg, cLevel, nPoints, ifString, twowayopts)

	return(currentArgsCalibBelt)
}

struct argsCalibBeltStruct {
	string scalar nameO
	string scalar nameE
	string scalar nameLogite
	real scalar infoFromLogisticRegressionFit
	string scalar devel
	real scalar thres
	real scalar maxDeg
	real vector cLevel
	real scalar nPoints
	string scalar ifString
	string scalar twowayopts
}

struct argsCalibBeltStruct scalar argsCalibBelt(nameO, nameE, nameLogite, infoFromLogisticRegressionFit, 
													devel, thres, maxDeg, cLevel ,nPoints, ifString, twowayopts) {
	
	struct argsCalibBeltStruct scalar argsCalibBeltTemp
	
	argsCalibBeltTemp.nameO = nameO
	argsCalibBeltTemp.nameE = nameE
	argsCalibBeltTemp.nameLogite = nameLogite
	argsCalibBeltTemp.infoFromLogisticRegressionFit = infoFromLogisticRegressionFit
	argsCalibBeltTemp.devel = devel
	argsCalibBeltTemp.thres = thres
	argsCalibBeltTemp.maxDeg = maxDeg
	argsCalibBeltTemp.cLevel = cLevel
	argsCalibBeltTemp.nPoints = nPoints
	argsCalibBeltTemp.ifString = ifString
	argsCalibBeltTemp.twowayopts = twowayopts
	
	return(argsCalibBeltTemp)
}

struct parFnStruct {
	real scalar g
	real scalar m
	real matrix G
	real vector o
	real scalar thresholdLogLik
}

struct parFnStruct scalar parFn(g, m , G, o , thresholdLogLik) {
	
	struct parFnStruct scalar parFnTemp
	
	parFnTemp.g = g
	parFnTemp.m = m
	parFnTemp.G = G
	parFnTemp.o = o
	parFnTemp.thresholdLogLik = thresholdLogLik

	return(parFnTemp)
}

struct parLogLikelihoodStruct {
	real vector beta 
	real vector direction
	real matrix G							
	real vector o
	real scalar thresholdLogLik
}

struct parLogLikelihoodStruct scalar parLogLikelihood(beta, direction, G, o, thresholdLogLik) {
	
	struct parLogLikelihoodStruct scalar parLogLikelihoodTemp
	
	parLogLikelihoodTemp.beta = beta
	parLogLikelihoodTemp.direction = direction
	parLogLikelihoodTemp.G = G
	parLogLikelihoodTemp.o = o
	parLogLikelihoodTemp.thresholdLogLik = thresholdLogLik

	return(parLogLikelihoodTemp)
}

numeric scalar function logLikelihood(rho,   
									  struct parLogLikelihoodStruct scalar parLogLikelihoodTemp) {
	beta = parLogLikelihoodTemp.beta
	direction = parLogLikelihoodTemp.direction 
	G = parLogLikelihoodTemp.G
	o = parLogLikelihoodTemp.o 
	thresholdLogLik = parLogLikelihoodTemp.thresholdLogLik

	probBeta = logistic(G * (beta + direction :* rho))
	y = colsum((1 :- o) :* log(1 :- probBeta) + o :* log(probBeta)) - thresholdLogLik
	return(y)
}

numeric vector function jacLogLikelihood(beta, G, o) {
	
	probBeta = logistic(G * beta)
	
	return(G' * (o :- probBeta))
}

numeric vector function Fn(real vector x, real vector y, 
							struct parFnStruct scalar parFnTemp) {

	g = parFnTemp.g
	m = parFnTemp.m
	G = parFnTemp.G
	o = parFnTemp.o
	thresholdLogLik = parFnTemp.thresholdLogLik  


	vecG = g:^((0..m)')
	vecG = vecG :/ sqrt(vecG' * vecG) 

	probBeta = logistic(G * x[1..(rows(x)-1)])

	F1 =  ((o - probBeta)'* G)' - x[rows(x)] * vecG
	F2 =  colsum((1 :- o) :* log(1 :- probBeta) + o :* log(probBeta)) - thresholdLogLik

	y=F1\F2
	return(y)
}


numeric matrix function JacobFn(x, g, m , G, o){

	vecG = g:^((0..m)')
	vecG = vecG :/ sqrt(vecG' * vecG) 

	probBeta = logistic(G * x[1..(rows(x)-1)])

	piOneMinusPiBeta = probBeta :* (1 :- probBeta)
	matrixProbBeta = piOneMinusPiBeta
	for (i=1; i <= m; i++) {
		matrixProbBeta  = matrixProbBeta , piOneMinusPiBeta	
	}

	H = (G:*matrixProbBeta)' * G

	J_F1 = H, vecG
	J_F2 = (o :- probBeta)' * G , 0

	return((J_F1\J_F2))
}

struct outputCBTableStruct {
	string scalar stringTable
	string matrix nameLines
}

struct outputCBTableStruct scalar outputCBTable(stringTable, nameLines) {
	
	struct outputCBTableStruct scalar outputCBTableTemp
	
	outputCBTableTemp.nameLines = nameLines
	outputCBTableTemp.stringTable = stringTable

	return(outputCBTableTemp)
}

void function plotCalibrationBelt(cbBoundMultipleCLevels, x, 
								  cbIntersectionsMultipleCLevels,
								  m, calibrationStat, calibrationP, 
								  sampleSize, cLevel, devel, | string scalar twowayopts,
								  string scalar polynomialString, 
								  string scalar testStatString,
								  string scalar pvalueString, 
								  string scalar nString,
								  string scalar confLevelString,
  								  string scalar underBisString, 
								  string scalar overBisString,
								  string scalar neverString,
								  string scalar opts) {

/*	
For bug fixing: 
	
	x = logistic(seqG)
	polynomialString = "Polynomial degree"
	testStatString = "Test statistic"
	pvalueString = "p-value"
	nString = "n"
	confLevelString= ""
	underBisString= ""
	overBisString= ""
	neverString= ""
	opts = ""
*/

								  
	xlim = (0,1)
	ylim = (0,1)
	
	n = rows(cbBoundMultipleCLevels)
	if (rows(x)!=n) _error(3200);
	N = st_nobs()
	if (N<n) st_addobs(n-N);
	
	nameVectorX =  st_tempname()
	st_store((1,n), st_addvar("double", nameVectorX), x)
	
	nClevel = (cols(cbBoundMultipleCLevels)/2)
	
	nameVars = J(1,cols(cbBoundMultipleCLevels),"")
	
	for(i=1; i <= nClevel; i++) {
		/*nameVars = ("lowerBound", "upperBound") :+ strofreal(i) :+ "calibrationBelt"*/
		nameVars[(2*i-1)] = st_tempname()
		nameVars[2*i] = st_tempname()
		st_store((1,n), st_addvar("double", nameVars[(2*i-1)]), cbBoundMultipleCLevels[,2*i-1])
		st_store((1,n), st_addvar("double", nameVars[2*i]), cbBoundMultipleCLevels[,2*i])
		
	}
	
	nameVersUpper = nameVars[range(2,length(nameVars),2)]
	nameVersLower = nameVars[range(1,length(nameVars)-1,2)]
	nameVariablesVector = (nameVersUpper[nClevel..1],nameVersLower)
	/*nameVariablesVector = ("upperBound" :+ strofreal(nClevel..1) :+ "calibrationBelt" ,
							"lowerBound" :+ strofreal(1..nClevel) :+ "calibrationBelt")*/
	
	stringBounds = invtokens(nameVariablesVector)
	
	grayScale = rangen(1, 16, nClevel + 2) 
	
	if (nClevel == 1) {
	
		grayScale = round(grayScale[2])
		
	} else {
	
		grayScale = round((grayScale[2..(nClevel +1)] \ grayScale[nClevel..2]))
		
	}
	
	grayScaleVectorString = "gs" :+ strofreal(grayScale)
	grayScaleString = invtokens(grayScaleVectorString')

	/* Writing on the plot area*/
	
	testStatChar = strofreal(calibrationStat, "%9.2f") 
	
	if (calibrationP < .001) {

	  pvalueChar = "<0.001"

	} else {

	  pvalueChar = strofreal(calibrationP, "%9.3f") 

	}

	fromTop = 0

	typeOfCalibrationString = "Type of evaluation: " + devel 
	
	if(polynomialString == "") {
		
		polynomialString = "Polynomial degree" 
		
	};
	
	if(testStatString == "") {
		
		testStatString = "Test statistic"
		
	};
	
	if(pvalueString == "") {
		
		pvalueString = "p-value"
		
	};
	
	if(nString == "") {
		
		nString = "n"
		
	};
	
	fromTop = fromTop + 0.05 * (ylim[2] - ylim[1])
	  
	textOnPlotTypeCalibration = (" text( " + strofreal(ylim[2] - fromTop) + " " + strofreal(xlim[1]) + 
								" " + char(34) + typeOfCalibrationString + char(34) + 
								", place(e) just(left)) ")
								
	fromTop = fromTop + 0.05 * (ylim[2] - ylim[1])
	  
	textOnPlotPolynomial = (" text( " + strofreal(ylim[2] - fromTop) + " " + strofreal(xlim[1]) + 
								" " + char(34) + polynomialString + ": " + strofreal(m) + char(34) + 
								", place(e) just(left)) ")
	
	fromTop = fromTop + 0.05 * (ylim[2] - ylim[1])
	
	textOnPlotTestStat = (" text( " + strofreal(ylim[2] - fromTop) + " " + strofreal(xlim[1]) + 
								" " + char(34) + testStatString + ": " + testStatChar + char(34) + 
								", place(e) just(left)) ")
	
	fromTop = fromTop + 0.05 * (ylim[2] - ylim[1])
	
	textOnPlotPvalue = (" text( " + strofreal(ylim[2] - fromTop) + " " + strofreal(xlim[1]) + 
								" " + char(34) + pvalueString + ": " + pvalueChar + char(34) + 
								", place(e) just(left)) ")
	
	fromTop = fromTop + 0.05 * (ylim[2] - ylim[1])
	  
	textOnPlotN = (" text( " + strofreal(ylim[2] - fromTop) + " " + strofreal(xlim[1]) + 
								" " + char(34) + nString + ": " + strofreal(sampleSize) + char(34) +
								", place(e) just(left)) ")

	struct outputCBTableStruct scalar resultCBTable
	grayVector = "gs" :+ strofreal(uniqrows(grayScale)[nClevel..1])
	resultCBTable = calibrationBeltTable(cbIntersectionsMultipleCLevels, xlim, ylim, cLevel, grayVector, 
										 confLevelString, underBisString, overBisString, neverString)
	
	stringTable = resultCBTable.stringTable
	nameLines = resultCBTable.nameLines
	
	stringTitleAxes = (" xtitle(" + char(34) + "Expected" + char(34) + 
					  ") ytitle(" + char(34) + "Observed" + char(34) + ") ")
	
	stringLinesTable = invtokens((" || line " :+  nameLines[,2] :+ " " 
								 :+ nameLines[,1] :+ ", lcolor(black) lpattern(solid) " )')
								 
	/*Lines to cover gray border */
	nameVectorCoverVertX =  st_tempname()
	nameVectorCoverVertY =  st_tempname()
	st_store((1,2), st_addvar("double", nameVectorCoverVertX), (max(x) \ max(x)))
	st_store((1,2), st_addvar("double", nameVectorCoverVertY), (0 \ 1))
	stringCoverVert = (" || line " + nameVectorCoverVertY + " " + 
						nameVectorCoverVertX + ", lcolor(white) lpattern(solid) " )

	nameVectorCoverHorizX =  st_tempname()
	nameVectorCoverHorizY =  st_tempname()
	st_store((1,2), st_addvar("double", nameVectorCoverHorizX), (0 \ 1))
	st_store((1,2), st_addvar("double", nameVectorCoverHorizY), (0 \ 0))
	stringCoverHoriz = (" || line " + nameVectorCoverHorizY + " " + 
						nameVectorCoverHorizX + ", lcolor(white) lpattern(solid) " )
						
								 
	stata("twoway area " + stringBounds +
		   " " + nameVectorX + ", ylabel(, angle(horizontal) nogrid) " + 
		   stringTitleAxes + " lwidth(none none none none none) color(" + grayScaleString + " white) legend(off) " + twowayopts + 
		   textOnPlotTypeCalibration + textOnPlotPolynomial + textOnPlotTestStat + textOnPlotPvalue + textOnPlotN + 
		   opts + stringCoverVert + stringCoverHoriz + stringTable  +
		   " || function y = x, lstyle(p2) "  + stringLinesTable ) 
		   /*ORIGINALLY: the bisector was setup with specified 
		                 color and pattern with "lcolor(red) lpattern(solid)" 
		     NOW: lstyle(p2) */
		   
	if (N<n) st_dropobsin((N+1,n))
	/*st_dropvar((nameVariablesVector, nameVectorX, vec(nameLines)'))*/
}

function editStringCalibrationBeltTable(stringToEdit) {
	
	vectorWords = tokens(stringToEdit)
	
	nWords = length(vectorWords)
	
	if(nWords>=2) {
	
		stringOutput = (char(34) + vectorWords[1] + char(34) + " " + 
						char(34) + invtokens(vectorWords[2..nWords]) + char(34))
		
	} else {
		stringOutput = (char(34) + stringToEdit + char(34) )
	}
	
	return(stringOutput)
}


function calibrationBeltTable(cbIntersectionsMultipleCLevels, xlim, ylim, cLevel, grayVector,
								string scalar confLevelString,
								string scalar underBisString, 
								string scalar overBisString,
								string scalar neverString){

	if(confLevelString == "") {
	  confLevelString = "Confidence level"
	}

	if(underBisString == "") {
	  underBisString = "Under the bisector"
	}
	
	if(overBisString == "") {
	  overBisString = "Over the bisector"
	}
	
	if(neverString == "") {
	   neverString = "NEVER"
	}

	confLevelString = editStringCalibrationBeltTable(confLevelString)
	overBisString = editStringCalibrationBeltTable(overBisString)
	underBisString = editStringCalibrationBeltTable(underBisString)

	fromBottom = ylim[1]

	/*Auxiliary variables for plotting lines*/ 
	nameBottomLineX = st_tempname()
	nameBottomLineY = st_tempname()
	
	st_store((1,2), st_addvar("double", nameBottomLineX), 
					(xlim[1] + 0.4 * (xlim[2] - xlim[1]), xlim[2])')
	st_store((1,2), st_addvar("double", nameBottomLineY), 
					(fromBottom - 0.025 * (ylim[2] - ylim[1]), fromBottom - 0.025 * (ylim[2] - ylim[1]))')
	
	nameLines = (nameBottomLineX, nameBottomLineY)
	stringTable = ""
	
	for(i = rows(cbIntersectionsMultipleCLevels); i >= 1; i--) {

	  intersIUnderString = cbIntersectionsMultipleCLevels[i,1]
	  intersIOverString = cbIntersectionsMultipleCLevels[i,2]
	  
	  intersIUnderVector = tokens(intersIUnderString, "#")
	  intersIOverVector = tokens(intersIOverString, "#")
	  
	  intersIUnderVector = select(intersIUnderVector,intersIUnderVector :!= "#")
	  intersIOverVector = select(intersIOverVector,intersIOverVector :!= "#")
	  
	  maxIntervalsI = max((length(intersIUnderVector),
						   length(intersIOverVector),
						   1))

	  heightRow = 0.05 * ( maxIntervalsI - 1 ) * (ylim[2] - ylim[1])

	  yConfLevel = (fromBottom + heightRow / 2 )

	  stringTable = stringTable + (" text( " + strofreal(yConfLevel) + " " + strofreal(xlim[1] + 0.5 * (xlim[2] - xlim[1])) + 
								" " + char(34) + strofreal(cLevel[i]*100) + "%" + char(34) + " )" + 
								" || scatteri " + strofreal(yConfLevel) + " " + strofreal(xlim[1] + 0.425 * (xlim[2] - xlim[1])) + ", msymbol(square) mcolor(" + grayVector[i] + ")")  
	  	
	  /*	
	  polygon(c(xlim[1] + 0.45 * (xlim[2] - xlim[1]),
				xlim[1] + 0.42 * (xlim[2] - xlim[1]),
				xlim[1] + 0.42 * (xlim[2] - xlim[1]),
				xlim[1] + 0.45 * (xlim[2] - xlim[1])),
			  c(yConfLevel - 0.015 * (ylim[2] - ylim[1]),
				yConfLevel - 0.015 * (ylim[2] - ylim[1]),
				yConfLevel + 0.015 * (ylim[2] - ylim[1]),
				yConfLevel + 0.015 * (ylim[2] - ylim[1])),
			  border = gray(grayLevels[i]), col = gray(grayLevels[i]))*/

	  if(length(intersIOverVector) >= 1) {

		if(length(intersIOverVector) == maxIntervalsI) {

		  for(iIntOver=1; iIntOver <= length(intersIOverVector); iIntOver++) {
			
			stringTable = stringTable + (" text( " + strofreal(fromBottom + heightRow - (iIntOver - 1) * 0.05 * (ylim[2] - ylim[1])) + " " + 
							strofreal(xlim[1] + 0.9 * (xlim[2] - xlim[1])) + 
								" " + char(34) + intersIOverVector[iIntOver] + char(34) + " )")
		  }

		} else {

		  spaceBetweenRows = heightRow / (length(intersIOverVector) + 1)

		  for(iIntOver=1; iIntOver <= length(intersIOverVector); iIntOver++) {

			stringTable = stringTable + (" text( " + strofreal(fromBottom + heightRow - iIntOver * spaceBetweenRows) + " " + 
							strofreal(xlim[1] + 0.9 * (xlim[2] - xlim[1])) + 
								" " + char(34) + intersIOverVector[iIntOver] + char(34) + " )")

		  }


		}


	  } else {

			stringTable = stringTable + (" text( " + strofreal(yConfLevel) + " " + 
							strofreal(xlim[1] + 0.9 * (xlim[2] - xlim[1])) + 
								" " + char(34) + neverString + char(34) + " )")

	  }

	  if(length(intersIUnderVector) >= 1) {

		if(length(intersIUnderVector) == maxIntervalsI) {

		  for(iIntUnder=1; iIntUnder <= length(intersIUnderVector); iIntUnder++) {

			stringTable = stringTable + (" text( " + strofreal(fromBottom + heightRow - (iIntUnder - 1) * 0.05 * (ylim[2] - ylim[1])) + " " + 
							strofreal(xlim[1] + 0.7 * (xlim[2] - xlim[1])) + 
								" " + char(34) + intersIUnderVector[iIntUnder] + char(34) + " )")
								
		  }

		} else {

		  spaceBetweenRows = heightRow / (length(intersIUnderVector) + 1)

		  for(iIntUnder=1; iIntUnder <= length(intersIUnderVector); iIntUnder++) {
			
			stringTable = stringTable + (" text( " + strofreal(fromBottom + heightRow - iIntUnder * spaceBetweenRows) + " " + 
							strofreal(xlim[1] + 0.7 * (xlim[2] - xlim[1])) + 
								" " + char(34) + intersIUnderVector[iIntUnder] + char(34) + " )")
								
		  }
		}

	  } else {

			stringTable = stringTable + (" text( " + strofreal(yConfLevel) + " " + 
							strofreal(xlim[1] + 0.7 * (xlim[2] - xlim[1])) + 
								" " + char(34) + neverString + char(34) + " )")

	  }

	fromBottom = fromBottom + heightRow + 0.05 * (ylim[2] - ylim[1])

	nameNewLineX = st_tempname()
	nameNewLineY = st_tempname()
	
	st_store((1,2), st_addvar("double", nameNewLineX), 
					(xlim[1] + 0.4 * (xlim[2] - xlim[1]), xlim[2])')
	st_store((1,2), st_addvar("double", nameNewLineY), 
					(fromBottom - 0.025 * (ylim[2] - ylim[1]), fromBottom - 0.025 * (ylim[2] - ylim[1]))')
	
	nameLines = nameLines \ (nameNewLineX, nameNewLineY)
	
	}

	stringTable = stringTable + (" text( " + strofreal(fromBottom + 0.02 * (ylim[2] - ylim[1])) + " " + 
							strofreal(xlim[1] + 0.5 * (xlim[2] - xlim[1])) + 
								" " +  confLevelString +  " )")
	
	stringTable = stringTable + (" text( " + strofreal(fromBottom + 0.02 * (ylim[2] - ylim[1])) + " " + 
							strofreal(xlim[1] + 0.7 * (xlim[2] - xlim[1])) + 
								" " +  underBisString +  " )")
								
	stringTable = stringTable + (" text( " + strofreal(fromBottom + 0.02 * (ylim[2] - ylim[1])) + " " + 
							strofreal(xlim[1] + 0.9 * (xlim[2] - xlim[1])) + 
								" " +  overBisString +  " )")
								
	return(outputCBTable(stringTable, nameLines))
}


function borderInterval(bound, intersection, seqP) {
	indexSelection = selectindex(intersection:>0)
	return( ( bound[indexSelection :+ 1] :* seqP[indexSelection] :- 
			  seqP[indexSelection :+ 1] :* bound[indexSelection]) :/ 
			  ((seqP[indexSelection] :- seqP[indexSelection :+ 1]) :-
			    (bound[indexSelection] :- bound[indexSelection :+ 1])))
}  

function calibrationBeltIntersections(lowerBound, upperBound, seqP, minMax) {
	
	nPoints = rows(lowerBound)
	
	intersectionsOverBisector = ""
	intersectionsUnderBisector = ""
	
	if( colsum(lowerBound :> seqP) == nPoints) {
			intersectionsOverBisector = ( strofreal(minMax[1], "%9.2f") + 
										 " - " + strofreal(minMax[2], "%9.2f"))
	}
	
	if( colsum(upperBound :< seqP) == nPoints) {
			intersectionsUnderBisector = ( strofreal(minMax[1], "%9.2f") + 
										 " - " + strofreal(minMax[2], "%9.2f"))
	}
	
	if( colsum(lowerBound :> seqP) != nPoints & colsum(upperBound :< seqP) != nPoints) {
	
		from2toEnd = 2..nPoints
		from1toEndMin1 = 1..(nPoints-1)
		
		intersectionLowBoundInc = (lowerBound[from2toEnd] :> seqP[from2toEnd] :&
								   lowerBound[from1toEndMin1] :< seqP[from1toEndMin1])	
		
		intersectionLowBoundDec = (lowerBound[from2toEnd] :< seqP[from2toEnd] :&
								   lowerBound[from1toEndMin1] :> seqP[from1toEndMin1])
		
		intersectionUppBoundInc = (upperBound[from2toEnd] :> seqP[from2toEnd] :&
								   upperBound[from1toEndMin1] :< seqP[from1toEndMin1])
								   
		intersectionUppBoundDec = (upperBound[from2toEnd] :< seqP[from2toEnd] :&
								   upperBound[from1toEndMin1] :> seqP[from1toEndMin1])
								   
		startLowerBoundOver = borderInterval(lowerBound, intersectionLowBoundInc, seqP)	
		startLowerBoundUnder = borderInterval(lowerBound, intersectionLowBoundDec, seqP)	
		startUpperBoundOver = borderInterval(upperBound, intersectionUppBoundInc, seqP)	
		startUpperBoundUnder = borderInterval(upperBound, intersectionUppBoundDec, seqP)	
		
		if(rows(startLowerBoundOver)==0 & rows(startLowerBoundUnder)!=0) {
			intersectionsOverBisector = ( strofreal(minMax[1], "%9.2f") + 
										 " - " + strofreal(startLowerBoundUnder[1], "%9.2f"))						 
		}
		
		if(rows(startLowerBoundOver)!=0 & rows(startLowerBoundUnder)==0) {
			intersectionsOverBisector = ( strofreal(startLowerBoundOver[1], "%9.2f") + 
										 " - " + strofreal(minMax[2], "%9.2f"))						 
		}
		
		if(rows(startLowerBoundOver)!=0 & rows(startLowerBoundUnder)!=0) {
			
			if(startLowerBoundOver[1] > startLowerBoundUnder[1]){
			
				startLowerBoundOver = minMax[1] \ startLowerBoundOver
			
			}
			
			if(rows(startLowerBoundOver)!=rows(startLowerBoundUnder)){
			
				startLowerBoundUnder = startLowerBoundUnder \ minMax[2]
			
			}
			
			for(i = 1; i<=rows(startLowerBoundUnder); i++) {
				intersectionsOverBisector = (intersectionsOverBisector + " " +
											 (i>1)*"# " + 
										strofreal(startLowerBoundOver[i],"%9.2f") + " - " + 
										strofreal(startLowerBoundUnder[i],"%9.2f"))
			}
									 
		}
		
		if(rows(startUpperBoundOver)==0 & rows(startUpperBoundUnder)!=0) {
			intersectionsUnderBisector = ( strofreal(startUpperBoundUnder[1], "%9.2f") + 
										 " - " + strofreal(minMax[2], "%9.2f"))						 
		}
		
		if(rows(startUpperBoundOver)!=0 & rows(startUpperBoundUnder)==0) {
			intersectionsUnderBisector = ( strofreal(minMax[1], "%9.2f") + 
										 " - " + strofreal(startUpperBoundOver[1], "%9.2f"))						 
		}
		
		if(rows(startUpperBoundOver)!=0 & rows(startUpperBoundUnder)!=0) {
			
			if(startUpperBoundUnder[1] > startUpperBoundOver[1]){
			
				startUpperBoundUnder = minMax[1] \ startUpperBoundUnder
			
			}
			
			if(rows(startUpperBoundOver)!=rows(startUpperBoundUnder)){
			
				startUpperBoundOver = startUpperBoundOver \ minMax[2]
			
			}
			
			
			for(i = 1; i<=rows(startUpperBoundUnder); i++) {
				intersectionsUnderBisector = (intersectionsUnderBisector + " " +
											 (i>1)*"# " + 
										strofreal(startUpperBoundUnder[i],"%9.2f") + " - " + 
										strofreal(startUpperBoundOver[i],"%9.2f"))
			}
									 
		}
		
	}
	return(intersectionsUnderBisector, intersectionsOverBisector)
}

function polynomialLogRegrFw(nameO, thres, maxDeg, startDeg, nameLogite) {

	if(startDeg == 1) {

		stringLogRegrStart = "logit " + nameO + " " + nameLogite

		} else {

			stringLogRegrStart = ("logit " + nameO + " " + 
								  (startDeg-1) * ("c." + nameLogite + "##" ) + 
								  "c." + nameLogite)
  
	}
	
	stata(stringLogRegrStart)
	devianceOld = (-2*st_numscalar("e(ll)"))
	
	if (maxDeg > startDeg) {
	
		for (i = (startDeg+1); i <= maxDeg; i++){

			stringLogRegr = "logit " + nameO + " " + (i-1) * ("c." + nameLogite + "##" ) + "c." + nameLogite
	 
			stata(stringLogRegr)
			devianceNew = (-2*st_numscalar("e(ll)"))
		
			if(chi2(1, devianceOld - devianceNew) < thres) {
				m = i-1
				break
			}
		
			m = i
			devianceOld = devianceNew
			
		}
		
	} else {
	
		m = startDeg
		
	}

	stringLogRegrSelected = ("logit " + nameO + " " + 
							 (m-1) * ("c." + nameLogite + "##" ) + 
							 "c." + nameLogite)
	stata(stringLogRegrSelected)
	
	return(m = m)

}

function integrand_m3_external_1(y, t, pDegInc) {
	return( (chi2(1, t - y) - 1 + pDegInc) * chi2den(1, y) )
}

function integrand_m3_external_2(y, t, k) {
	return( (sqrt(t - y) - sqrt(k)) * 1 / sqrt(y) )
}

function integrand_m4_external(r, t, k) {
	return(r^2 * (exp(-(r^2) / 2) - exp(-t/2)) *
                 (- pi() * sqrt(k) / (2 * r) + 2 * sqrt(k) / r *
                  asin((r^2 / k - 1)^(-1/2)) - 2 * atan(( 1 - 2 * k / r^2)^(-1/2)) +
                  2 * sqrt(k) / r * atan((r^2 / k - 2)^(-1/2)) +
                  2 * atan(r / sqrt(k) * sqrt(r^2 / k - 2))
                  - 2 * sqrt(k) / r * atan(sqrt(r^2/ k - 2))))
}

function integrand_m3_internal(r, k) {
	return(r * exp(- (r^2) / 2) * acos(sqrt(k) / r))
}

function integrand_m4_internal(r, k) {
	return(r^2 * exp(-(r^2) / 2) * (atan(sqrt(r^2 / k * (r^2 / k - 2)))-
                               sqrt(k) / r * atan(sqrt(r^2 / k - 2)) -
                               sqrt(k) / r * acos((r^2 / k - 1)^(-1/2))))
}

function givitiStatCdf(t, m, devel, thres) {

  if (rows(t) > 1 | rows(m) > 1 | rows(devel) > 1 | rows(thres) > 1) {
    _error("CDF evaluation: the arguments 't', 'm' and 'devel' cannot be vectors.")
  }

  if (sum(("internal","external") :== devel) == 0) {
    _error("CDF evaluation: the 'devel' argument must be either 'internal' or external'")
  }

  if (sum((1, 2, 3, 4) :== m) == 0) {
    _error("CDF evaluation: m must be an integer from 1 to 4")
  }

  if (thres < 0 | thres > 1) {
    _error("CDF evaluation: the argument 'thres' must be a number in [0,1]")
  }

  if (devel == "internal" & m == 1) {
    _error("CDF evaluation: if devel='internal', m must be an integer from 2 to 4")
  }

  pDegInc = 1 - thres
  k = invchi2(1, 1 - pDegInc)

  if(devel == "external") {

    if(t < (m-1)*k) {

      cdfValue = 0

    }  else {

      if(m == 1){
        cdfValue = chi2(2, t)
      } ;

      if(m == 2){
        cdfValue = ((chi2(1, t) - 1 + pDegInc +
                (-1) * sqrt(2) / sqrt(pi()) * exp(-t / 2) * ( sqrt(t) - sqrt(k))) / pDegInc)
      };

      if(m==3){
		
		integral1 = mm_integrate_38(&integrand_m3_external_1(), k, t - k, 5*999, 1, t, pDegInc)
		integral2 = mm_integrate_38(&integrand_m3_external_2(), k, t - k, 5*999, 1, t, k)

        num = (integral1 - exp(-t/2) / (2*pi()) * 2 * integral2)
        den = pDegInc^2

        cdfValue = (num / den)
      };

      if(m==4){
		
        integral = mm_integrate_38(&integrand_m4_external(), sqrt(3 * k), sqrt(t), 5*999, 1, t, k)

        cdfValue = ((2 / (pi() * pDegInc^2))^(3 / 2) * integral)
      };
    }
  };

  if(devel == "internal") {

    if(t <= (m-2)*k) {

     cdfValue = (0)

    } else {

      if(m == 2){

        cdfValue = (chi2(1, t))

      }

      if(m == 3){
		
		
		integral = mm_integrate_38(&integrand_m3_internal(), sqrt(k), sqrt(t), 5*999, 1, k)
		
        cdfValue = (2 / (pi() * pDegInc) * integral)
      }

      if(m==4){

		
		integral = mm_integrate_38(&integrand_m4_internal(), sqrt(2*k), sqrt(t), 5*999, 1, k)
		
        cdfValue = ((2 / pi())^(3 / 2) * (pDegInc)^(-2) * integral)
      }
    }
  };

  if(cdfValue < (-0.0001) | cdfValue > (1.0001)) {
    _error("CDF evaluation: cdfValue outside [0,1]. ")
  };

  if(cdfValue > (-0.0001) & cdfValue < 0) {
    output = 0
  };
  if(cdfValue < (1.0001) & cdfValue > 1) {
    output = 1
  };
  if(cdfValue <= 1 & cdfValue >= 0) {
    output = cdfValue
  };
  return(output)
}

struct parqCalibDistrStruct {
	real scalar m
	string scalar devel
	real scalar thres
	real scalar cLevel
}

struct parqCalibDistrStruct scalar parqCalibDistr(m, devel, thres, cLevel) {
	
	struct parqCalibDistrStruct scalar parqCalibDistrStructTemp
	
	parqCalibDistrStructTemp.devel = devel
	parqCalibDistrStructTemp.m = m
	parqCalibDistrStructTemp.thres = thres
	parqCalibDistrStructTemp.cLevel = cLevel

	return(parqCalibDistrStructTemp)
}


/*function qCalibDistr(x, y, struct parqCalibDistrStruct scalar parqCalibDistrStructTemp) {*/
function qCalibDistr(x, struct parqCalibDistrStruct scalar parqCalibDistrStructTemp) {	
	y = ( givitiStatCdf(x, 
						parqCalibDistrStructTemp.m, 
						parqCalibDistrStructTemp.devel, 
						parqCalibDistrStructTemp.thres) - parqCalibDistrStructTemp.cLevel)
		
    return(y)

}

function givitiCalibrationTestComp(o, e, nameO, devel, 
									thres, maxDeg, nameLogite) {
	
  if(devel == "external"){

    startDeg = 1

  };

  if(devel == "internal"){

    startDeg = 2

  };

  /*Best model selection (m and fit) */
  m = polynomialLogRegrFw(nameO, thres, maxDeg, startDeg, nameLogite)

  /* GiViTI Calibration Test*/
  logLikBisector = colsum((1 :- o) :* log(1 :- e) :+ o :* log(e))

  calibrationStat = 2 * (st_numscalar("e(ll)") - logLikBisector)

  calibrationP = 1 - givitiStatCdf(calibrationStat, m, devel, thres)

  outputCalibrationTest = (m, calibrationStat, calibrationP)
  return(outputCalibrationTest)

}

function calibrationK(devel, m, thres, cLevel) {
	
	if(devel == "external"){

		inverseCumulativeStart = (m - 1) * invchi2(1, thres) + 0.0001

	}

	if(devel == "internal"){

		inverseCumulativeStart = (m - 2) * invchi2(1, thres) + 0.0001

	}

	calibKTemp = 9999
	otherParametersqCalibDistr = parqCalibDistr(m, devel, thres, cLevel) 
	outputCalibK = mm_root(calibKTemp, &qCalibDistr(), inverseCumulativeStart, 40,  0, 10000, otherParametersqCalibDistr)

	calibK = calibKTemp
	
	/*S_calibK = solvenl_init()

	solvenl_init_iter_log(S_calibK, "off")
	solvenl_init_iter_dot(S_calibK, "off")

	solvenl_init_evaluator(S_calibK, &qCalibDistr())

	solvenl_init_narguments(S_calibK,1)
	otherParametersqCalibDistr = parqCalibDistr(m, devel, thres, cLevel) 
	solvenl_init_argument(S_calibK,1, otherParametersqCalibDistr)

	solvenl_init_type(S_calibK, "zero")
	solvenl_init_technique(S_calibK, "newton")
	solvenl_init_numeq(S_calibK, 1)
	solvenl_init_startingvals(S_calibK, inverseCumulativeStart)
	calibK = solvenl_solve(S_calibK)*/

	return(calibK)
}

function setStartingParameters(o, betaML, vcovML, gradNorm, G, thresholdLogLik) {

	eigensystemselecti(vcovML, (1,1), eigenvectors=., eigenvalue=.)

	rhoLim = 10* sqrt(eigenvalue)
	
	rhoMinTemp = 9999
	otherParametersRhoMin = parLogLikelihood(betaML, -gradNorm, G, o, thresholdLogLik) 
	outputRhoMin = mm_root(rhoMinTemp, &logLikelihood(), 0, Re(rhoLim),  0, 10000, otherParametersRhoMin)
	
	rhoMaxTemp = 9999	
	otherParametersRhoMax = parLogLikelihood(betaML, gradNorm, G, o, thresholdLogLik) 
	outputRhoMax = mm_root(rhoMaxTemp, &logLikelihood(), 0, Re(rhoLim),  0, 10000, otherParametersRhoMax)

	rhoMin = rhoMaxTemp
	rhoMax = rhoMaxTemp
	
	/*--------------------------*/
	/* STATA built in functions */
	/*--------------------------*/
	
	/*Rho Minimum*/
	/*S_rhoMin = solvenl_init()

	solvenl_init_iter_log(S_rhoMin, "off")
	solvenl_init_iter_dot(S_rhoMin, "off")

	solvenl_init_evaluator(S_rhoMin, &logLikelihood())

	solvenl_init_narguments(S_rhoMin,1)
	otherParametersRhoMin = parLogLikelihood(betaML, -gradNorm, G, o, thresholdLogLik) 
	solvenl_init_argument(S_rhoMin,1, otherParametersRhoMin)

	solvenl_init_type(S_rhoMin, "zero")
	solvenl_init_technique(S_rhoMin, "newton")
	solvenl_init_conv_nearzero(S_rhoMin, 1e-6)
	solvenl_init_numeq(S_rhoMin, 1)
	solvenl_init_startingvals(S_rhoMin, Re(rhoLim))
	rhoMin = solvenl_solve(S_rhoMin)*/
		

	/*Rho Maximum*/
	/*S_rhoMax = solvenl_init()

	solvenl_init_iter_log(S_rhoMax, "off")
	solvenl_init_iter_dot(S_rhoMax, "off")

	solvenl_init_evaluator(S_rhoMax, &logLikelihood())

	solvenl_init_narguments(S_rhoMax,1)
	otherParametersRhoMax = parLogLikelihood(betaML, gradNorm, G, o, thresholdLogLik) 
	solvenl_init_argument(S_rhoMax,1, otherParametersRhoMax)

	solvenl_init_type(S_rhoMax, "zero")
	solvenl_init_technique(S_rhoMax, "newton")
	solvenl_init_conv_nearzero(S_rhoMax, 1e-6)
	solvenl_init_numeq(S_rhoMax, 1)
	solvenl_init_startingvals(S_rhoMax, Re(rhoLim))
	rhoMax = solvenl_solve(S_rhoMax)*/

	betaBoundMin = betaML + rhoMin * (- gradNorm)  
	betaBoundMax = betaML + rhoMax * gradNorm

	epsilonMin = sqrt(colsum((jacLogLikelihood(betaBoundMin, G, o)):^2))
	epsilonMax = -sqrt(colsum((jacLogLikelihood(betaBoundMax, G, o)):^2))

	parMin = (betaBoundMin \ epsilonMin)
	parMax = (betaBoundMax \ epsilonMax)

	return(parMin, parMax)
}


function calibrationBeltPoints(o, logite, m, devel, thres, cLevel, seqG) {

	G = J(rows(logite), 1, 1)
	for (i=1; i <= m; i++) {
		G = G, logite:^i	
	}

	g = seqG[1]
	grad = g:^((0..m)')
	gradNorm = grad :/ sqrt(grad' * grad) 

	permutationMatrix =  J(1, m, 0), 1 \  I(m) , J(m,1,0)   
	betaML = permutationMatrix * st_matrix("e(b)")'
	vcovML = permutationMatrix * (permutationMatrix * st_matrix("e(V)"))' 
	logLikOpt = st_numscalar("e(ll)")

	calibK = calibrationK(devel, m, thres, cLevel)
	thresholdLogLik = (- calibK/2 + logLikOpt)

	startingParameters = setStartingParameters(o, betaML, vcovML, gradNorm, G, thresholdLogLik)
	parMin = startingParameters[,1]
	parMax = startingParameters[,2]

	for (j=1; j<=rows(seqG); j++) {
		
		g = seqG[j]
		
		/*Minimum*/
		S = solvenl_init()

		solvenl_init_iter_log(S, "off")
		solvenl_init_iter_dot(S, "off")

		solvenl_init_evaluator(S, &Fn())

		solvenl_init_narguments(S,1)
		otherParameters = parFn(g, m , G, o , thresholdLogLik) 
		solvenl_init_argument(S,1, otherParameters)

		solvenl_init_type(S, "zero")
		solvenl_init_technique(S, "newton")
		solvenl_init_conv_nearzero(S, 1e-4)
		solvenl_init_numeq(S, m+2)
		solvenl_init_startingvals(S, parMin)

		parMin = solvenl_solve(S)
		betaMin = parMin[1..(m+1)]
		
		/*Maximum*/
		S = solvenl_init()

		solvenl_init_iter_log(S, "off")
		solvenl_init_iter_dot(S, "off")

		solvenl_init_evaluator(S, &Fn())

		solvenl_init_narguments(S,1)
		otherParameters = parFn(g, m , G, o , thresholdLogLik) 
		solvenl_init_argument(S,1, otherParameters)

		solvenl_init_type(S, "zero")
		solvenl_init_technique(S, "newton")
		solvenl_init_conv_nearzero(S, 1e-4)
		solvenl_init_numeq(S, m+2)
		solvenl_init_startingvals(S, parMax)

		parMax = solvenl_solve(S)
		betaMax = parMax[1..(m+1)]

		if(j==1) {
			betaMinMatrix = betaMin'
			betaMaxMatrix = betaMax'
		} 
		else {
			betaMinMatrix = betaMinMatrix \ betaMin'
			betaMaxMatrix = betaMaxMatrix \ betaMax'
		}

	}

	Gdisplay = J(rows(seqG), 1, 1)
	for (i=1; i <= m; i++) {
		Gdisplay = Gdisplay, seqG:^i	
	}

	lowerBound = logistic(rowsum(Gdisplay :* betaMinMatrix)) 
	upperBound = logistic(rowsum(Gdisplay :* betaMaxMatrix)) 

	return(lowerBound, upperBound)
}

function calibrationBeltPointsApprox(m, devel, thres, cLevel, seqG) {

	permutationMatrix =  J(1, m, 0), 1 \  I(m) , J(m,1,0)   
	betaML = permutationMatrix * st_matrix("e(b)")'
	vcovML = permutationMatrix * (permutationMatrix * st_matrix("e(V)"))' 
	
	calibK = calibrationK(devel, m, thres, cLevel)
	
	Gdisplay = J(rows(seqG), 1, 1)
	for (i=1; i <= m; i++) {
		Gdisplay = Gdisplay, seqG:^i	
	}
	
	temp = J(rows(seqG), 1, 1) :* .
	for(i=1; i <= rows(seqG); i++) {
		temp[i] = Gdisplay[i,] * vcovML * ((Gdisplay[i,])')
	}

	lowerBound = logistic(Gdisplay * betaML - sqrt(calibK :* temp))
	upperBound = logistic(Gdisplay * betaML + sqrt(calibK :* temp)) 

	return(lowerBound, upperBound)
}


void function calibrationBelt(struct argsCalibBeltStruct scalar currentArgsCalibBelt) {

	/* Parameters */
	nameO = currentArgsCalibBelt.nameO
	nameE = currentArgsCalibBelt.nameE
	nameLogite = currentArgsCalibBelt.nameLogite
	
	infoFromLogisticRegressionFit = currentArgsCalibBelt.infoFromLogisticRegressionFit
	
	devel = currentArgsCalibBelt.devel
	maxDeg = currentArgsCalibBelt.maxDeg
	cLevel = currentArgsCalibBelt.cLevel
	nPoints = currentArgsCalibBelt.nPoints
	thres = currentArgsCalibBelt.thres
	ifString = currentArgsCalibBelt.ifString
	twowayopts = currentArgsCalibBelt.twowayopts

	
	/**************/
	/* BUG FIXING */
	/**************/
	/* After definition of the objects in the "bug fixing cb.do" file, start from here. */
	
	/* Calibration Belt generation */
	if(ifString!="") {
		nameONew = st_tempname()
		stata("gen " + nameONew + "=" + nameO + " " + ifString)
		nameO = nameONew
	};

	/*Response*/
	o = st_data(.,st_varindex(nameO))

	if(infoFromLogisticRegressionFit == 1) {
		/* If cb after fit, save last fitted model and execute 
		   again at the end of the procedure */
		cmdlineBeforeCB = st_global("e(cmdline)")
		
		stata("predict " + nameLogite + ", xb")
		
		if(ifString!="") {
			nameLogiteNew = st_tempname()
			stata("gen " + nameLogiteNew + "=" + nameLogite + " " + ifString)
			nameLogite = nameLogiteNew
		};
		
		logite = st_data(.,st_varindex(nameLogite))
		e = logistic(logite)	
		
	} else {
	
		if(ifString!="") {
			nameENew = st_tempname()
			stata("gen " + nameENew + "=" + nameE + " " + ifString)
			nameE = nameENew
		};
		
		e = st_data(.,st_varindex(nameE))
		logite = logit(e)
		st_store((1,length(o)), st_addvar("double", nameLogite), logite)

	}
	
	if( colsum(e :< 0 :& e:!=.)>0 | colsum(e :> 1 :& e:!=.)>0) {
	
		if(infoFromLogisticRegressionFit == 1) {
			_error((" Some of the predicted probabilities are outside the interval (0,1) "))
		} else {
			_error((" The variable -" + nameE + "- must be numeric with values in the interval (0,1) "))
		}
	};
	
	if( colsum(o :!= 0 :& o :!= 1 :& o:!=.)>0 ) {
		_error((" The variable -" + nameO + "- must be numeric with values 0 or 1 "))
	};
	
	/*Drop missing values*/
	dataTemp = (o, logite, e)
	dataTempNoMissing = select(dataTemp, rowmissing(dataTemp) :== 0)
	sampleSize = rows(dataTempNoMissing)

	o = dataTempNoMissing[,1]
	logite = dataTempNoMissing[,2]
	e = dataTempNoMissing[,3]

	/*Calibration test*/
	outputCalibrationTest = givitiCalibrationTestComp(o, e, nameO, devel, 
													   thres, maxDeg, nameLogite)
	m = outputCalibrationTest[1] 
	calibrationStat = outputCalibrationTest[2]
	calibrationP = outputCalibrationTest[3]

	
	/*Vector of points used to plot the belt*/
	halfEquispLogit = rangen(min(logite), max(logite), round(nPoints/2))
	halfEquispProb = logit(rangen(min(e), max(e), round(nPoints/2)))

	seqG = sort(halfEquispLogit \ halfEquispProb, 1)
	seqP = logistic(seqG) 
	minMax = min(e), max(e)
	
	/*Computation of calibration belt bounds*/
	for(i=1; i<=length(cLevel); i++) {
		
		
		/* If sample size small-moderate (n<10,000): classic approach to compute calibration belt boundaries. */
		/* If sample size large (n>10,000): Wald approximation to compute bounds. */
		
		if(sampleSize < 10000) {
			cbBounds = calibrationBeltPoints(o, logite, m, devel, thres, cLevel[i], seqG)
		} else {
			cbBounds = calibrationBeltPointsApprox(m, devel, thres, cLevel[i], seqG)
		}
		
		lowerBound = cbBounds[,1]
		upperBound = cbBounds[,2]

		cbIntersections = calibrationBeltIntersections(lowerBound, upperBound, seqP, minMax)
		
		if(i==1) {
			cbBoundMultipleCLevels = cbBounds
			cbIntersectionsMultipleCLevels = cbIntersections
		} else {
			cbBoundMultipleCLevels = cbBoundMultipleCLevels, cbBounds
			cbIntersectionsMultipleCLevels = cbIntersectionsMultipleCLevels \ cbIntersections
		}
	}


	/*
	polynomialString = "Grado del polinomio"
	pvalueString = "p"
	nString = "N"
	*/

	/*Plot calibration belt*/
	plotCalibrationBelt(cbBoundMultipleCLevels, logistic(seqG), 
						cbIntersectionsMultipleCLevels,
						m, calibrationStat, calibrationP, sampleSize, cLevel, devel, twowayopts) 

	if(infoFromLogisticRegressionFit==1) {
		stata(("quietly " + cmdlineBeforeCB))
	};
	
	
	st_strscalar("devel", devel)
	st_numscalar("r(sampleSize)", sampleSize)
	st_numscalar("r(m)", m)
	st_numscalar("r(calibrationStat)", calibrationStat)
	st_numscalar("r(calibrationP)", calibrationP)
}
	
end


