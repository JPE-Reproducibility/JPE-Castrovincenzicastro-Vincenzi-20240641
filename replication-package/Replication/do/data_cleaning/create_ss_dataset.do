* =======================================================================
* PROGRAM:			Build the main shift-share analysis dataset
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
* merge datasets
* ======================================================================

* Open Concordance
use "data/raw/Concordances/conc_naics97_naics12.dta", clear
keep if pay9712>0.7
rename naics97 naics


* Load NBER Industry Dataset - NAICS 1997 to map external variables to NAICS 2012
merge 1:m naics using "data/raw/NBER-CES/nberces_1958-2018.dta"
keep naics naics12 year vadd vship 
qui merge 1:1 naics year using "data/dta/shiftshare_ct", nogen
qui merge 1:1 naics year using "data/dta/imports_1989-2018_naics.dta", gen(merge_imports)
qui merge 1:1 naics year using "data/dta/exports_1989-2018_naics.dta", gen(merge_exports)


* Merge Concordance

collapse (rawsum) im* ex* (mean) share* shift* [w=vship], by(naics12 year)
ren naics12 naics

merge 1:1 naics year using "data/raw/NBER-CES/nberces-1958_2018_naics2012.dta", nogen keep(mat)
qui merge 1:1 naics year using "data/dta/concentration", gen(merge_conc)

* ======================================================================
* generate variables
* ======================================================================

*3-digit NAICS sub-sectors and interaction with year
gen naics3=int(naics/1000)
egen n3y = group(naics3 year)

* laborshare, material intensity, and material-to-labor expenditure ratio
gen labshr = pay/vadd
gen mat2va = matcost/vadd
gen mat2lab = matcost/pay

* average wage, capital-labor ratio, and production workers share
gen w = prodw/prodh
gen cap2lab = cap/prodh
gen prodshr = prode/emp

* Concentration ratios arrive from Census in percent. Convert all four to
* fractions of sales
foreach v of varlist cr4 cr8 cr20 cr50 {
	replace `v' = `v'/100
}



*import penetration
gen impen = im/(vship + im - ex)
gen impen_china = im_china/(vship + im - ex)

* take logs
qui foreach var of varlist mat2lab cap2lab labshr tfp* p* w hhi50{
	gen l`var' = log(`var')
}

* Reference-year values used by the main and robustness specifications
qui foreach var of varlist vadd mat2va {
	bys naics (year): gen `var'_90 = `var' if year==1990
	bys naics (year): ereplace `var'_90 = max(`var'_90)
	bys naics (year): gen `var'_58 = `var' if year==1958
	bys naics (year): ereplace `var'_58 = max(`var'_58)
	bys naics (year): gen `var'_70 = `var' if year==1970
	bys naics (year): ereplace `var'_70 = max(`var'_70)
	bys naics (year): gen `var'_72 = `var' if year==1972
	bys naics (year): ereplace `var'_72 = max(`var'_72)
	bys naics (year): gen `var'_80 = `var' if year==1980
	bys naics (year): ereplace `var'_80 = max(`var'_80)
	bys naics (year): gen `var'_97 = `var' if year==1997
	bys naics (year): ereplace `var'_97 = max(`var'_97)
}

* generate regressor 

gen treat = mat2va_90*lpimat



save "data/dta/mainregfile.dta", replace
