* =======================================================================
* PROGRAM:			Create Figure C.1: U.S. Aggregate Labor Share
*					(four measures)
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

* Use the paper's graph style, then restore the caller's settings.
quietly graph set window
local _ls_style_saved_font `"`r(fontface)'"'
local _ls_style_saved_scheme `"`c(scheme)'"'
capture noisily {
do "do/figures/graph_style.do"

* ======================================================================
* Load aggregate labor share data (produced by agg_labour_shares.do)
* ======================================================================

use data/dta/agglabshr, clear
gen year = yofd(dofq(date))
collapse (mean) ls_nipa_gr ls_nipa_nfcorp_gross ls_fernald ls_bls_nonfarm ls_mean, by(year)

label var ls_nipa_gr "NIPA data, based on Gomme and Rupert (2004)"
label var ls_nipa_nfcorp_gross "NIPA data, nonfinancial-corporations"
label var ls_fernald "Data from Fernald (2014)"
label var ls_bls_nonfarm "BLS non-farm business sector"
label var ls_mean "Mean across all sources"

* ======================================================================
* Plot
* ======================================================================

line ls_mean ls_nipa_gr ls_nipa_nfcorp_gross ls_fernald ls_bls_nonfarm year ///
	if inrange(year, 1970, 2024), ///
	legend(pos(6) cols(2) size(vsmall)) ///
	lc(navy*1.5 cranberry*1.3 forest_green*1.3 orange*1.5 dkorange*1.3) ///
	lwidth(thick medthin medthin medthin medthin) ///
	lpattern(solid dash shortdash longdash dash_dot) ///
	xtitle("") ytitle("Aggregate US labor share") ///
	scale(0.9) xsize(5) ysize(3) ///
	graphregion(color(white))

gr export "output/figures/figC1.png", replace width(2676) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
