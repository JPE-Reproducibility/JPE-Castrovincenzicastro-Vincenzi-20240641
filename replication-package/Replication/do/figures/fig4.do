* =======================================================================
* PROGRAM:			Create Figure 4: Cost reallocation from labor to materials
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

use "data/dta/BEA-BLS_klems_clean.dta"

keep if inlist(substr(ind_code,1,2),"31","32","33")
drop if year > 2019

* aggregate compensation 
gen WL = labor_nocol_compensation + labor_col_compensation
gen M = materials_compensation + energy_compensation

* renaming
rename value_added VA
rename gross_output GO
rename materials_compensation MAT_noEE
rename energy_compensation EE
rename service_compensation SERV


* prices
gen pMAT_noEE = MAT_noEE/materials_quantity
gen pEE = EE/energy_quantity
gen pVA = VA/va_quantity

* --- Step 1: Within-sector Tornqvist: materials + energy composite price ---
sort ind year
gen mshr = MAT_noEE/(MAT_noEE+EE)
bys ind (year): gen mshr_L = mshr[_n-1]
gen w_inner = (mshr + mshr_L) / 2

bys ind (year): gen dlog_pMAT = log(pMAT_noEE) - log(pMAT_noEE[_n-1]) if _n > 1
bys ind (year): gen dlog_pEE  = log(pEE) - log(pEE[_n-1]) if _n > 1

gen dlog_pM_sector = w_inner * dlog_pMAT + (1 - w_inner) * dlog_pEE

* Cumulate to log level within sector
bys ind (year): gen lp_M = 0 if _n == 1
bys ind (year): replace lp_M = lp_M[_n-1] + dlog_pM_sector if _n > 1 & !missing(dlog_pM_sector)

* --- Step 2: Aggregate across sectors using Tornqvist with M expenditure shares ---
bys year: egen M_total = total(M)
gen M_shr = M / M_total
bys ind (year): gen M_shr_L = M_shr[_n-1]
gen w_outer = (M_shr + M_shr_L) / 2

gen dlog_pM_weighted = w_outer * dlog_pM_sector

* --- VA price: aggregate across sectors ---
bys ind (year): gen dlog_pVA = log(pVA) - log(pVA[_n-1]) if _n > 1
bys year: egen VA_total = total(VA)
gen VA_shr = VA / VA_total
bys ind (year): gen VA_shr_L = VA_shr[_n-1]
gen w_VA = (VA_shr + VA_shr_L) / 2
gen dlog_pVA_weighted = w_VA * dlog_pVA

* --- Step 3: Collapse and chain ---
collapse (sum) dlog_pM_weighted dlog_pVA_weighted (rawsum) GO VA WL M, by(year)
sort year

* Cumulate aggregate log prices
gen lp_M_agg = 0
replace lp_M_agg = lp_M_agg[_n-1] + dlog_pM_weighted if _n > 1 & !missing(dlog_pM_weighted)

gen lp_VA_agg = 0
replace lp_VA_agg = lp_VA_agg[_n-1] + dlog_pVA_weighted if _n > 1 & !missing(dlog_pVA_weighted)

* generate more variables
gen labshr = WL/VA
gen WL2M = WL/M
gen lpm2p = lp_M_agg - lp_VA_agg

tw 	(line labshr 	year, lc(navy*1.5) lw(0.4)) ///
	(line WL2M 	year, lc(red*1.5)  lw(0.4) yaxis(2) lpattern(dash)) ///
	, ///
	xtitle("") ytitle("Labor share of value-added", axis(1)) ytitle("Labor compensation to expenditure on materials", axis(2)) ///
	legend( pos(6) label(1 "Labor share of value-added") label(2 "Labor compensation to expenditure on materials")) ///
	yscale(range(0.45 .) axis(1)) ylabel(0.45(0.05)0.65, axis(1)) ///
	xsize(100) ysize(80) scale(1.0)  xlabel(1990(10)2020)
	
graph export "output/figures/fig4a.png", replace width(2008) height(1606)

tw 	(line lpm2p 	year, lc(navy*1.5) lw(0.4)) ///
	(line WL2M 	year, lc(red*1.5)  lw(0.4) yaxis(2) lpattern(dash)) ///
	, ///
	xtitle("") ytitle("Log. relative price of materials", axis(1)) ytitle("Labor compensation to expenditure on materials", axis(2)) ///
	legend( pos(6) label(1 "Log. materials price / VA price") label(2 "Labor compensation to expenditure on materials")) ///
	xsize(100) ysize(80) scale(1.0) xlabel(1990(10)2020)
	
graph export "output/figures/fig4b.png", replace width(2008) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
