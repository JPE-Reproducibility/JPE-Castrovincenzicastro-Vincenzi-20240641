* =======================================================================
* PROGRAM:			Create Figure 6: Commodity Cost Shock Measure
* DATE:				14 July 2025
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
* define variables and make graphs
* ======================================================================

use "data/dta/mainregfile.dta", clear

* Run regression to get coefficient and SE
qui reghdfe treat shift_share_ct [aw = vadd_90] if inrange(year,1991,2016), absorb(naics year) cluster(naics)
local b = _b[shift_share_ct]
local se = _se[shift_share_ct]
local b_str : di %5.3f `b'
local se_str : di %5.3f `se'

binscatter treat shift_share_ct [aw = vadd_90] if inrange(year,1991,2016), ///
	absorb(naics) controls(i.year) ///
	mcolors(gs10) lcolors(red*1.5) msymbols(Oh) ///
	ytitle(Log. Materials Price Index) ///
	xtitle(Commodity Price IV) ///
	scale(1.2) xsize(100) ysize(75) ///
	legend(off) ///
	note("Coeff. = `b_str' (`se_str')", position(5) ring(0) size(medium))

graph export "output/figures/fig6a.png", replace width(2142) height(1606)

keep if inrange(year,1991,2018)

collapse shift_share_ct [w=vadd_90], by(year)

tw (line shift_share_ct year, color(gs10))(scatter shift_share_ct year, color(red*1.5)), ///
	ytitle("") xtitle("Year") legend(off) yline(0, lcolor(black) lpattern()) ///
	scale(1.2) xsize(100) ysize(75)
graph export "output/figures/fig6b.png", replace width(2142) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
