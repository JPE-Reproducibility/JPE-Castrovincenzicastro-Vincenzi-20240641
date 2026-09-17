* =======================================================================
* PROGRAM:          Create Table D.2: The Effect of Material Prices on the Labor Share - Disaster IV
* =======================================================================
clear all
set more off

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
* load data and merge disaster IV
* ======================================================================

use "data/dta/mainregfile.dta", clear
keep if inrange(year,1991,2016)
merge 1:1 naics year using "data/dta/disaster_iv_data.dta", nogen keep(master match)

* define variables
global yvar llabshr
global xvar treat
global commoncontrols lw lpiinv
global extracontrols1 prodshr lcap2lab
global extracontrols2 prodshr lcap2lab impen impen_china
global fe naics year
global w vadd_90
global div div_1

label variable ${xvar} "Mat. Int. $\times$ Log Mat. Price"
label variable lw "Log. Average Wage"
label variable lpiinv "Log. Investment Price"
label variable lcap2lab "Log. Capital-Labor Ratio"
label variable prodshr "Production Workers Share"
label variable impen "Import Penetration"
label variable impen_china "Import Penetration - China"

local cond if inrange(year,1991,2016)

* ======================================================================
* run regressions
* ======================================================================
eststo clear

* (1) OLS unweighted
qui eststo col1: reghdfe ${yvar} ${xvar} `cond', absorb(${fe}) cluster(naics) nocons
qui estadd local WeightedRow "No"
qui estadd local FErow "Yes"

* (2) OLS unweighted + controls
qui eststo col2: reghdfe ${yvar} ${xvar} ${commoncontrols} `cond', absorb(${fe}) cluster(naics) nocons
qui estadd local WeightedRow "No"
qui estadd local FErow "Yes"

* (3) 2SLS unweighted
qui ivreghdfe ${yvar} (${xvar} = ${div}) `cond', absorb(${fe}) cluster(naics) nocons
local fstat3 = e(widstat)
qui eststo col3
qui estadd scalar fstat = `fstat3'
qui estadd local WeightedRow "No"
qui estadd local FErow "Yes"

* (4) 2SLS unweighted + controls
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} `cond', absorb(${fe}) cluster(naics) nocons
local fstat4 = e(widstat)
qui eststo col4
qui estadd scalar fstat = `fstat4'
qui estadd local WeightedRow "No"
qui estadd local FErow "Yes"

* (5) 2SLS weighted
qui ivreghdfe ${yvar} (${xvar} = ${div}) `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons
local fstat5 = e(widstat)
qui eststo col5
qui estadd scalar fstat = `fstat5'
qui estadd local WeightedRow "Yes"
qui estadd local FErow "Yes"

* (6) 2SLS weighted + controls
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons
local fstat6 = e(widstat)
qui eststo col6
qui estadd scalar fstat = `fstat6'
qui estadd local WeightedRow "Yes"
qui estadd local FErow "Yes"

* (7) weighted + extra controls 1
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} ${extracontrols1} `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons
local fstat7 = e(widstat)
qui eststo col7
qui estadd scalar fstat = `fstat7'
qui estadd local WeightedRow "Yes"
qui estadd local FErow "Yes"

* (8) weighted + extra controls 2
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} ${extracontrols2} `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons
local fstat8 = e(widstat)
qui eststo col8
qui estadd scalar fstat = `fstat8'
qui estadd local WeightedRow "Yes"
qui estadd local FErow "Yes"

* ======================================================================
* export table
* ======================================================================
esttab col1 col2 col3 col4 col5 col6 col7 col8 using "output/tables/tabD2.tex", ///
    fragment ///
    nocons se ///
    keep(treat lw lpiinv lcap2lab prodshr impen impen_china) ///
    order(treat lw lpiinv lcap2lab prodshr impen impen_china) ///
    s(fstat N FErow WeightedRow, ///
      labels("First-stage F-stat (KP-Wald)" "\hline N" "Industry and Year FE" "Weighted") ///
      fmt(%9.2f %9.0f)) ///
    replace ///
    mtitle("OLS" "OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
    noobs nodepvar nonotes gaps ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    lines tex ///
    mgroups("" "" "\multicolumn{4}{c}{Log Industry Labor Share}" "" "\\ \cline{2-9} %" " ", pattern(1 1 1 1 1 1 1 1))

di "Disaster IV Table D.2 saved to output/tables/tabD2.tex"
