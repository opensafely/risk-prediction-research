********************************************************************************
*
*	Do-file:			0000_pick_up_coefficients.do
*
*	Written by:			Fizz & John
*
*	Data used:			None 
*
*	Data created:		None
*
*	Other output:		Programs:
*							identify_basecat
*							identify_pairinteract
*							identify_varexpress
*							get_coefs
*
********************************************************************************
*
*	Purpose:			This do-file contains programs that take a coeffient
*						matrix, e.g. from a regression model, (which has the 
*						variable names and categories as column names) 
*						and extracts the coefficients and variable expressions
*						for later use. 
*
*	Typical use:		get_coefs, coef_matrix(b) eqname("onscoviddeath") ///
*							dataname("temp")
*
*
*						identify_basecat, 		term("3.ethnicity")
*						identify_pairinteract, 	term("3.ethnicity#age")
*						identify_varexpress, 	term("6.bmi")
*
*						Note: get_coefs assumes base_surv is position
*						1,1 in the matrix, if given
*
********************************************************************************



*********************************************
*  Program to identify baseline categories  *
*********************************************

capture program drop identify_basecat 
program define identify_basecat, rclass

	syntax, term(string)

		* Assumes baseline categories are of form
		*		?b. 
		*		??b. 
		*		?o. 
		*		??o.
		* (where ? is a number)
		local isbasecat = 												///
			substr("`term'", 2, 1)=="b" 						 	| 	///
			regexm(substr("`term'", 1, 3), "^[0-9]b.") 		 		| 	///
			regexm(substr("`term'", 1, 4), "^[0-9][0-9]b.") 	 	| 	///
			regexm(substr("`term'", 1, 3), "^[0-9]o.") 		 		| 	///
			regexm(substr("`term'", 1, 4), "^[0-9][0-9]o.") 

		return scalar isbasecat = `isbasecat'
end




****************************************************
*  Program to identify pairwise interaction terms  *
****************************************************

capture program drop identify_pairinteract 
program define identify_pairinteract, rclass

	syntax, term(string)

		* Identify interactions (assume pairwise at most)
		local ispairinter = regex("`term'", "#")

		* If present, separate into the two terms
		if `ispairinter'==1 {
		    local pos_hash = 1
			local ok = 0
			while `ok' == 0 {
				local ++pos_hash
				local ok = substr("`term'", `pos_hash', 1)=="#"
			}
			local endfirst = `pos_hash' - 1
			local startsecond = `pos_hash' + 1
			local firstterm  = substr("`term'", 1, `endfirst')
			local secondterm = substr("`term'", `startsecond', .)
		}
		else {
		    local firstterm  = "`term'"
			local secondterm = ""
		}
		return scalar ispairinter = `ispairinter'
		return local firstterm   = "`firstterm'"
		return local secondterm  = "`secondterm'"
end



********************************************************************
*  Program to create a variable expression from the category name  *
********************************************************************

* e.g. 3.ethnicity becomes (ethnicity==3)
* c.age becomes age

capture program drop identify_varexpress
program define identify_varexpress, rclass

	syntax, term(string)

			* Identify terms starting with a category (max cat value = 999)
			*	(assumes these all start with a number, e.g. 3.ethnicity)
			if  regexm(substr("`term'", 1, 2), "^[0-9].")  			| 	///
				regexm(substr("`term'", 1, 3), "^[0-9][0-9].")  	|  	///
				regexm(substr("`term'", 1, 4), "^[0-9][0-9][0-9].") 	///
			{
				* Split term into number and variable
				local pos_dot = 1
				local ok = 0
				while `ok' == 0 {
					local ++pos_dot
					local ok = substr("`term'", `pos_dot', 1)=="."
				}
				local endnum   = `pos_dot' - 1
				local startvar = `pos_dot' + 1
				local num = substr("`term'", 1, `endnum')
				local var = substr("`term'", `startvar', .)
				* Save variable equation
				local varexpress  = "("+"`var'"+"=="+ "`num'" +")"		
			}
			else {
			    if substr("`term'", 1, 2)=="c." {
				   local varexpress  = substr("`term'", 3, .)
				} 
				else {
					local varexpress  = "`term'"		
				}
			}
			
	return local varexpress  = "`varexpress'"
	
end







*************************************************************************************
*  Program to save coefficients and variable expressions from a coefficient matrix  *
*************************************************************************************


capture program drop get_coefs
program define get_coefs
	syntax , coef_matrix(string) dataname(string) [cons_no eqname(string)]

	global terms: colfullnames `coef_matrix'
	tokenize $terms 
	
	
	local i = 1
	local j = 1
	while "``i''" != "" {

		if "`eqname'" == "xb0:" | "`eqname'" == "_t:" | "`eqname'" == "" {
			* Remove eqname prefix, e.g. "onscoviddeath:
			local length_prefix = length("`eqname'") + 1
			local term_`j' = substr("``i''", `length_prefix', .)
		}
		else  {
			* Remove eqname prefix, e.g. "onscoviddeath:"
			local length_prefix = length("`eqname'") + 2
			local term_`j' = substr("``i''", `length_prefix', .)
		}	
		
		* Check for baseline categories in either a single or two terms
		identify_pairinteract, term("`term_`j''")
		local ispairinter	= r(ispairinter) 
		local firstterm 	= r(firstterm)
		local secondterm 	= r(secondterm)
			
		if `ispairinter' == 0 {	// Not an interaction
			* Check for baseline
			identify_basecat, term("`term_`j''")
			local isbasecat = r(isbasecat)
		}
		else {	// An interaction
			identify_basecat, term("`firstterm'")
			local isbasecat_1 = r(isbasecat)
			identify_basecat, term("`firstterm'")
			local isbasecat_2 = r(isbasecat)
			local isbasecat = max(`isbasecat_1', `isbasecat_2')
		}
	
			* If non-baseline term then save coefficient and expression
				
			* Save the value of coefficient
			if "`term_`j''"!="base_surv28" & "`term_`j''"!="base_surv100"  ///
				& "`term_`j''"!="sigma" & "`term_`j''"!="kappa" {
				
				local coef_`j' = _b["`term_`j''"]
			
				* Identify the variable expression
				if `ispairinter' == 0 {
					* Not an interaction
					identify_varexpress, term("`term_`j''")
					local varexpress_`j' = r(varexpress)
				}
				else {
					* An interaction
					identify_varexpress, term("`firstterm'")
					local varexpress1 = r(varexpress)
					identify_varexpress, term("`secondterm'")
					local varexpress2 = r(varexpress)
					local varexpress_`j' = "`varexpress1'"+"*"+"`varexpress2'"
				}
			} 
			else {
				local coef_`j' = `coef_matrix'[1,1]
				local varexpress_`j' = ""
				
				* Sigma/Kappa for generalised gamma model 
				if "`term_`j''" == "sigma" {
					local coef_`j' = `coef_matrix'[1,1]
					local varexpress_`j' = ""
					}
				if "`term_`j''" == "kappa" {
					local coef_`j' = `coef_matrix'[1,2]
					local varexpress_`j' = ""
					}	
				if "`term_`j''" == "base_surv28" {
					local coef_`j' = `coef_matrix'[1,1]
					local varexpress_`j' = ""
					}
				if "`term_`j''" == "base_surv100" {
					local coef_`j' = `coef_matrix'[1,2]
					local varexpress_`j' = ""
					}		
				
			}
			local ++i
			local ++j
		
	}
	
	* Save coefficients and variable expressions into a temporary dataset
	tempname coefs_pf
	postfile `coefs_pf' str50(term) coef str50(varexpress) ///
		using `dataname', replace
		local max = `j' - 1
		forvalues k = 1 (1) `max' {
		    if "`term_`k''" != "_cons" {
				post `coefs_pf' ("`term_`k''") (`coef_`k'') ("`varexpress_`k''")
			}
			else if "`cons_no'" == "" {
				post `coefs_pf' ("`term_`k''") (`coef_`k'') ("(constant==1)")			    
			}
		}
			
	postclose `coefs_pf'
	
end


