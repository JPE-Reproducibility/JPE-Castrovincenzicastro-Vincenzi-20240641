* =======================================================================
* PROGRAM: Merge the cross-country IV into klems_panel_2025.dta,
*          apply sample restrictions and construct regression variables.
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

use "$path/data/dta/klems_panel_2025.dta", clear

* ======================================================================
* PART 1: Merge with cross-country IV
* ======================================================================

di _n "=============================================="
di "Part 1: Merging with shift-share IV"
di "=============================================="

* In the panel data, create a merge key replacing dashes with underscores
gen indcode_merge = subinstr(indcode, "-", "_", .)

* Load IV and fix its indcode to match
preserve
    use "$path/data/dta/crosscountry_iv.dta", clear
    * The IV has indcode with mixed conventions
    * Replace dashes with underscores to match
    gen indcode_merge = subinstr(indcode, "-", "_", .)
    drop indcode
    save "$path/data/dta/crosscountry_iv_merge.dta", replace
restore

merge m:1 country indcode_merge year using "$path/data/dta/crosscountry_iv_merge.dta", keep(mas mat)
di _n "IV merge results:"
tab _merge
di "Manufacturing obs without IV match:"
qui count if _merge == 1 & manuf == 1
di "  " r(N) " manufacturing obs unmatched"
qui count if _merge == 3 & manuf == 1
di "  " r(N) " manufacturing obs matched"
drop _merge indcode_merge



rename shift_share_fx_ct shift_share_fx

* ======================================================================
* PART 2: Data cleaning, then construct regression variables
* ======================================================================

* Keep manufacturing only
keep if manuf == 1

* Drop Luxembourg (too few manufacturing sectors, extreme price outlier)
* Drop Slovakia (extreme price outlier from 2020 vintage splice)
drop if inlist(country, "LU", "SK")

* ---- Data cleaning (before computing base-year variables) ----
* Drop observations where compensation exceeds value added (labshr > 1)
qui count if comp > va
di "Dropping " r(N) " obs with comp > va"
drop if comp > va

* Drop observations where intermediate inputs exceed gross output
qui count if ii > go
di "Dropping " r(N) " obs with ii > go"
drop if ii > go

* Drop extreme materials intensity (II/VA > 10)
* These are mostly C19 (petroleum refining) with volatile margins
qui count if mat2va > 10
di "Dropping " r(N) " obs with mat2va > 10"
drop if mat2va > 10

* Drop extreme labor shares (comp/VA < 0.05 or > 0.95)
qui count if labshr < 0.05 | labshr > 0.95
di "Dropping " r(N) " obs with labor share < 0.05 or > 0.95"
drop if labshr < 0.05 | labshr > 0.95

* Drop country×sector pairs with fewer than 5 observations
bys country indcode: gen _nobs = _N
qui count if _nobs < 5
di "Dropping " r(N) " obs from country-sector pairs with < 5 years"
drop if _nobs < 5
drop _nobs

* ---- Construct regression variables (after cleaning) ----
* Materials intensity in base year: use year 2000 for consistency across countries
* Fallback to first available year if no year-2000 data
gen _mat2va_2000 = mat2va if year == 2000
bys country indcode: egen mat2va_base = max(_mat2va_2000)
bys country indcode (year): replace mat2va_base = mat2va[1] if missing(mat2va_base)
drop _mat2va_2000

* Treatment: baseline materials intensity × log materials price
gen treat = mat2va_base * lii_pi

* Weight: within-country VA share in year 2000 (common base year)
* For each country-industry pair without a 2000 value, use its first available year.
gen _va_2000 = va if year == 2000
bys country indcode: egen _va_sec = max(_va_2000)
bys country indcode (year): replace _va_sec = va[1] if missing(_va_sec)
* Compute country total from these base-year sector values (constant across obs)
egen _cty_sec = group(country indcode)
preserve
    bys _cty_sec: keep if _n == 1
    bys country: egen _va_cty_total = total(_va_sec)
    keep _cty_sec _va_cty_total
    tempfile _wts
    save "`_wts'"
restore
merge m:1 _cty_sec using "`_wts'", nogen
gen va_base = _va_sec / _va_cty_total
drop _va_2000 _va_sec _cty_sec _va_cty_total

label variable treat "Materials Intensity × Log Materials Price"
label variable llabshr "Log Labor Share"
label variable lw "Log Wage"
label variable lpiinv "Log Investment Price"
label variable lcap2lab "Log Capital-Labor Ratio"

* Drop missing regression variables
drop if missing(llabshr, treat, shift_share_fx, lw, va_base)

* Regenerate ci after drops
cap drop ci
egen ci = group(country indcode)

di _n "Final analysis sample:"
di "  Observations: " _N
tab country
tab indcode
sum year

save "$path/data/dta/crosscountry_panel.dta", replace
