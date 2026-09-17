* =======================================================================
* PROGRAM:			Create Table 2: The Effect of Material Prices - Variation from Local Labor Markets
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

use "data/dta/regional.dta"

* define variables and conditions for regression
global yvar lLS
global xvar treat
global w ww
global commoncontrols lw lpk
global extracontrols1 lemp manuf_share
global extracontrols2 lemp manuf_share impen impen_china
global fe cz year
global iv iv 
global cond 

label variable ${xvar} "Materials Intensity × Log. Materials Price"


* create table
eststo clear
*FE: ols
qui eststo: reghdfe ${yvar} ${xvar} ${commoncontrols} ${cond} , absorb(${fe}) cluster(cz) nocons
qui estadd local Weighted "No"
qui estadd local FE "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local Trends "No"

*FE: 2sls unweighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond}, absorb(${fe}) cluster(cz) nocons
qui estadd local Weighted "No"
qui estadd local FE "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local Trends "No"

*FE: 2sls weighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(cz) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local Trends "No"

*FE: 2sls weighted with additional variables
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols1} ${cond} [aw=${w}], absorb(${fe}) cluster(cz) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "No"
qui estadd local Trends "No"

* FE: weighted 2SLS with wage, investment-price, regional-employment, manufacturing-share, and import-penetration controls.
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe}) cluster(cz) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local Trends "No"

* FE: weighted 2SLS with the same controls and CZ-specific linear trends.
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe} i.cz#c.year) cluster(cz) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local Trends "Yes"


esttab , ///
    title("The Eﬀect of Material Prices - Variation from Local Labor Markets" ) ///
	mtitle("OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N commoncontrols extracontrols1 extracontrols2 FE Weighted Trends, labels("First-stage F-stat (KP-Wald)" "\hline N" "Average Wage and Investment Price Controls" "Controls for regional employment and manuf. share" "Controls for import penetration" "Region and Year FE" "Weighted" "CZ-Specific Trends")) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	label depvar nonotes gaps keep(treat) lines star(* 0.10 ** 0.05 *** 0.01) mgroups("" "\multicolumn{4}{c}{Log Labor Share} "  " \\ \cline{2-7} %", pattern(1 1 1 1 1 1))

esttab using "output/tables/tab2.tex", ///
    title("The Eﬀect of Material Prices - Variation from Local Labor Markets" ) ///
	mtitle("OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N commoncontrols extracontrols1 extracontrols2 FE Weighted Trends, labels("First-stage F-stat (KP-Wald)" "\hline N" "Average Wage and Investment Price Controls" "Controls for regional employment and manuf. share" "Controls for import penetration" "Region and Year FE" "Weighted" "CZ-Specific Trends")) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps keep(treat) lines star(* 0.10 ** 0.05 *** 0.01) mgroups("" "\multicolumn{4}{c}{Log Labor Share} "  " \\ \cline{2-7} %", pattern(1 1 1 1 1 1))
	






