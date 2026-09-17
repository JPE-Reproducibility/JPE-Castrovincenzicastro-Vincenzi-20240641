* =======================================================================
* PROGRAM:    Rebuild censuscr_97-02-07-12_n6.dta from Census raw files
* =======================================================================
*
* Raw archives and their source URLs are in:
*   data/raw/census/concentration_ratios/

clear all

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

local raw "data/raw/census/concentration_ratios"
local output "data/dta/censuscr_97-02-07-12_n6.dta"

* The shared series use the standard Census codes. Manufacturing uses its
* subject-series concentration file instead.
local sectors "22 42 44 48 51 52 53 54 56 61 62 71 72 81"

* Import and reduce one 2002/2007/2012 Census table.
capture program drop _census_modern
program define _census_modern
	syntax, FILE(string) YEAR(integer) MFG(integer) OUTFILE(string)

* Import as text first: this preserves the published decimal strings before
* the explicit numeric conversions below.  Stata otherwise chooses float
* storage for several columns while importing delimited text.
	import delimited using "`file'", clear varnames(1) stringcols(_all)
	rename *, upper

	local naics NAICS`year'
	gen str9 naics6 = strtrim(`naics')
	replace naics6 = strtrim(naics6)

	* The source files contain industry aggregates and product-line detail.
	* Retain six-character NAICS industries only.
	keep if strlen(naics6) == 6

	* Some subject-series releases repeat data by tax status.  Retain the
	* all-establishments universe (00 where available, otherwise A).
	capture confirm variable OPTAX
	if !_rc {
		quietly count if strtrim(OPTAX) == "00"
		if r(N) > 0 keep if strtrim(OPTAX) == "00"
		else        keep if strtrim(OPTAX) == "A"
	}

	* Preserve the numeric precision published in the Census source files.
	local share VAL_PCT
	if `mfg' == 1 local share CCORCPPCT
	if `year' == 2002 & `mfg' == 0 local share VALPCT

	gen double company = .
	gen double sales = real(RCPTOT)
	gen double cr4 = .
	gen double cr8 = .
	gen double cr20 = .
	gen double cr50 = .
	gen double hhi50 = .
	gen double estab = .

	capture confirm variable RCPTOT_F
	if !_rc replace sales = . if strtrim(RCPTOT_F) != ""

	capture confirm variable ESTAB
	if !_rc {
		replace estab = real(ESTAB)
		capture confirm variable ESTAB_F
		if !_rc replace estab = . if strtrim(ESTAB_F) != ""
	}

	if `mfg' == 1 {
		replace company = real(COMPANY)
		local companyflag COMPANY_F
		capture confirm variable `companyflag'
		if _rc local companyflag COMPANYF
		capture confirm variable `companyflag'
		if !_rc replace company = . if strtrim(`companyflag') != ""

		* Retain the HHI value at its published decimal precision.
		replace hhi50 = real(VSHERFI)
		capture confirm variable VSHERFI_F
		if !_rc replace hhi50 = . if strtrim(VSHERFI_F) != ""
	}

	gen double _share = real(`share')
	capture confirm variable `share'_F
	if !_rc replace _share = . if strtrim(`share'_F) != ""
	gen str3 _concenfi = strtrim(CONCENFI)
	replace _concenfi = strtrim(_concenfi)
	replace cr4  = _share if inlist(_concenfi, "804", "856")
	replace cr8  = _share if inlist(_concenfi, "808", "857")
	replace cr20 = _share if inlist(_concenfi, "820", "858")
	replace cr50 = _share if inlist(_concenfi, "850", "859")

	drop _share _concenfi
	collapse (max) company sales cr4 cr8 cr20 cr50 hhi50 estab, by(naics6)
	gen float year = `year'
	sort naics6 year
	save "`outfile'", replace
end

* 1997 is the manufacturing-only R2 table.  Its fields are already one row
* per NAICS industry, so retain their original double precision.
tempfile y1997
import delimited using "`raw'/1997/E9731R2.dat", clear varnames(1) stringcols(_all)
rename *, upper
gen str9 naics6 = strtrim(NAICS)
keep if strlen(naics6) == 6
gen double company = real(COMPANY)
gen double sales = real(ECVALUE)
gen double cr4 = real(VSTOP4)
gen double cr8 = real(VSTOP8)
gen double cr20 = real(VSTOP20)
gen double cr50 = real(VSTOP50)
gen double hhi50 = real(VSHERFI)
gen double estab = .
foreach v in COMPANY ECVALUE VSTOP4 VSTOP8 VSTOP20 VSTOP50 VSHERFI {
	capture confirm variable `v'F
	if !_rc {
		local target = lower("`v'")
		if "`v'" == "ECVALUE" local target sales
		if "`v'" == "VSTOP4"  local target cr4
		if "`v'" == "VSTOP8"  local target cr8
		if "`v'" == "VSTOP20" local target cr20
		if "`v'" == "VSTOP50" local target cr50
		if "`v'" == "VSHERFI" local target hhi50
		replace `target' = . if strtrim(`v'F) != ""
	}
}
gen float year = 1997
keep naics6 company sales cr4 cr8 cr20 cr50 hhi50 year estab
save "`y1997'", replace

* Build each later Census year from one manufacturing and fourteen
* non-manufacturing subject-series files.
foreach y in 2002 2007 2012 {
	local yy = string(mod(`y', 100), "%02.0f")
	if `y' == 2002 local mfgfile "EC0231SR12.dat"
	if `y' == 2007 local mfgfile "EC0731SR12.dat"
	if `y' == 2012 local mfgfile "EC1231SR2.dat"

	tempfile year`y' mfg
	_census_modern, file("`raw'/`y'/`mfgfile'") year(`y') mfg(1) outfile("`mfg'")
	use "`mfg'", clear

	foreach s of local sectors {
		tempfile piece
		preserve
		_census_modern, file("`raw'/`y'/EC`yy'`s'SSSZ6.dat") year(`y') mfg(0) outfile("`piece'")
		restore
		append using "`piece'"
	}
	sort naics6 year
	save "`year`y''", replace
}

use "`y1997'", clear
append using "`year2002'"
append using "`year2007'"
append using "`year2012'"

* Set the output schema and storage types.
gen str9 n1997 = ""
gen str9 n2002 = ""
gen str9 n2007 = ""
gen str6 n2012 = ""
replace n1997 = naics6 if year == 1997
replace n2002 = naics6 if year == 2002
replace n2007 = naics6 if year == 2007
replace n2012 = naics6 if year == 2012
recast long company estab
recast float year
label variable estab "(max) estab"
order naics6 company sales cr4 cr8 cr20 cr50 hhi50 year estab n1997 n2002 n2007 n2012
format naics6 n1997 n2002 n2007 n2012 %9s
format company sales %12.0g
format cr4 cr8 cr20 cr50 hhi50 %10.0g
format year %9.0g
format estab %10.0g
sort naics6 year
save "`output'", replace
