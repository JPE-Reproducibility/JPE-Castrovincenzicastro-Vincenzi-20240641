* =======================================================================
* PROGRAM:			Create Figure C.3: The Effect of Commodity Intensity on Materials-to-Labor Expenditure Ratio and on the Labor Share
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

keep if inrange(year,1991,2016)

* Equation (C.1) specifies theta^comm_{j,1997}: a fixed 1997 industry
* characteristic interacted with year dummies
bysort naics (year): gen double share_ct_97 = share_ct if year == 1997
bysort naics (year): ereplace share_ct_97 = max(share_ct_97)

* Estimate Equation (C.1) from the empirical appendix
reghdfe llabshr c.share_ct_97##ib1997.year [aw=vadd_90] if inrange(year,1991,2016), absorb(naics) cluster(naics)

* Initialize variables
gen beta_hat = .
gen ub = .
gen lb = .

* Set beta_hat to 0 for baseline year 1997
replace beta_hat = 0 if year == 1997

* Loop over years excluding baseline 1997 and get coefficients
forvalues y = 1991/2016 {
    if `y' != 1997 {
        local coefname = "c.share_ct_97#`y'.year"

                replace beta_hat = _b[`coefname'] if year == `y'
                replace lb = _b[`coefname'] - 1.645 * _se[`coefname'] if year == `y'
                replace ub = _b[`coefname'] + 1.645 * _se[`coefname'] if year == `y'
            }
        }


twoway (rcap lb ub year, lwidth(medium) lcolor(gray*1.3)) (scatter beta_hat year, msize(medium) color(gray*0.8) msymbol(sh)), legend(lab(1 "90% C.I") lab(2 "Estimated Coefficient")) ytitle(Log. Labor Share) xtitle("Year") yline(0, lcolor(gray*1.3) lpattern(shortdash)) legend(pos(6) col(2))

graph export "output/figures/figC3b.png", replace width(2676) height(1606)


* Initialize variables
replace beta_hat = .
replace ub = .
replace lb = .

* Set beta_hat to 0 for baseline year 1997
replace beta_hat = 0 if year == 1997

reghdfe lmat2lab c.share_ct_97##ib1997.year [aw=vadd_90] if inrange(year,1991,2016), absorb(naics) cluster(naics)

* Loop over years excluding baseline 1997 and get coefficients
forvalues y = 1991/2016 {
    if `y' != 1997 {
        local coefname = "c.share_ct_97#`y'.year"

                replace beta_hat = _b[`coefname'] if year == `y'
                replace lb = _b[`coefname'] - 1.645 * _se[`coefname'] if year == `y'
                replace ub = _b[`coefname'] + 1.645 * _se[`coefname'] if year == `y'
            }
        }


twoway (rcap lb ub year, lwidth(medium) lcolor(gray*1.3)) (scatter beta_hat year, msize(medium) color(gray*0.8) msymbol(sh)), legend(lab(1 "90% C.I") lab(2 "Estimated Coefficient")) ytitle(Log. Materials to Labor) xtitle("Year") yline(0, lcolor(gray*1.3)) legend(pos(6) col(2))

graph export "output/figures/figC3a.png", replace width(2676) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
