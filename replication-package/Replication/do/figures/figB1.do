* =======================================================================
* PROGRAM:			Create Figure B.1: Comparison of BEA and NBER-CES
*					Manufacturing Aggregates (3-panel figure)
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
* Load BEA historical data
* ======================================================================

use "data/dta/bea_historical.dta", clear

* BEA intermediates = gross output - value added
gen ii = go_manuf - va_manuf

* ======================================================================
* Panel 1: Sales comparison (levels)
* ======================================================================

label var go_manuf  "BEA Gross Output"
label var nber_vship "NBER-CES Shipments"

tw (line go_manuf nber_vship year ///
		if !missing(go_manuf) & !missing(nber_vship), ///
		clcolor(navy cranberry) lstyle(p1 p5) lwidth(0.5 0.5)) ///
	, legend(pos(6)) xtitle("") ytitle("Millions $") ///
	scale(1.0) name(p1, replace) nodraw

* ======================================================================
* Panel 2: Intermediates comparison (levels)
* ======================================================================

label var ii  "BEA Intermediates"
label var nber_matcost "NBER-CES Materials"

tw (line ii nber_matcost year ///
		if !missing(ii) & !missing(nber_matcost), ///
		clcolor(navy cranberry) lstyle(p1 p5) lwidth(0.5 0.5)) ///
	, legend(pos(6)) xtitle("") ytitle("Millions $") ///
	scale(1.0) name(p2, replace) nodraw

* ======================================================================
* Panel 3: Payments to employees (levels)
* ======================================================================

label var comp_manuf   "BEA Labor Compensation"
label var nber_pay     "NBER-CES Wages"
label var wages_manuf  "BEA Wages and Salaries"

tw (line comp_manuf nber_pay wages_manuf year ///
		if !missing(comp_manuf) & !missing(nber_pay), ///
		clcolor(navy cranberry forest_green) lstyle(p1 p5 p3) ///
		lwidth(0.5 0.5 0.5) lpattern(solid solid dash)) ///
	, legend(pos(6)) xtitle("") ytitle("Millions $") ///
	scale(1.0) name(p3, replace) nodraw

* ======================================================================
* Combine panels
* ======================================================================

graph combine p1 p2 p3, cols(3) xsize(10) ysize(3.5) ///
	title("Comparison of BEA Industry Accounts and NBER-CES Panel", size(small))

gr export "output/figures/figB1.png", replace width(1800) height(630)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
