* =======================================================================
* PROGRAM:			clean fred prices
* DATE:				14 July 2025
* =======================================================================

clear all


* =======================================================================
* Define paths
* =======================================================================

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
* Aggregate prices from different sources
* Pre-downloaded FRED CSVs in data/raw/aggregate/
* To update, download from https://fred.stlouisfed.org/series/SERIESID
* ======================================================================

* Load each FRED CSV, create quarterly date, save temp files
local series_list WPSID62 WPSFD49207 LCEAMN01USQ189S GDP GDPDEF NAGIGP01EZQ661S JPNGDPDEFQISMEI CCUSMA02EZQ618N CCUSMA02JPQ618N DGDSRG3M086SBEA GOODS0EU28M086NEST PITGCG02EZA661N WPSFD49201
local names_list  us_ppi_unproc us_ppi_finished us_manufw us_gdp us_gdpdf eu_gdpdf jp_gdpdf euxr jpxr us_pce_goods eu_cpi_goods eu_ppi_goods us_ppi_finishedtot

local n : word count `series_list'
local first = 1

forvalues i = 1/`n' {
	local series : word `i' of `series_list'
	local vname  : word `i' of `names_list'

	import delimited "data/raw/aggregate/`series'.csv", clear
	rename observation_date datestr
	rename `=lower("`series'")' `vname'
	gen date = qofd(date(datestr, "YMD"))
	format date %tq
	keep date `vname'
	collapse (mean) `vname', by(date)

	if `first' {
		save "data/temp/__fred_merged", replace
		local first = 0
	}
	else {
		merge 1:1 date using "data/temp/__fred_merged", nogen
		save "data/temp/__fred_merged", replace
	}
}

use "data/temp/__fred_merged", clear
erase "data/temp/__fred_merged.dta"

lab var us_ppi_unproc "USA PPI Unprocessed Goods for Intermediate Demand, 1982=100"
lab var us_ppi_finished "USA PPI Finished Goods, 1982=100"
lab var us_manufw "US Hourly Earnings in Manufacturing, National Currency"
lab var us_gdpdf "USA GDP Deflator 2012=100"
lab var us_gdp "USA GDP (Billions of Dollars)"
lab var eu_gdpdf "EU GDP Deflator 2015=100"
lab var jp_gdpdf "Japan GDP Deflator 2015=100"
lab var euxr "National Currency to USD XR: Average of Daily Rates for the EU"
lab var jpxr "National Currency to USD XR: Average of Daily Rates for Japan"
lab var us_pce_goods "USA PCE goods, 2012=100"
lab var eu_cpi_goods "EU CPI for goods, 2015=100"
lab var eu_ppi_goods "EU PPI for goods, 2015=100"
lab var us_ppi_finishedtot "USA PPI Final Demand, 1982=100"

save data/temp/fred_prices, replace
