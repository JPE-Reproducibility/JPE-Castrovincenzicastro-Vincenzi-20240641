* =======================================================================
* PROGRAM:			Create Figure 5: The Relationship Between Material Prices and Industry Outcomes
*					Panel A: Long-difference scatters (2000-2010)
*					Panel B: Panel binscatters (1991-2016)
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
* load data
* ======================================================================

use "data/dta/mainregfile.dta", clear

* ======================================================================
* PANEL A: Long-difference scatters (2000-2010)
* ======================================================================

* construct 2000 materials intensity for long-difference treatment
bys naics (year): gen mat2va_00 = mat2va if year == 2000
bys naics (year): ereplace mat2va_00 = max(mat2va_00)

* construct 2000 value added for weights
bys naics (year): gen vadd_00 = vadd if year == 2000
bys naics (year): ereplace vadd_00 = max(vadd_00)

gen treat_ld = mat2va_00 * lpimat

tsset naics year

foreach var in llabshr lmat2lab treat_ld {
	gen d_10_`var' = `var' - l10.`var'
}

* regression for coefficients (VA-weighted) and fitted line
foreach outcome of varlist d_10_llabshr d_10_lmat2lab {

	reg `outcome' d_10_treat_ld [aw=vadd_00] if year == 2010

	local bb : display %6.4f _b[d_10_treat_ld]
	local se_bb : display %6.4f _se[d_10_treat_ld]

	* fitted values for weighted regression line
	cap drop _yhat_ld
	predict _yhat_ld if year == 2010, xb

	if "`outcome'" == "d_10_llabshr" {
		local name "a"
		local ytxt "Log Change in Labor Share"
		local x_cord = 3
		local y_cord = 0.5
		local y_cord_se = 0.4
	}
	if "`outcome'" == "d_10_lmat2lab" {
		local name "b"
		local ytxt "Log Change in Materials/Labor Expenditure"
		local x_cord = 3
		local y_cord = -0.5
		local y_cord_se = -0.6
	}
	local x_cord_se = `x_cord'

	tw (scatter `outcome' d_10_treat_ld if year == 2010, mc(gs10) msymbol(circle_hollow)) ///
	   (line    _yhat_ld d_10_treat_ld if year == 2010, sort lc(red*1.5)), ///
	   legend(off) ///
	   ytitle("`ytxt' (2000-2010)") ///
	   xtitle("Materials Intensity x {&Delta} Log Materials Price Index (2000-2010)") ///
	   text(`y_cord' `x_cord' "β = `bb'" "(`se_bb')", size(small)) ///
	   xsize(6) ysize(4) scale(0.9)

	graph export "output/figures/fig5`name'_ld.png", replace width(2410) height(1606)
}

* ======================================================================
* PANEL B: Panel binscatters (1991-2016)
* ======================================================================

* residualize using industry and year FE, weighted by vadd_90
qui areg llabshr i.year [aw = vadd_90] if inrange(year,1991,2016), abs(naics)
cap drop llabshr_res
predict llabshr_res, residuals

qui areg lmat2lab i.year [aw = vadd_90] if inrange(year,1991,2016), abs(naics)
cap drop lmat2lab_res
predict lmat2lab_res, residuals

qui areg treat i.year [aw = vadd_90] if inrange(year,1991,2016), abs(naics)
cap drop lpimat_res
predict lpimat_res, residuals

qui sum treat [aw = vadd_90] if inrange(year,1991,2016), det
replace lpimat_res = lpimat_res + r(mean)

qui sum llabshr [aw = vadd_90] if inrange(year,1991,2016), det
replace llabshr_res = llabshr_res + r(mean)

qui sum lmat2lab [aw = vadd_90] if inrange(year,1991,2016), det
replace lmat2lab_res = lmat2lab_res + r(mean)

* run regressions on residualized data for coefficients
reg llabshr_res lpimat_res [aw = vadd_90] if inrange(year,1991,2016), cluster(naics)
local bb_a : display %6.4f _b[lpimat_res]
local se_a : display %6.4f _se[lpimat_res]

reg lmat2lab_res lpimat_res [aw = vadd_90] if inrange(year,1991,2016), cluster(naics)
local bb_b : display %6.4f _b[lpimat_res]
local se_b : display %6.4f _se[lpimat_res]

* save binned data for both panels
binscatter llabshr_res lpimat_res [aw = vadd_90] if inrange(year,1991,2016), ///
	nquantiles(50) savedata("output/figures/_fig5a_bins") replace

binscatter lmat2lab_res lpimat_res [aw = vadd_90] if inrange(year,1991,2016), ///
	nquantiles(50) savedata("output/figures/_fig5b_bins") replace

* Panel B(a): Labor Share — coef at (0.5, -1.2)
preserve
import delimited "output/figures/_fig5a_bins.csv", clear
tw (scatter llabshr_res lpimat_res, mc(gs10) msymbol(Oh)) ///
   (lfit    llabshr_res lpimat_res, lc(red*1.5)), ///
   legend(off) ///
   ytitle("Log Labor Share") ///
   xtitle("Materials Intensity x Log Materials Price Index") ///
   text(-1.2 0.5 "β = `bb_a'" "(`se_a')", size(small)) ///
   xsize(6) ysize(4) scale(0.9)
graph export "output/figures/fig5a.png", replace width(2410) height(1606)
restore
cap erase "output/figures/_fig5a_bins.csv"
cap erase "output/figures/_fig5a_bins.do"

* Panel B(b): Material-to-Labor Expenditure Ratio — coef at (-1, 1.4)
preserve
import delimited "output/figures/_fig5b_bins.csv", clear
tw (scatter lmat2lab_res lpimat_res, mc(gs10) msymbol(Oh)) ///
   (lfit    lmat2lab_res lpimat_res, lc(red*1.5)), ///
   legend(off) ///
   ytitle("Log Material-to-Labor Expenditure") ///
   xtitle("Materials Intensity x Log Materials Price Index") ///
   text(1.4 -1 "β = `bb_b'" "(`se_b')", size(small)) ///
   xsize(6) ysize(4) scale(0.9)
graph export "output/figures/fig5b.png", replace width(2410) height(1606)
restore
cap erase "output/figures/_fig5b_bins.csv"
cap erase "output/figures/_fig5b_bins.do"

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
