********************************************************************************
*
*	Do-file:			daypois.do
*
*	Written by:			Fizz
*
*	Data used:			None
*						None
*	Data created:		None
*
*	Other output:		Program: daypois
*
********************************************************************************
*
*	Purpose:			This do-file contains a program to perform maximum 
*						likelihood estimation for a Poisson model for COVID-19
*						incorporating time-varying measures of infection 
*						prevalance and immunity. 
*	 
*		Typical use:
*			daypois covid i.diabetes age chronic_respiratory_disease, 	///
* 				timevar(cons day daysq) 								///
*				weight(sf_weight) start(0.5 0.5 0.5)	///
*				timeadj(None)
*
*				timeadj options: 	None (no time-varying things)
*									Quadratic (quadratic coefs)
*									Other 
*	
********************************************************************************





capture program drop daypois
program define daypois, rclass
	version 16
	syntax varlist(min=2 fv), timeadj(string) timevar(varlist) ///
		[weight(varname) start(numlist min=3 max=3)]
		
	*********************
	*  Pick up inputs   *
	*********************

		* Outcome and covariates
		tokenize `varlist'
		local y `1'
		macro shift
		local cov `*'
		
		* Time variables (assume quadratic, b=cons, c=day, d=daysq)
		if "`timeadj'"== "Quadratic" {
			tokenize `timevar'
			local b `1'
			local c `2'
			local d `3'
		}
		else if "`timeadj'"== "Other" {
			tokenize `timevar'
			local timecov `*'
		}	

		* Weight variable
		if "`weight'"!="" {
			local weight_opt = "[pweight = `weight']"
		}	
		else {
			local weight_opt " "
		}
		
		* Starting values 
		if "`timeadj'"== "Quadratic" & "`start'"!="" {
			tokenize `start'
			local bstart `1'
			local cstart `2'
			local dstart `3'
			local start_opt =   "from(b:_cons="+"`bstart'"+ ///
									" c:_cons="+"`cstart'"+ ///
									" d:_cons="+"`dstart'"+")"
		}
		else {
			local start_opt = "difficult"
		}

	
	************************
	*  Linear predictors   *
	************************
	
		* Exponential of linear predictor, covariates
		local expt1l = "exp({xb: `cov'})"
		local expt1  = "exp({xb: })"
		
		if "`timeadj'"== "Quadratic" {
			* Predictor for time variables, longhand
			local t2l_b = "exp({b: _cons})*`b'"
			local t2l_c = "exp({c: _cons})*`c'"
			local t2l_d = "exp({d: _cons})*`d'"
			local t2l = "("+"`t2l_b'"+" - "+"`t2l_c'"+" + "+"`t2l_d'"+")"
		
			* Predictor for time variables, shorthand
			local t2_b = "exp({b: })*`b'"
			local t2_c = "exp({c: })*`c'"
			local t2_d = "exp({d: })*`d'"
			local t2 = "("+"`t2_b'"+" - "+"`t2_c'"+" + "+"`t2_d'"+")"
		}
		else if "`timeadj'"== "Other" {
			* Predictor for time variables, longhand
			local t2l = "{z: `timecov'}"
		
			* Predictor for time variables, shorthand
			local t2  = "{z: }"
		}
		else if  "`timeadj'"== "None" {
			local t2l = "1"
			local t2  = "1"
		}
		
		
		
	****************************
	*  Display input options   *
	****************************		
	
	
	local stars = "******************************************************"
	
	noi display _n "`stars'""`stars'"
	noi display _n _col(30) "SUMMARY"
	noi display _n "Outcome:"  			_col(50) "`y'"
	noi display    "Covariates:"  		_col(50) "`cov'"
	noi display "Time-varying covariates:"
	if "`timeadj'"== "Quadratic" {
		noi display   _col(5) "Cons:"  		_col(50) "`b'"
		noi display   _col(5) "Day:" 		_col(50) "`c'"
		noi display   _col(5) "Day-sq:"  	_col(50) "`d'"
	}
	else {
		noi display   _col(5) "None"  	
	}
	noi di _n "Model options:"
	noi di _col(5)"Weight:" 			_col(50) "`weight_opt'"
	noi di _col(5)"Starting values" 	_col(50) "`start_opt'"
	
	noi display _n "`stars'""`stars'"

	
	
	
			
	*********************************************
	*  Assemble log-likelihood and derivatives  *
	********************************************	

	
	/*  Log-likelihood */
	
	local ll = "-(1-`y')*`expt1l'*`t2l' + `y'*log(1 - exp(-1*`expt1'*`t2'))"
	
	
	/*  Derivative for time-fixed covariates  */
		
	local dtheta1 = "deriv(/xb = -(1-`y')*`expt1'*`t2'"  		+ ///
					"+ `y'*`expt1'*`t2'*exp(-`expt1'*`t2')*("	+ ///
						"(1 - exp(-1*`expt1'*`t2'))^(-1)"		+ ///
					")"											+ ///
				")" 	
	
	
	
	/*  Derivative for time-varying covariates   */

	if "`timeadj'"== "Quadratic" {
		local dtheta2b =	"deriv(/b = 	`t2_b'*("				+ ///
							"-(1-`y')*`expt1'" 						+ ///
							"+ `y'*`expt1'*exp(-`expt1'*`t2')*("	+ ///
								"(1 - exp(-1*`expt1'*`t2'))^(-1)"	+ ///
							")"										+ ///
						")"											+ ///
					")"												
		local dtheta2c =	"deriv(/c = 	-`t2_c'*("				+ ///
							"-(1-`y')*`expt1'" 						+ ///
							"+ `y'*`expt1'*exp(-`expt1'*`t2')*("	+ ///
								"(1 - exp(-1*`expt1'*`t2'))^(-1)"	+ ///
							")"										+ ///
						")"											+ ///
					")"												
		local dtheta2d =	"deriv(/d = 	`t2_d'*("				+ ///
							"-(1-`y')*`expt1'" 						+ ///
							"+ `y'*`expt1'*exp(-`expt1'*`t2')*("	+ ///
								"(1 - exp(-1*`expt1'*`t2'))^(-1)"	+ ///
							")"										+ ///
						")"											+ ///
					")"	
		local dtheta2 = "`dtheta2b' " + "`dtheta2c' " + "`dtheta2d' " 
	}	
	else if "`timeadj'"== "Other" {
		local dtheta2 =	"deriv(/z = 	"				+ ///
							"-(1-`y')*`expt1'" 						+ ///
							"+ `y'*`expt1'*exp(-`expt1'*`t2')*("	+ ///
								"(1 - exp(-1*`expt1'*`t2'))^(-1)"	+ ///
							")"										+ ///
					")"												
	}
	else if "`timeadj'"== "None" {
	   local dtheta2 = " "
	}
				
	
	
	/*  Maximum likelihood estimation  */
	
	* Poisson y=0 vs y>0 with analytic derivs and probability weights
	noi mlexp (`ll') 								///
		`weight_opt',								///	
		`dtheta1'									///
		`dtheta2'									///
		`start_opt'
		
		matrix b = e(b)
		matrix V = e(V)
		
		* Put the time-varying parameter estimates on original scale
	if "`timeadj'"== "Quadratic" {
		nlcom 	(cons:   exp(_b[b:_cons])) 	///
				(day:   -exp(_b[c:_cons]))	///	
				(daysq:  exp(_b[d:_cons]))
	}	
		* Return estimates
		return matrix b = b
		return matrix V = V
		
				
end



