* =======================================================================
* PROGRAM:			construct data/dta/oilprices.dta
* DATE:				24 July 2026
* =======================================================================

clear all

* ======================================================================
* set path
* ======================================================================

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

local infile  "data/raw/misc/CMO-Historical-Data-Annual.xlsx"
local outfile "data/dta/oilprices.dta"

* Last year retained. Set to 2021 to match the vintage shipped with the
* package; raise it to extend the series with a newer workbook.
local endyear = 2021

* ======================================================================
* nominal prices (current US$)
* ======================================================================

import excel using "`infile'", sheet("Annual Prices (Nominal)") ///
	cellrange(A9) allstring clear

keep A B
rename (A B) (year oil_price_nominal)
destring year oil_price_nominal, replace force
drop if missing(year)

tempfile nominal
save "`nominal'"

* ======================================================================
* real prices (constant 2010 US$)
* ======================================================================

import excel using "`infile'", sheet("Annual Prices (Real)") ///
	cellrange(A9) allstring clear

keep A B
rename (A B) (year oil_price_real)
destring year oil_price_real, replace force
drop if missing(year)

* ======================================================================
* merge, label and save
* ======================================================================

merge 1:1 year using "`nominal'", nogen
keep if year <= `endyear'

order year oil_price_nominal oil_price_real
sort year

lab var year				"year"
lab var oil_price_nominal	"oil_price_nominal"
lab var oil_price_real		"oil_price_real"

* Internal consistency check: the World Bank real series is expressed in
* constant 2010 dollars, so the two series must coincide in 2010.
qui summ oil_price_nominal if year == 2010
local n2010 = r(mean)
qui summ oil_price_real if year == 2010
local r2010 = r(mean)
capture assert abs(`n2010' - `r2010') < 1e-6
if _rc != 0 {
	di as error "WARNING: nominal and real differ in 2010 -- check the base year"
}

compress
save "`outfile'", replace

di as text "oilprices.dta written: " _N " obs, " ///
	%4.0f `=year[1]' "-" %4.0f `=year[_N]'
