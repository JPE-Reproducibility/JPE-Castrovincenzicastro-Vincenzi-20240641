* =======================================================================
* PROGRAM:          Create Table 4: Material Prices and the Labor Share Across Countries
*                   6 columns: OLS/2SLS/2SLS-exUS × unweighted/weighted
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

* ======================================================================
* run regressions and create table
* ======================================================================

use "$path/data/dta/crosscountry_panel.dta", clear

eststo clear

* --- Unweighted (cols 1-3) ---

* Col 1: OLS, unweighted
qui reghdfe llabshr treat lw, absorb(ci year) cluster(ci)
estadd local CIfe "Yes"
estadd local Yfe "Yes"
estadd local Lw "Yes"
estadd local ExUS ""
eststo col1

* Col 2: 2SLS, unweighted
qui ivreghdfe llabshr lw (treat = shift_share_fx), absorb(ci year) cluster(ci)
estadd local CIfe "Yes"
estadd local Yfe "Yes"
estadd local Lw "Yes"
estadd local ExUS ""
eststo col2

* Col 3: 2SLS, unweighted, excl. US
qui ivreghdfe llabshr lw (treat = shift_share_fx) if !us, absorb(ci year) cluster(ci)
estadd local CIfe "Yes"
estadd local Yfe "Yes"
estadd local Lw "Yes"
estadd local ExUS "Yes"
eststo col3

* --- Weighted (cols 4-6) ---

* Col 4: OLS, weighted
qui reghdfe llabshr treat lw [aw=va_base], absorb(ci year) cluster(ci)
estadd local CIfe "Yes"
estadd local Yfe "Yes"
estadd local Lw "Yes"
estadd local ExUS ""
eststo col4

* Col 5: 2SLS, weighted
qui ivreghdfe llabshr lw (treat = shift_share_fx) [aw=va_base], absorb(ci year) cluster(ci)
estadd local CIfe "Yes"
estadd local Yfe "Yes"
estadd local Lw "Yes"
estadd local ExUS ""
eststo col5

* Col 6: 2SLS, weighted, excl. US
qui ivreghdfe llabshr lw (treat = shift_share_fx) [aw=va_base] if !us, absorb(ci year) cluster(ci)
estadd local CIfe "Yes"
estadd local Yfe "Yes"
estadd local Lw "Yes"
estadd local ExUS "Yes"
eststo col6


esttab col1 col2 col3 col4 col5 col6, se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat) ///
    stats(widstat N CIfe Yfe Lw ExUS, ///
        labels("First-stage F-stat (KP-Wald)" "N" ///
               "Country*Industry FE" "Year FE" "Log Wage" "Excl. US")) ///
    mtitle("OLS" "2SLS" "2SLS" "OLS" "2SLS" "2SLS") ///
    title("Material Prices and the Labor Share Across Countries")

esttab col1 col2 col3 col4 col5 col6 using "$path/output/tables/tab4.tex", ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat) ///
    stats(widstat N CIfe Yfe Lw ExUS, ///
        labels("First-stage F-stat (KP-Wald)" "\hline N" ///
               "Country\$\times\$Industry FE" "Year FE" ///
               "Log Wage" `"Excl.\ US"')) ///
    mtitle("OLS" "2SLS" "2SLS" "OLS" "2SLS" "2SLS") ///
    replace fragment ///
    prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
    tex label depvar nonotes gaps lines ///
    mgroups("Unweighted" "Weighted", ///
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span}))
