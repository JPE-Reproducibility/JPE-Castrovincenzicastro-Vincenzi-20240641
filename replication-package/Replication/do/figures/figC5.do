* =======================================================================
* PROGRAM:			Create Figure C.5: Dispersion in the Growth of Residual Materials Prices
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
* define variables and make the graph
* ======================================================================

use "data/dta/mainregfile.dta",clear

global w vadd 

cap drop lpimat_resid
reghdfe lpimat lw lpiinv [aw=$w], absorb(naics year) resid
predict lpimat_resid, resid

cap drop dlpimat*
bys naics (year): gen dlpimat = (lpimat_resid[_n+1] - lpimat_resid[_n-1])/3

gcollapse (var) dlpimat [w=$w], by(year) 
line dlpimat year, xline(1970 1981 1997, lcolor(gray) lpattern(shortdash)) xtitle("") ytitle("Variance of changes in material prices") lc(black) xsize(5) ysize(2.5) yscale(range(0 0.003)) ylabel(0(0.001)0.003)

gr export "output/figures/figC5.png", replace width(2944) height(1472)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
