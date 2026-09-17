* =======================================================================
* PROGRAM:			Create Table C.5: The Effect of Material Prices on the Materials Intensity and the Value-Added Share
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
* create variables
* ======================================================================

use "data/dta/mainregfile.dta", clear

* create variables 
gen lM2VA = log(matcost/vadd)
gen lVA2R = log(vadd/vship)

* ======================================================================
* run regressions and create table
* ======================================================================

replace treat = (lpimat)
global xvar treat
global w vadd_90
global commoncontrols lw lpiinv prodshr lcap2lab impen impen_china
global fe naics year
global iv shift_share_ct
global cond if !missing(shift_share_ct) & inrange(year,1991,2016)

label variable ${xvar} "Log. Materials Price"


eststo clear
qui eststo: ivreghdfe 	lM2VA (${xvar} = ${iv}) ${commoncontrols}  ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local IC "Yes"
qui estadd local IT "No"


qui eststo: ivreghdfe 	lM2VA (${xvar} = ${iv}) ${commoncontrols}  ${cond} [aw=${w}], absorb(${fe} c.year##i.naics) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local IC "Yes"
qui estadd local IT "Yes"


qui eststo: ivreghdfe 	lVA2R (${xvar} = ${iv}) ${commoncontrols}  ${cond} [aw=${w}], absorb(${fe}) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local IC "Yes"
qui estadd local IT "No"


qui eststo: ivreghdfe 	lVA2R (${xvar} = ${iv}) ${commoncontrols}  ${cond} [aw=${w}], absorb(${fe} c.year##i.naics) cluster(naics) nocons
qui estadd local Weighted "Yes"
qui estadd local FE "Yes"
qui estadd local IC "Yes"
qui estadd local IT "Yes"


esttab, ///
    title("The Eﬀect of the Price of Materials on Other Industry Outcomes." ) ///
	mtitle("Log M/V" "Log M/V " "Log V/R" "Log V/R") ///
    nocons se ///
    s(widstat  N IC FE Weighted IT , labels("First-stage F-stat (KP-Wald)" "\hline N" "Industry controls (see notes)" "Industry and Year FE " "Weighted" "Industry Trends" )) ///
    replace ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline \end{tabular} \end{table}") ///
	label depvar nonotes gaps keep(treat) lines star(* 0.10 ** 0.05 *** 0.01)	


esttab using "output/tables/tabC5.tex", ///
    title("The Eﬀect of the Price of Materials on Other Industry Outcomes." ) ///
	mtitle("Log M/V" "Log M/V " "Log V/R" "Log V/R") ///
    nocons se ///
    s(widstat  N IC FE Weighted , labels("First-stage F-stat (KP-Wald)" "\hline N" "Industry controls (see notes)" "Industry and Year FE " "Weighted" )) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps keep(treat) lines star(* 0.10 ** 0.05 *** 0.01)


