* =======================================================================
* PROGRAM:			Create Table C.10: Controlling for Industry Concentration
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


* define variables and conditions for regression
global yvar llabshr
global xvar treat
global commoncontrols lw lpiinv
global extracontrols1 prodshr lcap2lab
global extracontrols2 prodshr lcap2lab impen impen_china
global concmeasures cr4 lhhi50
global fe naics year
global iv shift_share_ct
global w vadd_90
global cond if !missing(shift_share_ct) & inrange(year,1991,2016) & !missing(cr4) & !missing(lhhi50)

label variable treat "Materials Intensity × Log. Materials Price"
label variable cr4 "Fraction of Sales Top-4"
label variable lhhi50 "Log. HHI-50"



* create table
eststo clear
*FE: ols
qui eststo: reghdfe ${yvar} ${xvar} ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"

*FE: 2sls weighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"

*FE: 2sls weighted with additional variables
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols1} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local FE "Yes"
*FE: ols
qui eststo: reghdfe ${yvar} ${xvar} ${concmeasures} ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"
*FE: 2sls weighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${concmeasures} ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"

*FE: 2sls weighted with additional variables + import penetration (subset of industries)
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${concmeasures} ${commoncontrols} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local FE "Yes"

esttab using "output/tables/tabC10.tex", ///
    title("Controlling for Industry Concentration" ) ///
	mtitle("OLS" "2SLS" "2SLS" "OLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N commoncontrols extracontrols1 extracontrols2 FE Weighted , labels("First-stage F-stat (KP-Wald)" "\hline N" "Average Wage and Investment Price Controls" "Production Workers Share and K/L Ratio Controls" "Import Penetration Controls " "Industry and Year FE" "Weighted" )) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps keep(treat cr4 lhhi50) lines star(* 0.10 ** 0.05 *** 0.01) mgroups("" "\multicolumn{4}{c}{Log Industry Labor Share} "  " \\ \cline{2-7} %", pattern(1 1 1 1 1))



