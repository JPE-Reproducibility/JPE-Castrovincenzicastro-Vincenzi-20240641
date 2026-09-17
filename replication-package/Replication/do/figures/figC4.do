* =======================================================================
* PROGRAM:			Create Figure C.4: Effect of Material Prices on the Labor Share by 3-digit NAICS Sectors
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
* merge datasets and make the graph
* ======================================================================

use "data/dta/mainregfile.dta", clear 



merge m:1 naics3 using "data/raw/misc/naics3names12.dta", keep(1 3) nogen
tsset naics year
label var treat " "
tostring naics3, g(temp)
ereplace temp = concat(temp n3des)
label var naics3 ""
labmask naics3, values(temp)
cap drop temp*

ivreghdfe llabshr (i.naics3#c.treat = i.naics3#c.shift_share_ct) lw lpiinv  [aw=vadd_90] if inrange(year,1991,2016), absorb(naics year) cluster(naics) 
coefplot, omitted base drop(lw lpiinv) xline(0) levels(90) coeflabels(, interaction(" ")) yscale(alt) scale(1.2) xsize(9)  ///
	order(31* . 32* . 33* ) color(red*1.5) xtitle("Estimated Effect")

	
gr export "output/figures/figC4.png", replace width(2944) height(1472)
	

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
