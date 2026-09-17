* =======================================================================
* PROGRAM:			construct data/dta/bea_historical.dta
* DATE:				27 July 2026
* =======================================================================

clear all
set more off

* The master initializes paths; for standalone use, first run do/setup.do.
if "$path" == "" {
    display as error "Package root is unset. Change to the package root and run do/setup.do."
    exit 198
}
if subinstr("`c(pwd)'", char(92), "/", .) != "$path" {
    display as error "The working directory differs from the initialized package root."
    display as error "Change to the intended package root and rerun do/setup.do."
    exit 198
}
foreach _ls_path_marker in "do/main.do" "do/setup.do" "do/data_cleaning/model_inputs.do" "quant_model/main.jl" {
    capture confirm file "`_ls_path_marker'"
    if _rc {
        display as error "The current directory is not a complete Replication package root."
        display as error "Missing required file: `_ls_path_marker'"
        exit 601
    }
}

cd "$path"

tempfile nber nipa va go

* ======================================================================
* NBER-CES manufacturing totals
* Use NAICS-1997 data through 2011 and NAICS-2012 data from 2012.
* ======================================================================

use "data/raw/NBER-CES/nberces_1958-2018.dta", clear
keep year vship matcost pay
gcollapse (sum) vship matcost pay, by(year)
rename (vship matcost pay) (nber_vship nber_matcost nber_pay)
save "`nber'", replace

use "data/raw/NBER-CES/nberces-1958_2018_naics2012.dta", clear
keep year vship matcost pay
gcollapse (sum) vship matcost pay, by(year)
rename (vship matcost pay) (v12 m12 p12)
merge 1:1 year using "`nber'", nogen
replace nber_vship   = v12 if year >= 2012
replace nber_matcost = m12 if year >= 2012
replace nber_pay     = p12 if year >= 2012
drop v12 m12 p12
save "`nber'", replace

* 2007-2011 come from the 1958-2011 NBER-CES release
use "data/raw/NBER-CES/nberces_1958-2011_naics.dta", clear
keep year vship matcost pay
gcollapse (sum) vship matcost pay, by(year)
rename (vship matcost pay) (v11 m11 p11)
merge 1:1 year using "`nber'", nogen
replace nber_vship   = v11 if inrange(year, 2007, 2011)
replace nber_matcost = m11 if inrange(year, 2007, 2011)
replace nber_pay     = p11 if inrange(year, 2007, 2011)
drop v11 m11 p11
save "`nber'", replace

* ======================================================================
* NIPA annual: compensation and wages in manufacturing, 1998-2018
* ======================================================================

capture program drop _nipa_manuf
program define _nipa_manuf
	args sheet code newname out
	import excel using "data/raw/aggregate/BEA_NIPA_Section6_Dec2019.xlsx", ///
		sheet("`sheet'") cellrange(A1) allstring clear

	gen long _r = _n
	qui su _r if strtrim(A) == "Line"
	local hdr = r(min)
	qui su _r if strtrim(C) == "`code'"
	local mrow = r(min)
	if missing(`hdr') | missing(`mrow') {
		di as error "could not locate header or series `code' in `sheet'"
		exit 459
	}

	drop _r
	tempname M
	postfile `M' int year double `newname' using "`out'", replace
	foreach v of varlist * {
		local y = real(`v'[`hdr'])
		local x = real(`v'[`mrow'])
		if !missing(`y') & `y' >= 1900 & `y' <= 2100 & !missing(`x') {
			post `M' (`y') (`x')
		}
	}
	postclose `M'
end

tempfile comp wage
_nipa_manuf "T60200D-A" "N4013C" comp_manuf  "`comp'"    // Table 6.2D
_nipa_manuf "T60300D-A" "N552RC" wages_manuf "`wage'"    // Table 6.3D

use "`comp'", clear
merge 1:1 year using "`wage'", nogen
save "`nipa'", replace

* ======================================================================
* BEA GDP by Industry: value added and gross output, manufacturing
* ======================================================================

capture program drop _bea_manuf
program define _bea_manuf
	args file sheet newname out
	import excel using "`file'", sheet("`sheet'") cellrange(A1) allstring clear

	* locate the header row and the Manufacturing row
	gen long _r = _n
	qui su _r if strtrim(A) == "Line"
	local hdr = r(min)
	qui su _r if strtrim(B) == "Manufacturing"
	local mrow = r(min)
	if missing(`hdr') | missing(`mrow') {
		di as error "could not locate header or Manufacturing row in `sheet'"
		exit 459
	}

	drop _r
	tempname M
	postfile `M' int year double `newname' using "`out'", replace
	foreach v of varlist * {
		local y = real(`v'[`hdr'])
		local x = real(`v'[`mrow'])
		if !missing(`y') & `y' >= 1900 & `y' <= 2100 {
			post `M' (`y') (`x')
		}
	}
	postclose `M'
end

_bea_manuf "data/raw/aggregate/BEA_GDPbyInd_ValueAdded.xlsx"  "VA" va_manuf "`va'"
_bea_manuf "data/raw/aggregate/BEA_GDPbyInd_GrossOutput.xlsx" "GO" go_manuf "`go'"

* ======================================================================
* BEA SIC-basis historical industry accounts, 1947-1997
* ======================================================================

capture program drop _bea_sic
program define _bea_sic
	args file sheet tag newname out
	import excel using "`file'", sheet("`sheet'") cellrange(A1) allstring clear

	gen long _r = _n
	qui su _r if strtrim(A) == "Code"
	local hdr = r(min)
	qui su _r if strtrim(A) == "`tag'" & strtrim(B) == "Manufacturing"
	local mrow = r(min)
	if missing(`hdr') | missing(`mrow') {
		di as error "could not locate header or `tag' Manufacturing row in `sheet'"
		exit 459
	}

	drop _r
	tempname M
	postfile `M' int year double `newname' using "`out'", replace
	foreach v of varlist * {
		local y = real(`v'[`hdr'])
		local x = real(`v'[`mrow'])
		if !missing(`y') & `y' >= 1900 & `y' <= 2100 & !missing(`x') {
			post `M' (`y') (`x')
		}
	}
	postclose `M'
end

* Splice the two vintages of each series, 72SIC first so it wins on 1987.
capture program drop _bea_sic_splice
program define _bea_sic_splice
	args sheet72 sheet87 tag newname out
	local f "data/raw/aggregate/BEA_GDPbyInd_SIC_1947-1997.xls"
	tempfile a b
	_bea_sic "`f'" "`sheet72'" "`tag'" `newname' "`a'"
	_bea_sic "`f'" "`sheet87'" "`tag'" `newname' "`b'"
	use "`a'", clear
	gen byte _pref = 1
	append using "`b'"
	replace _pref = 2 if missing(_pref)
	bysort year (_pref): keep if _n == 1
	drop _pref
	save "`out'", replace
end

tempfile va_sic go_sic comp_sic wage_sic

_bea_sic_splice "72SIC_VA, GO, II"       "87SIC_VA, GO, II"       "VA"   va_sic_v    "`va_sic'"
_bea_sic_splice "72SIC_VA, GO, II"       "87SIC_VA, GO, II"       "GO"   go_sic_v    "`go_sic'"
_bea_sic_splice "72SIC_Components of VA" "87SIC_Components of VA" "COMP" comp_sic_v  "`comp_sic'"
_bea_sic_splice "72SIC_Components of VA" "87SIC_Components of VA" "W&S"  wage_sic_v  "`wage_sic'"

* ======================================================================
* combine
* The SIC workbook supplies 1947-1997, the modern releases 1998-2018.
* ======================================================================

clear
set obs 72
gen int year = 1946 + _n

merge 1:1 year using "`nber'",     nogen
merge 1:1 year using "`nipa'",     nogen
merge 1:1 year using "`va'",       nogen
merge 1:1 year using "`go'",       nogen
merge 1:1 year using "`va_sic'",   nogen
merge 1:1 year using "`go_sic'",   nogen
merge 1:1 year using "`comp_sic'", nogen
merge 1:1 year using "`wage_sic'", nogen

replace va_manuf    = va_sic_v   if year <= 1997
replace go_manuf    = go_sic_v   if year <= 1997
replace comp_manuf  = comp_sic_v if year <= 1997
replace wages_manuf = wage_sic_v if year <= 1997

drop *_sic_v
keep if inrange(year, 1947, 2018)


foreach v of varlist nber_* {
	replace `v' = . if year > 2016
}
order year nber_vship nber_matcost nber_pay va_manuf go_manuf comp_manuf wages_manuf
sort year
compress
save "data/dta/bea_historical.dta", replace


