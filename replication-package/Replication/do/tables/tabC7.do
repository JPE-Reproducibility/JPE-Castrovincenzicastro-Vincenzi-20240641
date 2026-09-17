* =======================================================================
* PROGRAM:			Create Table C.7: The Effect of Material Prices on the Labor Share - BEA Subsectors
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

*================================================================*
* Collapse Census data to the bea classification 
*================================================================*

use "data/dta/mainregfile.dta", clear

* merge bea codes
merge m:1 naics using "data/raw/Concordances/naics2012_to_bea.dta", nogen


* collapse census vars to the KLEMS level
gcollapse (sum) im ex im_china pay vadd matcost emp vship energy prod* cap (mean) pi* shift_share* [w=vadd], by(year bea_summary)

* merge bea data 
rename bea_summary ind_code
keep if year>=1987
merge 1:1 year ind_code using "data/dta/BEA-BLS_klems_clean.dta", keep(1 3)

*================================================================*
* Generate variables 
*================================================================*

* clean trade variables
replace ex = cond(missing(ex),0,ex)
replace im = cond(missing(im),0,im)
replace im_china = cond(missing(im_china),0,im_china)
gen impen = im/(vship + im - ex)
gen impen_china = im_china/(vship + im - ex)

* generate variables
gen labshr = (labor_nocol_compensation+labor_col_compensation)/value_added
gen mat2vadd = matcost/vadd

gen w = (labor_nocol_compensation+labor_col_compensation)/labor_hours_quantity
gen cap2lab = cap/labor_hours_quantity
drop prodshr
gen prodshr = prode/emp
rename (pimat piship piinv pien) (pimat_census piship_census piinv_census pien_census)

* BEA prices
gen pimat =  materials_compensation/materials_quantity
gen piserv =  service_compensation/services_quantity

* services intensity 
gen serv_shr2 = service_compensation / (service_compensation+materials_compensation+energy_compensation)

* Logs used by the dependent variable, treatment and reported controls
qui foreach var of varlist labshr pimat piserv piinv_census w cap2lab {
	gen l`var' = log(`var')
}

 
* base levels
qui foreach var of varlist value_added mat2va {
	bys ind_code (year): gen `var'_90 = `var' if year==1990
	bys ind_code (year): ereplace `var'_90 = max(`var'_90)
}

gen treat = mat2vadd_90*lpimat
egen naics_numeric = group(ind_code)

* ======================================================================
* run regressions and create table
* ======================================================================

* define variables and conditions for regression
global yvar llabshr 
global xvar treat 
global w value_added_90
global commoncontrols lw lpiinv_census
global extracontrols1 lcap2lab prodshr 
global extracontrols2 lcap2lab prodshr impen impen_china
global extracontrols3 serv_shr2 
global extracontrols4 serv_shr2 lpiserv 
global fe ind_code year
global iv shift_share_ct
global cond if !missing(shift_share_ct) & inrange(year,1991,2018)

label variable treat "Materials Intensity × Log. Materials Price"
label variable serv_shr2 "Sourced Services Share "
label variable lpiserv "Log. Services Price Index "



* create table
eststo clear
*FE: ols
qui eststo: reghdfe ${yvar} ${xvar} ${commoncontrols} ${cond} , absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "No"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"


*FE: 2sls unweighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond}, absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "No"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"

*FE: 2sls weighted
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${cond} [aw=${w}], absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "No"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"

*FE: 2sls weighted with additional variables
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols1} ${cond} [aw=${w}], absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "No"
qui estadd local FE "Yes"

*FE: 2sls weighted with additional variables + import penetration (subset of industries)
qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${cond} [aw=${w}], absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local FE "Yes"

qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${extracontrols3} ${cond} [aw=${w}], absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local FE "Yes"

qui eststo: ivreghdfe ${yvar} (${xvar} = ${iv}) ${commoncontrols} ${extracontrols2} ${extracontrols3} ${extracontrols4} ${cond} [aw=${w}], absorb(${fe}) cluster(naics_numeric) nocons
qui estadd local Weighted "Yes"
qui estadd local commoncontrols "Yes"
qui estadd local extracontrols1 "Yes"
qui estadd local extracontrols2 "Yes"
qui estadd local FE "Yes"



esttab using "output/tables/tabC7.tex", ///
    title("The Eﬀect of Material Prices on the Labor Share - BEA Subsectors" ) ///
	mtitle("OLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS" "2SLS") ///
    nocons se ///
    s(widstat  N commoncontrols extracontrols1 extracontrols2 FE Weighted , labels("First-stage F-stat (KP-Wald)" "\hline N" "Average Wage and Investment Price Controls" "Production Workers Share and K/L Ratio Controls" "Import Penetration Controls " "BEA Subsector and Year FE " "Weighted" )) ///
    replace ///
	fragment ///
	prefoot("\\ \hline") posthead("\hline \hline") postfoot("\hline") ///
	tex label depvar nonotes gaps keep(treat serv_shr2 lpiserv) lines star(* 0.10 ** 0.05 *** 0.01) mgroups( "" "" "\multicolumn{3}{c}{Log Industry Labor Share}" "" "\\ \cline{2-8} %"  , pattern(1 1 1 1 1 1 1 1))
	



