* =======================================================================
* PROGRAM:            Create Figure 7: Structural Interpretation and Counterfactual Labor Share
* DESCRIPTION:        Panel (a): sigma-pi relationship implied by beta
*                     Panel (b): counterfactual labor share
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
* Panel (a): Implied relationship between sigma and profit share pi
* ======================================================================

local sigma_min = 0
local sigma_max = 0.6

use "data/dta/mainregfile.dta", clear

keep if inrange(year,1991,2016)
keep if !missing(shift_share_ct)

gen lVA2R = log(vadd / vship)
gen lM2VA = log(matcost / vadd)

local controls lw lpiinv prodshr lcap2lab impen impen_china
local fe naics year

* Labor-share moments used for the two loci
ivreghdfe llabshr (treat = shift_share_ct) `controls' [aw=vadd_90], ///
    absorb(`fe') cluster(naics) nocons
local beta    = _b[treat]
local beta_se = _se[treat]
local ab_nt   = -`beta'

* Compute tau_bar
qui summ mat2va_90 if e(sample) [aw=vadd_90]
local tau_bar = r(mean)
local s_bar   = `tau_bar' / (1 + `tau_bar')

ivreghdfe llabshr (treat = shift_share_ct) `controls' [aw=vadd_90], ///
    absorb(`fe' i.naics#c.year) cluster(naics) nocons
local beta9    = _b[treat]
local beta9_se = _se[treat]
local ab_tr    = -`beta9'

* Auxiliary moments from log(M/Y)
ivreghdfe lM2VA (lpimat = shift_share_ct) `controls' [aw=vadd_90], ///
    absorb(`fe') cluster(naics) nocons
local eps_my_nt = _b[lpimat]

ivreghdfe lM2VA (lpimat = shift_share_ct) `controls' [aw=vadd_90], ///
    absorb(`fe' i.naics#c.year) cluster(naics) nocons
local eps_my_tr = _b[lpimat]

* Auxiliary moments from log(Y/R)
ivreghdfe lVA2R (lpimat = shift_share_ct) `controls' [aw=vadd_90], ///
    absorb(`fe') cluster(naics) nocons
local eps_yr_nt = _b[lpimat]

ivreghdfe lVA2R (lpimat = shift_share_ct) `controls' [aw=vadd_90], ///
    absorb(`fe' i.naics#c.year) cluster(naics) nocons
local eps_yr_tr = _b[lpimat]

* Intersections implied by log(M/Y)
local A_my_nt     = `eps_my_nt' + `ab_nt' * `tau_bar'
local sigma_my_nt = 1 - `A_my_nt'
local mu_my_nt    = 1 + `ab_nt' / `A_my_nt'
local pi_my_nt    = 1 - 1 / `mu_my_nt'

local A_my_tr     = `eps_my_tr' + `ab_tr' * `tau_bar'
local sigma_my_tr = 1 - `A_my_tr'
local mu_my_tr    = 1 + `ab_tr' / `A_my_tr'
local pi_my_tr    = 1 - 1 / `mu_my_tr'

* Intersections implied by log(Y/R)
local A_yr_nt     = -`eps_yr_nt' / `s_bar' + `ab_nt' * `tau_bar'
local sigma_yr_nt = 1 - `A_yr_nt'
local mu_yr_nt    = 1 + `ab_nt' / `A_yr_nt'
local pi_yr_nt    = 1 - 1 / `mu_yr_nt'

local A_yr_tr     = -`eps_yr_tr' / `s_bar' + `ab_tr' * `tau_bar'
local sigma_yr_tr = 1 - `A_yr_tr'
local mu_yr_tr    = 1 + `ab_tr' / `A_yr_tr'
local pi_yr_tr    = 1 - 1 / `mu_yr_tr'

clear
set obs 1000
gen sigma = `sigma_min' + (_n - 1) * (`sigma_max' - `sigma_min') / 999

* Labor-share loci: beta = pi/(1-pi) * (sigma - 1)
* Point estimates
gen pw_nt = -`beta' / (1 - sigma)
gen pi_nt = pw_nt / (1 + pw_nt)
replace pi_nt = . if pi_nt <= 0 | pi_nt >= 1

gen pw_tr = -`beta9' / (1 - sigma)
gen pi_tr = pw_tr / (1 + pw_tr)
replace pi_tr = . if pi_tr <= 0 | pi_tr >= 1

* 95% confidence intervals: beta +/- 1.96*SE
gen pw_nt_lo = -(`beta' - 1.96*`beta_se') / (1 - sigma)
gen pi_nt_lo = pw_nt_lo / (1 + pw_nt_lo)
replace pi_nt_lo = . if pi_nt_lo <= 0 | pi_nt_lo >= 1

gen pw_nt_hi = -(`beta' + 1.96*`beta_se') / (1 - sigma)
gen pi_nt_hi = pw_nt_hi / (1 + pw_nt_hi)
replace pi_nt_hi = . if pi_nt_hi <= 0 | pi_nt_hi >= 1

gen pw_tr_lo = -(`beta9' - 1.96*`beta9_se') / (1 - sigma)
gen pi_tr_lo = pw_tr_lo / (1 + pw_tr_lo)
replace pi_tr_lo = . if pi_tr_lo <= 0 | pi_tr_lo >= 1

gen pw_tr_hi = -(`beta9' + 1.96*`beta9_se') / (1 - sigma)
gen pi_tr_hi = pw_tr_hi / (1 + pw_tr_hi)
replace pi_tr_hi = . if pi_tr_hi <= 0 | pi_tr_hi >= 1

qui sum pi_nt if !missing(pi_nt), meanonly
local ymax = r(max)
qui sum pi_tr if !missing(pi_tr), meanonly
local ymax = max(`ymax', r(max))
local ymax = max(`ymax', `pi_my_nt', `pi_my_tr', `pi_yr_nt', `pi_yr_tr')
local ymax = ceil(`ymax' * 10) / 10 + 0.05

twoway (rarea pi_nt_lo pi_nt_hi sigma, sort color(cranberry%15) lwidth(none)) ///
       (rarea pi_tr_lo pi_tr_hi sigma, sort color(navy%15) lwidth(none)) ///
       (line pi_nt sigma if !missing(pi_nt), ///
        sort lcolor(cranberry) lwidth(medthick)) ///
       (line pi_tr sigma if !missing(pi_tr), ///
        sort lcolor(navy) lwidth(medthick) lpattern(dash)) ///
       (scatteri `pi_my_nt' `sigma_my_nt', ///
        msymbol(D) msize(medium) mcolor(cranberry) mlcolor(cranberry)) ///
       (scatteri `pi_my_tr' `sigma_my_tr', ///
        msymbol(D) msize(medium) mcolor(navy) mlcolor(navy)) ///
       (scatteri `pi_yr_nt' `sigma_yr_nt', ///
        msymbol(star) msize(large) mcolor(cranberry) mlcolor(cranberry)) ///
       (scatteri `pi_yr_tr' `sigma_yr_tr', ///
        msymbol(star) msize(large) mcolor(navy) mlcolor(navy)) ///
       , ///
       yscale(range(0.05 `ymax')) ylabel(0.05(0.1)`ymax') ///
       xscale(range(`sigma_min' `sigma_max')) xlabel(`sigma_min'(0.1)`sigma_max') ///
       ytitle("Profit share of sales ({&pi})") ///
       xtitle("Elasticity of substitution {&sigma}") ///
       legend(order(3 "({&sigma},{&pi}) combinations implied by Col. 8" ///
                    4 "({&sigma},{&pi}) combinations implied by Col. 9" ///
                    5 "({&sigma},{&pi}) from log(M/V) elasticity (Col. 8)" ///
                    6 "({&sigma},{&pi}) from log(M/V) elasticity (Col. 9)" ///
                    7 "({&sigma},{&pi}) from log(V/R) elasticity (Col. 8)" ///
                    8 "({&sigma},{&pi}) from log(V/R) elasticity (Col. 9)") ///
              pos(11) ring(0) cols(1) size(vsmall)) ///
       xsize(5) ysize(4.5) ///
       graphregion(color(white)) plotregion(margin(small))

gr export "output/figures/fig7a.png", replace width(1200) height(1080)

* ======================================================================
* Panel (b): Counterfactual labor share
* ======================================================================

* --- Step 1: Construct deflated materials price via year-FE regression ---
* Regress sector-level log materials price on log VA price deflator,
* sector FE, and year FE (using all BEA-KLEMS manufacturing data from 1987).
* Year FE = residual materials price series (normalized to 0 in 1988).

use "data/dta/BEA-BLS_klems_clean.dta", clear

* Keep manufacturing sectors (NAICS 31-33)
keep if substr(ind_code,1,1) == "3"

* Aggregate compensation variables
gen WL = labor_nocol_compensation + labor_col_compensation
gen M = materials_compensation + energy_compensation

rename value_added VA
rename gross_output GO
rename materials_compensation MAT
rename energy_compensation EE

* --- Within-sector Tornqvist: materials + energy composite price ---
gen pMAT = MAT / materials_quantity
gen pEE  = EE  / energy_quantity

sort ind_code year
bys ind_code (year): gen dlog_pMAT = log(pMAT) - log(pMAT[_n-1]) if _n > 1
bys ind_code (year): gen dlog_pEE  = log(pEE)  - log(pEE[_n-1])  if _n > 1

gen mshr = MAT / (MAT + EE)
bys ind_code (year): gen mshr_L = mshr[_n-1]
gen w_inner = (mshr + mshr_L) / 2

gen dlog_pM_sector = w_inner * dlog_pMAT + (1 - w_inner) * dlog_pEE

* Cumulate to log level (relative to 1987)
bys ind_code (year): gen lp_M = 0 if _n == 1
bys ind_code (year): replace lp_M = lp_M[_n-1] + dlog_pM_sector if _n > 1 & !missing(dlog_pM_sector)

* --- Log VA price deflator ---
gen pVA = VA / va_quantity
gen lpVA = log(pVA)

* --- Weight by VA in 1987 ---
bys ind_code (year): gen VA_base = VA[1]

encode ind_code, gen(ind_id)

* --- Regression: extract year FE ---
reghdfe lp_M lpVA [aw=VA_base], absorb(ind_id yearfe=year) cluster(ind_id)

* --- Collapse year FE to year level ---
preserve
collapse (mean) yearfe, by(year)
sort year
* Normalize to 0 in 1988
qui sum yearfe if year == 1988
replace yearfe = yearfe - r(mean)
* Year-on-year changes in year FE
gen dlp = yearfe - yearfe[_n-1] if _n > 1
tempfile yearfe_data
save "`yearfe_data'"
restore

* --- Aggregate nominal variables to manufacturing level ---
bys year: egen M_total = total(M)
gen M_shr = M / M_total
bys ind_code (year): gen M_shr_L = M_shr[_n-1]
gen w_outer = (M_shr + M_shr_L) / 2
gen dlog_pM_weighted = w_outer * dlog_pM_sector

collapse (sum) dlog_pM_weighted (rawsum) GO VA WL M, by(year)
rename dlog_pM_weighted dlp_nom
sort year

* Cumulate nominal price
gen lp_nom = 0
replace lp_nom = lp_nom[_n-1] + dlp_nom if _n > 1 & !missing(dlp_nom)

* Generate key variables
gen labshr = WL / VA
gen M2VA = M / VA

* Merge year FE
merge 1:1 year using "`yearfe_data'", nogen

keep if inrange(year, 1988, 2019)
sort year


* Log labor share relative to 1988
gen llabshr = log(labshr) - log(labshr[1])

* Year-by-year counterfactual: in each year, remove the effect using
* LAGGED M/VA times the CHANGE in the deflated materials price (year FE)
* effect_t = |beta| * (M/VA)_{t-1} * d(yearfe_t)
* Cumulate these year-by-year effects

* Lagged M/VA
gen M2VA_L = M2VA[_n-1] if _n > 1

* Column 8 (baseline)
local absbeta = abs(`beta')
gen cum_effect    = 0
gen cum_effect_lo = 0
gen cum_effect_hi = 0
replace cum_effect    = cum_effect[_n-1]    + `absbeta'                  * M2VA_L * dlp if _n > 1 & !missing(dlp)
replace cum_effect_lo = cum_effect_lo[_n-1] + (`absbeta'-1.96*`beta_se') * M2VA_L * dlp if _n > 1 & !missing(dlp)
replace cum_effect_hi = cum_effect_hi[_n-1] + (`absbeta'+1.96*`beta_se') * M2VA_L * dlp if _n > 1 & !missing(dlp)
gen llabshr_cf    = llabshr + cum_effect
gen ub_llabshr_cf = llabshr + cum_effect_hi
gen lb_llabshr_cf = llabshr + cum_effect_lo

* Column 9 (industry trends)
local absbeta9 = abs(`beta9')
gen cum_effect9    = 0
gen cum_effect9_lo = 0
gen cum_effect9_hi = 0
replace cum_effect9    = cum_effect9[_n-1]    + `absbeta9'                    * M2VA_L * dlp if _n > 1 & !missing(dlp)
replace cum_effect9_lo = cum_effect9_lo[_n-1] + (`absbeta9'-1.96*`beta9_se') * M2VA_L * dlp if _n > 1 & !missing(dlp)
replace cum_effect9_hi = cum_effect9_hi[_n-1] + (`absbeta9'+1.96*`beta9_se') * M2VA_L * dlp if _n > 1 & !missing(dlp)
gen llabshr_cf9    = llabshr + cum_effect9
gen ub_llabshr_cf9 = llabshr + cum_effect9_hi
gen lb_llabshr_cf9 = llabshr + cum_effect9_lo

* --- Cumulative contribution from absolute log-labor-share deviations ---
* Contribution = 1 - sum|log(lambda_CF) - log(lambda_0)| / sum|log(lambda_actual) - log(lambda_0)|
* where lambda_0 is the labor share in the first year (1988)

* Sum of absolute deviations from initial value: actual
gen abs_dev_actual = abs(llabshr)
qui sum abs_dev_actual
local sum_actual = r(sum)

* Sum of absolute deviations from initial value: CF col 8
gen abs_dev_cf = abs(llabshr_cf)
qui sum abs_dev_cf
local sum_cf = r(sum)

* Sum of absolute deviations from initial value: CF col 9
gen abs_dev_cf9 = abs(llabshr_cf9)
qui sum abs_dev_cf9
local sum_cf9 = r(sum)

local contrib_8 = 1 - `sum_cf' / `sum_actual'
local contrib_9 = 1 - `sum_cf9' / `sum_actual'

di _n "=== Cumulative contribution ==="
di "  Sum |actual - lambda_0|:     " %8.3f `sum_actual'
di "  Sum |CF col8 - lambda_0|:    " %8.3f `sum_cf'
di "  Sum |CF col9 - lambda_0|:    " %8.3f `sum_cf9'
di "  Contribution (Col 8):        " %6.1f 100*`contrib_8' "%"
di "  Contribution (Col 9):        " %6.1f 100*`contrib_9' "%"

* --- Step 5: Plot ---

twoway (rarea ub_llabshr_cf lb_llabshr_cf year, ///
        color(cranberry%15) lwidth(none)) ///
       (rarea ub_llabshr_cf9 lb_llabshr_cf9 year, ///
        color(navy%15) lwidth(none)) ///
       (line llabshr year, ///
        lcolor(black) lpattern(solid) lwidth(medthick)) ///
       (line llabshr_cf year, ///
        lcolor(cranberry) lpattern(dash) lwidth(medthick)) ///
       (line llabshr_cf9 year, ///
        lcolor(navy) lpattern(dash) lwidth(medthick)) ///
       , ///
       ylabel(-0.3(0.1)0.1) xlabel(1988(4)2020) ///
       xtitle("Year") ///
       ytitle("Change in log labor share") ///
       legend(order(3 "Actual" 4 "CF: baseline (Col. 8)" ///
        5 "CF: ind. trends (Col. 9)") ///
        pos(11) ring(0) cols(1) size(small)) ///
       xsize(5) ysize(4.5) ///
       graphregion(color(white)) plotregion(margin(small))

gr export "output/figures/fig7b.png", replace width(1200) height(1080)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
