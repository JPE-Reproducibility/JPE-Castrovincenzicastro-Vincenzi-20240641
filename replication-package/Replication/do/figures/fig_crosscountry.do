* =======================================================================
* PROGRAM:          Create Figures F.1 and F.2: Cross-Country Binscatter; Materials Prices Across Countries
*                   Figure F.1: Cross-Country Binscatter
*                   Figure F.2: Materials Prices Across Countries
* DATE:             March 2026
* =======================================================================
clear all
set more off

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

use "$path/data/dta/crosscountry_panel.dta", clear


* ======================================================================
* FIGURE F.1a: First-stage scatter
* ======================================================================

di _n "=============================================="
di "Figure F.1a: First-stage scatter"
di "=============================================="

* Run first-stage regression to get coefficient and SE
qui reghdfe lii_pi shift_share_fx [aw=va_base], absorb(ci year) cluster(ci)
local fs_b : di %5.3f _b[shift_share_fx]
local fs_se : di %5.3f _se[shift_share_fx]

* Residualize for binscatter
qui reghdfe lii_pi [aw=va_base], absorb(ci year) resid
predict _y_r, resid
qui reghdfe shift_share_fx [aw=va_base], absorb(ci year) resid
predict _x_r, resid
qui sum lii_pi [aw=va_base]
replace _y_r = _y_r + r(mean)
qui sum shift_share_fx [aw=va_base]
replace _x_r = _x_r + r(mean)
xtile _xbin = _x_r [aw=va_base], nq(20)
preserve
    collapse (mean) _y_r _x_r [aw=va_base], by(_xbin)
    tw (scatter _y_r _x_r, mc(navy) msize(medsmall)) ///
       (lfit _y_r _x_r, lc(maroon) lw(medthick)), ///
       xtitle("Commodity Price IV (residualized)") ///
       ytitle("Log Materials Price Index (residualized)") ///
       legend(off) ///
       note("Coef = `fs_b' (`fs_se')", pos(11) ring(0) size(medium)) ///
       xsize(3.5) ysize(3)
    graph export "$path/output/figures/figF1a.png", replace width(1874) height(1606)
restore
drop _y_r _x_r _xbin


* ======================================================================
* FIGURE F.1b: Binscatter of log labor share vs treatment (OLS)
* ======================================================================

di _n "=============================================="
di "Figure F.1b: OLS Binscatter"
di "=============================================="

* Run OLS regression to get coefficient and SE
qui reghdfe llabshr treat [aw=va_base], absorb(ci year) cluster(ci)
local rf_b : di %6.4f _b[treat]
local rf_se : di %6.4f _se[treat]

* Residualize for binscatter
qui reghdfe llabshr [aw=va_base], absorb(ci year) resid
predict _y_r, resid
qui reghdfe treat [aw=va_base], absorb(ci year) resid
predict _x_r, resid
qui sum llabshr [aw=va_base]
replace _y_r = _y_r + r(mean)
qui sum treat [aw=va_base]
replace _x_r = _x_r + r(mean)
xtile _xbin = _x_r [aw=va_base], nq(20)
preserve
    collapse (mean) _y_r _x_r [aw=va_base], by(_xbin)
    tw (scatter _y_r _x_r, mc(navy) msize(medsmall)) ///
       (lfit _y_r _x_r, lc(maroon) lw(medthick)), ///
       xtitle("Materials Intensity × Log Materials Price (resid.)") ///
       ytitle("Log Labor Share (resid.)") ///
       legend(off) ///
       note("Coef = `rf_b' (`rf_se')", pos(11) ring(0) size(medium)) ///
       xsize(3.5) ysize(3)
    graph export "$path/output/figures/figF1b.png", replace width(1874) height(1606)
restore
drop _y_r _x_r _xbin


* ======================================================================
* FIGURE F.2: Materials prices across countries
* ======================================================================

di _n "=============================================="
di "Figure F.2: Materials Prices Across Countries"
di "=============================================="

* ---- Merge exchange rates (needed for Figure F.2b: USD conversion) ----
tempfile _fxtemp
preserve
    use "$path/data/dta/fx.dta", clear
    keep country year fx
    replace country = "EL" if country == "GR"
    replace country = "UK" if country == "GB"
    gen _fx2000 = fx if year == 2000
    bys country: egen fx_base = max(_fx2000)
    drop _fx2000
    bys country (year): replace fx_base = fx[1] if missing(fx_base)
    save "`_fxtemp'"
restore
merge m:1 country year using "`_fxtemp'", keep(mas mat) nogen

preserve
    * ---- Törnqvist chain index for pmat2pva at the country level ----
    * Step 1: Compute materials expenditure shares within each country-year
    bys country year: egen _ii_total = total(ii)
    gen _ii_share = ii / _ii_total

    * Step 2: Log changes at sector level
    sort country indcode year
    bys country indcode (year): gen _dlpmat = log(pmat2pva) - log(pmat2pva[_n-1]) ///
        if _n > 1 & year == year[_n-1] + 1

    * Step 3: Törnqvist weights: average of current and lagged intermediate-expenditure shares
    bys country indcode (year): gen _lag_share = _ii_share[_n-1] ///
        if _n > 1 & year == year[_n-1] + 1
    gen _tw = (_ii_share + _lag_share) / 2

    * Step 4: Weighted log change at country level
    gen _wdl = _tw * _dlpmat if !missing(_dlpmat) & !missing(_tw)
    bys country year: egen _agg_dlpmat = total(_wdl)
    * Mark years where we can compute the chain
    bys country year: egen _n_dl = total(!missing(_wdl))
    replace _agg_dlpmat = . if _n_dl == 0

    * Step 5: Collapse to country-year (carry total intermediate expenditure for cross-country weighting)
    collapse (first) _agg_dlpmat (first) _country_ii_total=_ii_total (first) fx fx_base, by(country year)

    * Step 6: Chain the log changes and normalize to 2000 = 1
    sort country year
    gen double _cum_lpmat = 0
    * Set cumulative log to 0 at year 2000, then chain forward and backward
    bys country (year): gen _yr2000 = _n if year == 2000
    bys country: egen _pos2000 = max(_yr2000)
    drop _yr2000

    * Chain forward from 2000
    bys country (year): replace _cum_lpmat = _cum_lpmat[_n-1] + _agg_dlpmat ///
        if _n > _pos2000 & !missing(_agg_dlpmat)
    * Chain backward from 2000
    gsort country -year
    bys country: replace _cum_lpmat = _cum_lpmat[_n-1] - _agg_dlpmat[_n-1] ///
        if year < 2000 & _n > 1 & !missing(_agg_dlpmat[_n-1])
    sort country year

    * For countries without year 2000, normalize to first available year
    bys country (year): replace _cum_lpmat = 0 if _n == 1 & missing(_pos2000)
    bys country (year): replace _cum_lpmat = _cum_lpmat[_n-1] + _agg_dlpmat ///
        if missing(_pos2000) & _n > 1 & !missing(_agg_dlpmat) & !missing(_cum_lpmat[_n-1])

    gen pmat_norm = exp(_cum_lpmat)
    drop _cum_lpmat _pos2000

    * Europe dummy (exclude US, JP, CA, KR — all non-European countries in sample)
    gen byte europe = !inlist(country, "US", "JP", "CA", "KR")

    * ---- Törnqvist chain for European aggregate (local currency) ----
    * Step 1: Country shares of total European nominal intermediate expenditure
    bys year: egen _eu_ii_total = total(_country_ii_total) if europe
    gen _eu_share = _country_ii_total / _eu_ii_total if europe

    * Step 2: Törnqvist weights across countries (average of current and lagged shares)
    sort country year
    bys country (year): gen _eu_lag_share = _eu_share[_n-1] ///
        if _n > 1 & year == year[_n-1] + 1 & europe
    gen _eu_tw = (_eu_share + _eu_lag_share) / 2 if europe

    * Step 3: Weighted average of country-level log changes
    gen _eu_wdl = _eu_tw * _agg_dlpmat if europe & !missing(_agg_dlpmat) & !missing(_eu_tw)
    bys year: egen _eu_agg_dl = total(_eu_wdl) if europe
    bys year: egen _eu_n_dl = total(!missing(_eu_wdl)) if europe
    replace _eu_agg_dl = . if _eu_n_dl == 0

    * Step 4: Chain the European aggregate, normalize to 2000 = 1
    * Chain directly on the dataset using DE's rows as reference
    sort country year
    gen double _eu_cum = 0 if country == "DE"

    * Forward from 2000: iterate through DE's years
    qui levelsof year if country == "DE" & year > 2000, local(fwd_years)
    foreach y of local fwd_years {
        qui sum _eu_agg_dl if country == "DE" & year == `y'
        local dl = r(mean)
        qui sum _eu_cum if country == "DE" & year == `=`y'-1'
        local prev = r(mean)
        if !missing(`dl') & !missing(`prev') {
            qui replace _eu_cum = `prev' + `dl' if country == "DE" & year == `y'
        }
    }
    * Backward from 2000
    qui levelsof year if country == "DE" & year < 2000, local(bwd_years)
    local bwd_sorted : list sort bwd_years
    local bwd_rev ""
    foreach y of local bwd_sorted {
        local bwd_rev `y' `bwd_rev'
    }
    foreach y of local bwd_rev {
        qui sum _eu_agg_dl if country == "DE" & year == `=`y'+1'
        local dl = r(mean)
        qui sum _eu_cum if country == "DE" & year == `=`y'+1'
        local nxt = r(mean)
        if !missing(`dl') & !missing(`nxt') {
            qui replace _eu_cum = `nxt' - `dl' if country == "DE" & year == `y'
        }
    }

    gen _pmat_eu_de = exp(_eu_cum) if country == "DE"
    bys year: egen pmat_eu = max(_pmat_eu_de)
    drop _eu_ii_total _eu_share _eu_lag_share _eu_tw _eu_wdl _eu_agg_dl _eu_n_dl _eu_cum _pmat_eu_de

    * ---- Törnqvist chain for European aggregate (FX-adjusted to USD) ----
    * Convert country-level log changes to USD: Δlog(p_local/fx) = Δlog(p_local) - Δlog(fx)
    gen fx_norm = fx / fx_base if !missing(fx_base)
    sort country year
    bys country (year): gen _dlfx = log(fx_norm) - log(fx_norm[_n-1]) ///
        if _n > 1 & year == year[_n-1] + 1 & europe & year >= 2001
    gen _agg_dlpmat_fx = _agg_dlpmat - _dlfx if europe & !missing(_dlfx) & !missing(_agg_dlpmat)

    * Re-weight with the same Törnqvist country intermediate-expenditure shares
    bys year: egen _eu_ii_total2 = total(_country_ii_total) if europe
    gen _eu_share2 = _country_ii_total / _eu_ii_total2 if europe
    bys country (year): gen _eu_lag_share2 = _eu_share2[_n-1] ///
        if _n > 1 & year == year[_n-1] + 1 & europe
    gen _eu_tw2 = (_eu_share2 + _eu_lag_share2) / 2 if europe
    gen _eu_wdl_fx = _eu_tw2 * _agg_dlpmat_fx if europe & !missing(_agg_dlpmat_fx) & !missing(_eu_tw2)
    bys year: egen _eu_agg_dl_fx = total(_eu_wdl_fx) if europe
    bys year: egen _eu_n_dl_fx = total(!missing(_eu_wdl_fx)) if europe
    replace _eu_agg_dl_fx = . if _eu_n_dl_fx == 0

    * Chain the FX-adjusted index forward from the 2000 baseline.
    sort country year
    gen double _eu_cum_fx = 0 if country == "DE" & year == 2000
    qui levelsof year if country == "DE" & year > 2000, local(fwd_years_fx)
    foreach y of local fwd_years_fx {
        qui sum _eu_agg_dl_fx if country == "DE" & year == `y'
        local dl = r(mean)
        qui sum _eu_cum_fx if country == "DE" & year == `=`y'-1'
        local prev = r(mean)
        if !missing(`dl') & !missing(`prev') {
            qui replace _eu_cum_fx = `prev' + `dl' if country == "DE" & year == `y'
        }
    }
    gen _pmat_eu_fx_de = exp(_eu_cum_fx) if country == "DE"
    bys year: egen pmat_eu_fx = max(_pmat_eu_fx_de)
    drop _dlfx _agg_dlpmat_fx _eu_ii_total2 _eu_share2 _eu_lag_share2 _eu_tw2 _eu_wdl_fx _eu_agg_dl_fx _eu_n_dl_fx _eu_cum_fx _pmat_eu_fx_de

    * Labels for scatter points
    gen lab_us = "USA" if country == "US"
    gen lab_jp = "Japan" if country == "JP"
    gen lab_de = "Germany" if country == "DE"
    gen lab_eu = "Europe" if country == "DE"

    * Country numeric ID for looping
    egen c = group(country)
    qui sum c
    local cmax = r(max)

    * Build gray spaghetti lines for all countries except US, JP, DE
    local linelist ""
    forvalues i = 1/`cmax' {
        local linelist "`linelist' (line pmat_norm year if c==`i' & !inlist(country, `"US"', `"JP"', `"DE"'), lw(0.2) lcolor(gray*0.5))"
    }

    * --- Panel (a): All countries, no FX-adjusted line ---
    tw `linelist' ///
        (line pmat_norm year if country=="US", lw(0.5) lcolor(navy*1.5)) ///
        (scatter pmat_norm year if country=="US" & year == 2017, msymbol(i) mlabel(lab_us) mlabc(navy*1.5) mlabpos(3)) ///
        (line pmat_norm year if country=="JP", lw(0.5) lcolor(red*1.5)) ///
        (scatter pmat_norm year if country=="JP" & year == 2017, msymbol(i) mlabel(lab_jp) mlabc(red*1.5) mlabpos(3)) ///
        (line pmat_norm year if country=="DE", lw(0.5) lcolor(green*1.5)) ///
        (scatter pmat_norm year if country=="DE" & year == 2018, msymbol(i) mlabel(lab_de) mlabc(green*1.5) mlabpos(4)) ///
        (line pmat_eu year if europe & country == "DE", lw(0.5) lcolor(purple*1.0)) ///
        (scatter pmat_eu year if country=="DE" & year == 2016, msymbol(i) mlabel(lab_eu) mlabc(purple*1.0) mlabpos(4)) ///
        , ///
        legend(off) xtitle("") ytitle("Materials/VA Price Ratio") ///
        xscale(range(1995 2020)) xlabel(1995(5)2020) ///
        yscale(range(0.5 2)) ylabel(0.5(0.5)2) ///
        yline(1, lc(gs12) lw(thin) lpattern(solid)) ///
        xsize(3.5) ysize(3)
    graph export "$path/output/figures/figF2a.png", replace width(1874) height(1606)

    * --- Panel (b): Europe average vs FX-adjusted ---
    tw (line pmat_eu year if europe & country == "DE", lw(0.7) lcolor(purple*1.0)) ///
       (line pmat_eu_fx year if europe & country == "FR" & year >= 2000, lw(0.7) lcolor(purple*1.0) lpattern(dash)) ///
       , ///
       legend(order(1 "Europe (local)" 2 "Europe (USD)") pos(11) ring(0) cols(1) size(small)) ///
       xtitle("") ytitle("Materials/VA Price Ratio") ///
       xscale(range(1995 2020)) xlabel(1995(5)2020) ///
       yscale(range(0.75 2.25)) ylabel(0.75(0.25)2.25) ///
       yline(1, lc(gs12) lw(thin) lpattern(solid)) ///
       xsize(3.5) ysize(3)
    graph export "$path/output/figures/figF2b.png", replace width(1874) height(1606)
restore

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
