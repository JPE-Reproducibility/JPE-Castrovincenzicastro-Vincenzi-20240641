* =======================================================================
* PROGRAM:			Create Table C.12: The Effect of Material Prices - Different Periods
* DATE:				02 April 2026
* NOTE:				Period-specific specifications (Materials Intensity x Log Materials Price)
*					Controls: log average wage, log investment price, production-worker share, and log capital-labor ratio.
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

global controls lw lpiinv prodshr lcap2lab

eststo clear

*Labor share: 1958-1970
cap drop treat
gen treat = mat2va_58 * lpimat
qui eststo: reghdfe llabshr treat $controls if inrange(year,1958,1970) [aw=vadd_58], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Labor share: 1970-1980
cap drop treat
gen treat = mat2va_70 * lpimat
qui eststo: reghdfe llabshr treat $controls if inrange(year,1970,1980) [aw=vadd_70], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Labor share: 1980-1997
cap drop treat
gen treat = mat2va_80 * lpimat
qui eststo: reghdfe llabshr treat $controls if inrange(year,1980,1997) [aw=vadd_80], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Labor share: 1997-2016
cap drop treat
gen treat = mat2va_97 * lpimat
qui eststo: reghdfe llabshr treat $controls if inrange(year,1997,2016) [aw=vadd_97], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Log. Materials to Wage-Bill: 1958-1970
cap drop treat
gen treat = mat2va_58 * lpimat
qui eststo: reghdfe lmat2lab treat $controls if inrange(year,1958,1970) [aw=vadd_58], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Log. Materials to Wage-Bill: 1970-1980
cap drop treat
gen treat = mat2va_70 * lpimat
qui eststo: reghdfe lmat2lab treat $controls if inrange(year,1970,1980) [aw=vadd_70], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Log. Materials to Wage-Bill: 1980-1997
cap drop treat
gen treat = mat2va_80 * lpimat
qui eststo: reghdfe lmat2lab treat $controls if inrange(year,1980,1997) [aw=vadd_80], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

*Log. Materials to Wage-Bill: 1997-2016
cap drop treat
gen treat = mat2va_97 * lpimat
qui eststo: reghdfe lmat2lab treat $controls if inrange(year,1997,2016) [aw=vadd_97], absorb(naics year) cluster(naics) nocons
qui estadd local FE "Yes"

label variable treat "Materials Intensity × Log. Materials Price"

esttab using "output/tables/tabC12.tex", ///
    title("The Effect of Material Prices on the Labor Share" ) ///
	mtitle("1958-1970 " "1970-1980" "1980-1997" "1997-2016" "1958-1970 " "1970-1980" "1980-1997" "1997-2016") ///
    nocons se ///
    s( N FE , labels("N" "Industry and Year FE" )) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps keep(treat) lines star(* 0.10 ** 0.05 *** 0.01) mgroups( "\multicolumn{4}{c}{Log. Labor Share}" "\multicolumn{4}{c}{Log. Materials to Wage-Bill} \\ \cmidrule(lr{.75em}){2-5} \cmidrule(l{.75em}r){6-9}%" " ", pattern(1 1 1 1 1 1 1 1))
