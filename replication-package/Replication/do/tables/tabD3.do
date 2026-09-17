* =======================================================================
* PROGRAM:          Create Table D.3: First Stage - Disaster IV
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

label variable ${div} "Disaster IV"
label variable ${xvar} "Mat. Int. $\times$ Log Mat. Price"

local cond if inrange(year,1991,2016)

* ======================================================================
* first-stage regressions
* ======================================================================
eststo clear

* (3) 2SLS unweighted, no controls
qui ivreghdfe ${yvar} (${xvar} = ${div}) `cond', absorb(${fe}) cluster(naics) nocons savefirst savefprefix(fs3_)
local fstat3 = e(widstat)
qui eststo fs3: estimates restore fs3_${xvar}
qui estadd scalar fstat = `fstat3'
qui estadd local ControlsRow "No"
qui estadd local WeightedRow "No"

* (4) 2SLS unweighted + controls
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} `cond', absorb(${fe}) cluster(naics) nocons savefirst savefprefix(fs4_)
local fstat4 = e(widstat)
qui eststo fs4: estimates restore fs4_${xvar}
qui estadd scalar fstat = `fstat4'
qui estadd local ControlsRow "Yes"
qui estadd local WeightedRow "No"

* (5) 2SLS weighted, no controls
qui ivreghdfe ${yvar} (${xvar} = ${div}) `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons savefirst savefprefix(fs5_)
local fstat5 = e(widstat)
qui eststo fs5: estimates restore fs5_${xvar}
qui estadd scalar fstat = `fstat5'
qui estadd local ControlsRow "No"
qui estadd local WeightedRow "Yes"

* (6) 2SLS weighted + controls
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons savefirst savefprefix(fs6_)
local fstat6 = e(widstat)
qui eststo fs6: estimates restore fs6_${xvar}
qui estadd scalar fstat = `fstat6'
qui estadd local ControlsRow "Yes"
qui estadd local WeightedRow "Yes"

* (7) weighted + extra controls 1
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} ${extracontrols1} `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons savefirst savefprefix(fs7_)
local fstat7 = e(widstat)
qui eststo fs7: estimates restore fs7_${xvar}
qui estadd scalar fstat = `fstat7'
qui estadd local ControlsRow "Yes"
qui estadd local WeightedRow "Yes"

* (8) weighted + extra controls 2
qui ivreghdfe ${yvar} (${xvar} = ${div}) ${commoncontrols} ${extracontrols2} `cond' [aw=${w}], absorb(${fe}) cluster(naics) nocons savefirst savefprefix(fs8_)
local fstat8 = e(widstat)
qui eststo fs8: estimates restore fs8_${xvar}
qui estadd scalar fstat = `fstat8'
qui estadd local ControlsRow "Yes"
qui estadd local WeightedRow "Yes"

* ======================================================================
* export table
* ======================================================================
* This is a first-stage table, so the outcome spanning the columns is the
* endogenous regressor, not the labor share.
esttab fs3 fs4 fs5 fs6 fs7 fs8 using "output/tables/tabD3.tex", ///
    fragment ///
    nocons se ///
    keep(${div}) ///
    order(${div}) ///
    s(fstat N ControlsRow WeightedRow, ///
      labels("F-stat (KP-Wald)" "\hline N" "Controls" "Weighted") ///
      fmt(%9.2f %9.0f)) ///
    replace ///
    mtitle("2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
    noobs nodepvar nonotes gaps ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    lines tex ///
    mgroups("Materials Intensity $\times$ Log. Materials Price", ///
        pattern(1 0 0 0 0 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span}))

di "Disaster IV first stage saved to output/tables/"
