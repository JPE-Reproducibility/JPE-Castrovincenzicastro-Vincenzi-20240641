* =======================================================================
* PROGRAM:            Create Table C.11: The Effect of Material Prices on the Labor Share - Energy vs. Non-energy Instruments
* PURPOSE:            Eight-column IV table: four energy and four non-energy specifications
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

* Ensure output folders exist
cap mkdir "output"
cap mkdir "output/tables"
cap mkdir "output/figures"

* ======================================================================
* Load data once
* ======================================================================
use "data/dta/mainregfile.dta", clear
keep if inrange(year,1991,2016)

* ======================================================================
* Globals and labels
* ======================================================================
global yvar llabshr
global xvar treat

global commoncontrols lw lpiinv
global extracontrols2 prodshr lcap2lab impen impen_china

global fe naics year
global w  vadd_90
global cond if !missing(shift_share_ct) & inrange(year,1991,2016)

label variable ${xvar} "Materials Intensity $\times$ Log. Materials Price"
label variable lw "Log. Average Wage"
label variable lpiinv "Log. Investment Price"
label variable lcap2lab "Log. Capital-Labor Ratio"
label variable prodshr "Production Workers Share"
label variable impen "Import Penetration"
label variable impen_china "Import Penetration - China"

* ======================================================================
* MAIN TABLE: 8 columns (weighted), 4 per IV set
*   Spec A: no controls
*   Spec B: + commoncontrols
*   Spec C: + commoncontrols + extracontrols2
*   Spec D: + commoncontrols + extracontrols2 + industry-specific trends
* ======================================================================

eststo clear

local OUT_MAIN   "output/tables/tabC11.tex"

local WGT "[aw=${w}]"

* ======================================================================
* (I) ENERGY ONLY: iv = shift_share_e_ct
* ======================================================================
local iv_energy "shift_share_e_ct"

noisily eststo E1: ivreghdfe ${yvar} (${xvar} = `iv_energy') ${cond} `WGT', ///
    absorb(${fe}) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "No"

noisily eststo E2: ivreghdfe ${yvar} (${xvar} = `iv_energy') ${commoncontrols} ${cond} `WGT', ///
    absorb(${fe}) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "No"

noisily eststo E3: ivreghdfe ${yvar} (${xvar} = `iv_energy') ${commoncontrols} ${extracontrols2} ${cond} `WGT', ///
    absorb(${fe}) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "No"

noisily eststo E4: ivreghdfe ${yvar} (${xvar} = `iv_energy') ${commoncontrols} ${extracontrols2} ${cond} `WGT', ///
    absorb(${fe} i.naics#c.year) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "Yes"

* ======================================================================
* (II) NON-ENERGY ONLY: iv = shift_share_ne_ct
* ======================================================================
local iv_nonenergy "shift_share_ne_ct"

noisily eststo NE1: ivreghdfe ${yvar} (${xvar} = `iv_nonenergy') ${cond} `WGT', ///
    absorb(${fe}) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "No"

noisily eststo NE2: ivreghdfe ${yvar} (${xvar} = `iv_nonenergy') ${commoncontrols} ${cond} `WGT', ///
    absorb(${fe}) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "No"

noisily eststo NE3: ivreghdfe ${yvar} (${xvar} = `iv_nonenergy') ${commoncontrols} ${extracontrols2} ${cond} `WGT', ///
    absorb(${fe}) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "No"

noisily eststo NE4: ivreghdfe ${yvar} (${xvar} = `iv_nonenergy') ${commoncontrols} ${extracontrols2} ${cond} `WGT', ///
    absorb(${fe} i.naics#c.year) cluster(naics) nocons
noisily estadd local Weighted "Yes"
noisily estadd local FE "Yes"
estadd local Trends "Yes"

* ======================================================================
* Export 8-column table (Energy 4 cols + Non-energy 4 cols)
* Formatting matches Table 1 in the paper
* ======================================================================

esttab E1 E2 E3 E4 NE1 NE2 NE3 NE4 using "`OUT_MAIN'", ///
    mtitle("2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat N FE Weighted Trends, ///
      labels("First-stage F-stat (KP-Wald)" "\hline N" "Industry and Year FE" "Weighted" "Industry-Specific Trends")) ///
    replace ///
    fragment ///
    prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
    tex label depvar nonotes gaps lines star(* 0.10 ** 0.05 *** 0.01) ///
    mgroups("Energy IV" "Non-energy IV", ///
        pattern(1 0 0 0 1 0 0 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span}))

di as text "Wrote 8-column table to: `OUT_MAIN'"

di as result "Done."
