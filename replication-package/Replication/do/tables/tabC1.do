* =======================================================================
* PROGRAM:		Create Table C.1: Commodities with Largest Price Increases
* DATE:			03 April 2026
* NOTE:			Top 10 HS6 commodities by % price change, 2000-2010.
* =======================================================================
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

* ======================================================================
* Load HS96-level prices
* ======================================================================

capture confirm file "data/dta/Commodity_Prices_HS96.dta"
if _rc != 0 {
	use "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11.dta", clear
	tempfile _hs_conc2
	preserve
		use "data/raw/Concordances/HS696_Commodities.dta", clear
		keep HS92 HS96 Description
		duplicates drop
		save "`_hs_conc2'"
	restore
	joinby HS92 using "`_hs_conc2'"
	joinby HS96 using "data/raw/Concordances/HS696_to_IOT.dta"
	sort HS96 year
	gen energy = inrange(HS96, 270000, 279999)
	save "data/dta/Commodity_Prices_HS96.dta", replace
}
else {
	use "data/dta/Commodity_Prices_HS96.dta", clear
}

* Collapse to HS96 level
collapse (mean) ind_tuv (firstnm) Description [aw=weight], by(HS96 year)

* Keep 2000 and 2010
keep if inlist(year, 2000, 2010)
reshape wide ind_tuv, i(HS96 Description) j(year)

* % change
gen pct_change = (ind_tuv2010 / ind_tuv2000 - 1) * 100
drop if missing(pct_change)

* Top 10
gsort -pct_change
keep if _n <= 10

* ======================================================================
* Clean descriptions: short readable names
* ======================================================================

* Escape LaTeX special characters
replace Description = subinstr(Description, "&", "\&", .)
replace Description = subinstr(Description, "%", "\%", .)
replace Description = subinstr(Description, "_", "\_", .)
replace Description = subinstr(Description, "<", "$<$", .)
replace Description = subinstr(Description, ">", "$>$", .)
replace Description = subinstr(Description, "#", "\#", .)

* Truncate cleanly at word boundary (max ~45 chars)
gen desc_clean = Description
replace desc_clean = substr(desc_clean, 1, 45) if strlen(desc_clean) > 45
* Remove trailing partial word
replace desc_clean = regexs(0) if regexm(desc_clean, "^(.+ )") & strlen(Description) > 45
replace desc_clean = strtrim(desc_clean)

format pct_change %9.1f

* ======================================================================
* Write LaTeX table body
* ======================================================================

capture file close ofile
file open ofile using "output/tables/tabC1.tex", write replace

local N = _N
forvalues i = 1/`N' {
	local hs96 = HS96[`i']
	local desc = desc_clean[`i']
	local pct : display %9.1f pct_change[`i']
	local pct = strtrim("`pct'")

	file write ofile "     `hs96' & `desc' & `pct' \\" _n
}
file write ofile "     \bottomrule" _n

file close ofile
