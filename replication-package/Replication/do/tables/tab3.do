* =======================================================================
* PROGRAM:			Create Table 3: The Effect of Material Prices on the Labor Share - 1970s Oil Shock
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
* merge datasets and create variables
* ======================================================================
use "data/dta/mainregfile.dta", clear

qui merge m:1 year using "data/dta/oilprices.dta", gen(merge_oil) keep(mat mas)
qui merge m:1 naics using "data/raw/misc/naicsnames12.dta", keep(1 3) nogen


*define the regressor and instrument 
gen treat_72 = mat2va_72*lpimat
gen iv = energy/vadd if year==1972
bys naics (year): ereplace iv = max(iv)
replace iv = iv*log(oil_price_real)

* ======================================================================
* run regressions and create table
* ======================================================================


* define variables and conditions for regression
global y llabshr 
global x treat_72
global iv iv
global cond if inrange(year,1970,1980)
global ww vadd_72
global controls_base lw lpiinv

label variable treat_72 "Materials Intensity × Log. Materials Price"



* create table
eststo clear
eststo: reghdfe ${y} ${x} ${controls_base} ${cond}, absorb(naics year) cluster(naics)
qui estadd local Weighted "No"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local FE "Yes"
qui estadd local FE2 "No"




eststo: ivreghdfe ${y} (${x}=${iv}) ${controls_base} ${cond}, absorb(naics year) cluster(naics)
qui estadd local Weighted "No"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local FE "Yes"
qui estadd local FE2 "No"



eststo: ivreghdfe ${y} (${x}=${iv}) ${controls_base} ${cond} [aw=${ww}], absorb(naics year) cluster(naics)
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local FE "Yes"
qui estadd local FE2 "No"


eststo: ivreghdfe ${y} (${x}=${iv}) ${controls_base} prodshr lcap2lab ${cond} [aw=${ww}], absorb(naics year) cluster(naics)
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local FE "Yes"
qui estadd local FE2 "No"


eststo: ivreghdfe ${y} (${x}=${iv}) ${controls_base} ${cond} [aw=${ww}], absorb(naics n3y) cluster(naics)
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local FE "Yes"
qui estadd local FE2 "Yes"


eststo: ivreghdfe ${y} (${x}=${iv}) ${controls_base} prodshr lcap2lab ${cond} [aw=${ww}], absorb(naics n3y) cluster(naics)
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local FE "Yes"
qui estadd local FE2 "Yes"



esttab using "output/tables/tab3.tex", ///
    title("The Eﬀect of Material Prices on the Labor Share - 1970s Oil Shock" ) ///
	mtitle("OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N commoncontrols extracontrols1 FE FE2 Weighted , labels("First-stage F-stat (KP-Wald)" "\hline N" "Average Wage and Investment Price Controls" "Production Workers Share and K/L Ratio Controls" "Industry and Year FE " "Industry and Year ×Sector FE " "Weighted " )) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps keep(treat_72) lines star(* 0.10 ** 0.05 *** 0.01) mgroups( "" "\multicolumn{4}{c}{Log Industry Labor Share}" "\\ \cline{2-7} %" " ", pattern(1 1 1 1 1))


