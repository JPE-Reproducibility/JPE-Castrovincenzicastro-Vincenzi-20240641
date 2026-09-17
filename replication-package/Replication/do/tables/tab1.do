* =======================================================================
* PROGRAM:			Create Table 1: The Effect of Material Prices on the Labor Share
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

* ======================================================================
* run regressions and create table
* ======================================================================

use "data/dta/mainregfile.dta", clear

keep if inrange(year,1991,2016)


* define variables and conditions for regression
global yvar llabshr
global xvar treat
global commoncontrols lw lpiinv
global extracontrols1 prodshr lcap2lab
global extracontrols2 prodshr lcap2lab impen impen_china
global fe naics year
global iv shift_share_ct
global w vadd_90
global cond if !missing(shift_share_ct) & inrange(year,1991,2016)

label variable ${xvar} "Materials Intensity × Log. Materials Price"
label variable lw "Log. Average Wage"
label variable lpiinv "Log. Investment Price"
label variable lcap2lab "Log. Capital-Labor Ratio"
label variable prodshr "Production Workers Share"
label variable impen "Import Penetration"
label variable impen_china "Import Penetration - China"


* Create table
eststo clear

* FE: OLS - no controls
qui eststo: reghdfe ${yvar} ${xvar} ${cond}, absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "No"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: OLS
qui eststo: reghdfe ${yvar} ${xvar} ${commoncontrols} ${cond}, absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "No"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS unweighted - no controls
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${cond}, absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "No"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS unweighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond}, absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "No"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS weighted - no controls
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS weighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS weighted with additional variables
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols1} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS weighted with additional variables + import penetration (subset)
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local Trends "No"

* FE: 2SLS weighted with additional variables + import penetration + industry-specific trends (subset)
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe} i.naics#c.year) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local Trends "Yes"

* Export to LaTeX
esttab using "output/tables/tab1.tex", ///
    title("The Effect of Material Prices on the Labor Share" ) ///
	mtitle("OLS" "OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N FE Weighted Trends, labels("First-stage F-stat (KP-Wald)" "\hline N" "Industry and Year FE" "Weighted" "Industry-Specific Trends")) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps lines star(* 0.10 ** 0.05 *** 0.01) mgroups( "" "" "\multicolumn{4}{c}{Log Industry Labor Share}" "" "\\ \cline{2-10} %" " ", pattern(1 1 1 1 1 1 1 1 1))


* Display the table in the Stata results window and execution log.
esttab , ///
    title("The Effect of Material Prices on the Labor Share" ) ///
	mtitle("OLS" "OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N FE Weighted Trends, labels("First-stage F-stat (KP-Wald)" "\hline N" "Industry and Year FE" "Weighted" "Industry-Specific Trends")) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	label depvar nonotes gaps lines star(* 0.10 ** 0.05 *** 0.01) mgroups( "" "" "\multicolumn{4}{c}{Log Industry Labor Share}" "" "\\ \cline{2-10} %" " ", pattern(1 1 1 1 1 1 1 1 1))
