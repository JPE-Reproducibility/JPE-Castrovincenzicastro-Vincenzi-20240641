* =======================================================================
* PROGRAM:		Create Table C.2: Industries with the Largest Increase in Commodity Prices
* DATE:			03 April 2026
* NOTE:			Top 15 industries by shift-share price shock, 2000-2010.
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
* Load and compute
* ======================================================================

use "data/dta/mainregfile.dta", clear
merge m:1 naics using "data/raw/misc/naicsnames12.dta", keep(1 3) nogen

* Get 2000 values
preserve
	keep if year == 2000
	keep naics shift_share_ct labshr share_ct description
	rename (shift_share_ct labshr share_ct) (ss_2000 labshr_2000 commodity_intensity)
	tempfile y2000
	save "`y2000'"
restore

* Get 2010 values
preserve
	keep if year == 2010
	keep naics shift_share_ct labshr
	rename (shift_share_ct labshr) (ss_2010 labshr_2010)
	tempfile y2010
	save "`y2010'"
restore

use "`y2000'", clear
merge 1:1 naics using "`y2010'", keep(3) nogen

* Price shock as % change: exp(Δ log price) - 1
gen price_shock = (exp(ss_2010 - ss_2000) - 1) * 100
gen delta_labshr = labshr_2010 - labshr_2000

drop if missing(price_shock) | missing(delta_labshr) | missing(commodity_intensity)

gsort -price_shock
gen rank = _n
keep if rank <= 15

* ======================================================================
* Clean descriptions
* ======================================================================

replace description = subinstr(description, "&", "\&", .)
replace description = subinstr(description, "%", "\%", .)
replace description = subinstr(description, "_", "\_", .)
replace description = subinstr(description, "#", "\#", .)
replace description = subinstr(description, "<", "$<$", .)
replace description = subinstr(description, ">", "$>$", .)
replace description = strtrim(description)

* Truncate at ~40 chars for column width
gen desc_clean = description
replace desc_clean = substr(desc_clean, 1, 40) if strlen(desc_clean) > 40
replace desc_clean = regexs(0) if regexm(desc_clean, "^(.+ )") & strlen(description) > 40
replace desc_clean = strtrim(desc_clean)

format price_shock %9.1f
format delta_labshr %9.3f
format commodity_intensity %9.3f

* ======================================================================
* Write LaTeX table body
* ======================================================================

capture file close ofile
file open ofile using "output/tables/tabC2.tex", write replace

local N = _N
forvalues i = 1/`N' {
	local rk = rank[`i']
	local nc = naics[`i']
	local desc = desc_clean[`i']
	local ps : display %9.1f price_shock[`i']
	local ps = strtrim("`ps'")
	local dl : display %9.3f delta_labshr[`i']
	local dl = strtrim("`dl'")
	local ci : display %9.3f commodity_intensity[`i']
	local ci = strtrim("`ci'")

	file write ofile "    `rk' & `nc' & `desc' & `ps' & `dl' & `ci' \\" _n
}
file write ofile "    \bottomrule" _n

file close ofile
