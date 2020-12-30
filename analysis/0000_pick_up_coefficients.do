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
*	Typical use:		get_coefs, coef_matrix(b) eqname("onscoviddeath:") ///
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





****************************************************
*  Program to identify pairwise interaction terms  *
****************************************************

capture program drop identify_tripleinteract 
program define identify_tripleinteract, rclass

	syntax, term(string)
	
		* Check a three-way interaction is there (assume no 4-way or higher)
		local istripleinter = regexm(subinstr("`term'", "#", "!", 1), "#")

		* If present, separate into the three terms
		if `istripleinter'==1 {
			
			* Separate first from second/third terms
		    local pos_hash = 1
			local ok = 0
			while `ok' == 0 {
				local ++pos_hash
				local ok = substr("`term'", `pos_hash', 1)=="#"
			}
			local endfirst 		   = `pos_hash' - 1
			local startsecondthird = `pos_hash' + 1
			local firstterm        = substr("`term'", 1, `endfirst')
			local secondthirdterm  = substr("`term'", `startsecondthird', .)
			
			* Separate second from third terms
		    local pos_hash = 1
			local ok = 0
			while `ok' == 0 {
				local ++pos_hash
				local ok = substr("`secondthirdterm'", `pos_hash', 1)=="#"
			}
			local endsecond  = `pos_hash' - 1
			local startthird = `pos_hash' + 1
			local secondterm = substr("`secondthirdterm'", 1, `endsecond')
			local thirdterm  = substr("`secondthirdterm'", `startthird', .)
			
		}
		else {
		    local firstterm  = "`term'"
			local secondterm = ""
			local thirdterm  = ""
		}
		return scalar istripleinter = `istripleinter'
		return local firstterm   = "`firstterm'"
		return local secondterm  = "`secondterm'"
		return local thirdterm   = "`thirdterm'"
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
* 3bn.ethnicity becomes (ethnicity==3)

capture program drop identify_varexpress
program define identify_varexpress, rclass

	syntax, term(string)
	

			* For terms of the form #bno. convert to #.
			* e.g. 3bno.ethnicity becomes 3.ethnicity
			local term = subinstr("`term'", "bno.", ".", 1)

			* For terms of the form #bn. convert to #.
			* e.g. 3bn.ethnicity becomes 3.ethnicity
			local term = subinstr("`term'", "bn.", ".", 1)

			* For terms of the form #b. convert to #.
			* e.g. 3b.ethnicity becomes 3.ethnicity
			local term = subinstr("`term'", "b.", ".", 1)
			
			* For terms of the form #o. convert to #.
			* e.g. 3o.ethnicity becomes 3.ethnicity
			* These terms are omitted - the associated coefficient is zero
			local term = subinstr("`term'", "o.", ".", 1)

			* Omitted continuous variables then become .varname; remove .
			if substr("`term'", 1, 1)=="." {
				local term = substr("`term'", 2, length("`term'"))
			}
			
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

* NB: eqname must include the colon, e.g. onscoviddeath:

capture program drop get_coefs
program define get_coefs
	syntax , coef_matrix(string) dataname(string) [cons_no eqname(string)]

	global terms: colfullnames `coef_matrix'
	tokenize $terms 
	
	
	local i = 1
	local j = 1
	while "``i''" != "" {

		* Remove eqname prefix, e.g. "onscoviddeath:
		local length_prefix = length("`eqname'") + 1
		local term_`j' = substr("``i''", `length_prefix', .)
		
		
		* Check for three-way interaction
		identify_tripleinteract, term("`term_`j''")
		local istripleinter	= r(istripleinter) 
		local firstterm 	= r(firstterm)
		local secondterm 	= r(secondterm)
		local thirdterm 	= r(thirdterm)
			
		* Otherwise check for two-way interaction
		if `istripleinter'== 0 {				
			identify_pairinteract, term("`term_`j''")
			local ispairinter	= r(ispairinter) 
			local firstterm 	= r(firstterm)
			local secondterm 	= r(secondterm)
		}	
			
		* Save the value of coefficient
		if "`term_`j''"!="base_surv28" & "`term_`j''"!="base_surv100"  ///
			& "`term_`j''"!="sigma" & "`term_`j''"!="kappa" {
			
			local coef_`j' = _b["`term_`j''"]
		
			* Identify the variable expression
			if `ispairinter'==0 & `istripleinter'== 0 {
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
				if `istripleinter'==1 {
					identify_varexpress, term("`thirdterm'")
					local varexpress3 = r(varexpress)					
					local varexpress_`j' = "`varexpress_`j''"+"*"+"`varexpress3'"
				}
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
		
	}
			
	postclose `coefs_pf'
	
end


