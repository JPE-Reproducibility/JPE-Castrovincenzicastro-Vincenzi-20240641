* =======================================================================
* PROGRAM:			Create Figure 1: Trends in the Aggregate Labor Share and Relative Price of Materials
* DATE:				March 2026
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

* Use the paper's graph style, then restore the caller's settings.
quietly graph set window
local _ls_style_saved_font `"`r(fontface)'"'
local _ls_style_saved_scheme `"`c(scheme)'"'
capture noisily {
do "do/figures/graph_style.do"

* ======================================================================
* Part 1: Labor share and FRED price series
* ======================================================================

use data/dta/agglabshr, clear
qui merge 1:1 date using data/temp/fred_prices.dta, nogen

gen year = yofd(dofq(date))
collapse (mean) ls* eu* jp* us* , by(year)

tempfile fig1_data
save "`fig1_data'"

* ======================================================================
* Part 2: Import WPSID61
*
* WPSID61 = "Processed Goods for Intermediate Demand" (1982=100)
* WPSID62 = "Unprocessed Goods for Intermediate Demand" (1982=100)
*           Already in FRED data as us_ppi_unproc.
* ======================================================================

import delimited "data/raw/aggregate/WPSID61.csv", clear
gen year = year(date(observation_date, "YMD"))
keep year wpsid61
rename wpsid61 ppi_processed
tempfile processed
save "`processed'"

* ======================================================================
* Part 3: Merge and construct relative prices
* ======================================================================

use "`fig1_data'", clear
merge 1:1 year using "`processed'", nogen

* us_ppi_unproc = WPSID62 = "Unprocessed Goods for Intermediate Demand"
* Deflate both PPI series by PCE for goods
gen rp_wpsid62 = us_ppi_unproc / us_pce_goods * 100
gen rp_wpsid61 = ppi_processed / us_pce_goods * 100

* Normalize all to 2000 = 100
foreach v in rp_wpsid62 rp_wpsid61 {
	summ `v' if year == 2000, meanonly
	replace `v' = `v' / r(mean) * 100
}

* ======================================================================
* Part 4: Plot
* ======================================================================

tw (line ls_mean year if inrange(year,1970,2024), ///
		color(navy*1.5) lwidth(0.5) ) ///
   (line rp_wpsid62 year if inrange(year,1970,2024), ///
		yaxis(2) color(cranberry*1.2) lwidth(0.5) lpattern(dash) ) ///
   (line rp_wpsid61 year if inrange(year,1970,2024), ///
		yaxis(2) color(forest_green*1.2) lwidth(0.5) lpattern(shortdash_dot) ) ///
   , legend(pos(6) rows(2) size(small) ///
		label(1 "Mean aggregate US labor share") ///
		label(2 "PPI unprocessed goods (WPSID62) / PCE goods") ///
		label(3 "PPI processed goods (WPSID61) / PCE goods") ) ///
	xtitle("") ///
	ytitle("Labor share", axis(1)) ///
	ytitle("Relative price (2000 = 100)", axis(2)) ///
	xlabel(1970(10)2020) ///
	yscale(range(80 220) axis(2)) ylabel(80(35)220, axis(2)) ///
	scale(0.9) xsize(6) ysize(3.5)

gr export "output/figures/fig1.png", replace width(2754) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
