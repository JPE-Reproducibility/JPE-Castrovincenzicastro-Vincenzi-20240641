* =======================================================================
* PROGRAM:			Create Figure 3: Labor Shares and Material Price Shocks Across U.S. Sectors
* DATE:				14 July 2025 (updated March 2026)
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
* Load and prepare data
* ======================================================================

use "data/dta/BEA-BLS_klems_clean.dta", clear
drop if year > 2019

* Drop government, agriculture, and utilities sectors
drop if ind_code == "GF" | missing(ind_code)
drop if substr(ind_code, 1, 1) == "1"
drop if ind_code == "22"
encode ind_code, gen(ind_id)


* Create material input and output aggregates
gen M  = materials_compensation + energy_compensation
gen WL = labor_nocol_compensation + labor_col_compensation
gen VA = value_added
gen GO = gross_output
gen labshr = WL / VA


* ======================================================================
* Industry-level Tornqvist chain price index for materials + energy
* ======================================================================

* Implicit prices
gen pMAT = materials_compensation / materials_quantity
gen pEE  = energy_compensation / energy_quantity
gen pVA  = VA / va_quantity

* Log price changes
sort ind year
bys ind (year): gen dlog_pMAT = log(pMAT) - log(pMAT[_n-1]) if _n > 1
bys ind (year): gen dlog_pEE  = log(pEE)  - log(pEE[_n-1])  if _n > 1

* Tornqvist weights: average of current and lagged expenditure shares
gen mshr = materials_compensation / M
bys ind (year): gen mshr_L = mshr[_n-1]
gen w_torn = (mshr + mshr_L) / 2

* Composite log price change and cumulate
gen dlog_pM = w_torn * dlog_pMAT + (1 - w_torn) * dlog_pEE
bys ind (year): gen lpM_ind = sum(dlog_pM)
bys ind (year): replace lpM_ind = 0 if _n == 1

* Log VA price
gen lpVA = log(pVA)


* ======================================================================
* Define material intensity groups (M/VA in 1997)
* ======================================================================

gen M2VA = M / VA
xtile matintense = M2VA [w=VA] if year == 1997, n(2)
replace matintense = matintense - 1
bys ind_code: ereplace matintense = max(matintense)


* ======================================================================
* Panel (c): Binscatter
* ======================================================================

bys ind (year): gen deltalpM_ind = lpM_ind - lpM_ind[1]
gen M2VA_1997 = M / VA if year == 1997
bys ind (year): ereplace M2VA_1997 = max(M2VA_1997)
gen E = M2VA_1997 * deltalpM_ind
gen llabshr = log(labshr)

* Run regression to get coefficient and SE
reghdfe llabshr E lpVA, absorb(ind year) cluster(ind)
local b : display %5.3f _b[E]
local se : display %5.3f _se[E]

binscatter2 llabshr E, absorb(ind year) control(lpVA)  ///
	xtitle("1997 Materials Intensity × Log Change in Material Prices") ///
	ytitle("Log Labor Share") ///
	text(-.63 .15 "β = `b' (`se')", size(small) placement(c)) ///
	xsize(100) ysize(100) scale(0.9)

graph export "output/figures/fig3c.png", replace width(1606) height(1606)


* ======================================================================
* Panels (a) and (b): Group-level Tornqvist price aggregation
*
* Tornqvist across industries within each group, using the industry-level
* composite materials+energy price index (dlog_pM) weighted by industry M.
* ======================================================================

preserve

	* --- Tornqvist aggregation within each group ---
	forvalues g = 0/1 {
		bysort year: egen tot_M_`g' = total(M) if matintense == `g'
		gen share_`g' = M / tot_M_`g' if matintense == `g'
		sort ind_id year
		by ind_id: gen share_`g'_L = share_`g'[_n-1]
		gen w_`g' = (share_`g' + share_`g'_L) / 2
		gen c_`g' = w_`g' * dlog_pM if matintense == `g'
		bysort year: egen dlog_pM_`g' = total(c_`g')
	}

	* Collapse to year level and chain
	collapse (first) dlog_pM_0 dlog_pM_1, by(year)
	sort year

	forvalues g = 0/1 {
		gen deltalpM_`g' = sum(dlog_pM_`g')
		replace deltalpM_`g' = 0 if year == 1987
	}

	keep year deltalpM_*
	tempfile group_prices
	save "`group_prices'"

restore

* --- Collapse labor share by group ---
gcollapse (rawsum) VA WL, by(year matintense)
gen LS = WL / VA
bys matintense (year): gen deltalLS = LS - LS[1]

* Merge Tornqvist group prices
reshape wide VA WL LS deltalLS, i(year) j(matintense)
merge 1:1 year using "`group_prices'", nogen
reshape long VA WL LS deltalLS deltalpM_, i(year) j(matintense)
rename deltalpM_ deltalpM

* Plot: Material Price Change
tw (line deltalpM year if matintense, lc(navy*1.5) lw(0.4)) ///
   (line deltalpM year if !matintense, lc(red*1.5) lw(0.4) lpattern(dash)), ///
   xtitle("") ytitle("Log. change in material prices") ///
   legend(ring(0) pos(5) label(1 "Materials-intensive sectors") label(2 "Other sectors")) ///
   xsize(100) ysize(100) scale(0.9) xlabel(1990(10)2020)
graph export "output/figures/fig3a.png", replace width(1606) height(1606)

* Plot: Labor Share Change
tw (line deltalLS year if matintense, lc(navy*1.5) lw(0.5)) ///
   (line deltalLS year if !matintense, lc(red*1.5) lw(0.5) lpattern(dash)), ///
   xtitle("") ytitle("Change in labor share from 1987 in p.p.") ///
   legend(ring(0) pos(7) label(1 "Materials-intensive sectors") label(2 "Other sectors")) ///
   xsize(100) ysize(100) scale(0.9) xlabel(1990(10)2020)
graph export "output/figures/fig3b.png", replace width(1606) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
