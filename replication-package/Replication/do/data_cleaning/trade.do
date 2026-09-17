* =======================================================================
* PROGRAM:			clean trade data
* DATE:				14 July 2025
* =======================================================================

clear all

* ======================================================================
* individual paths
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
* clean import data
* ======================================================================

* First pass to initialize dataset
local first = 1

foreach yr of numlist 89/118 {
    use "data/raw/trade/imp_detl_yearly_`yr'n", clear

    * Keep only manufacturing data
    keep if substr(naics,1,1) == "3"

    * Rename and generate variables
    rename gen_val_yr im
    gen im_china = im * (cty_code == 5700)
    gen im_nafta = im * inlist(cty_code, 2010, 1220)

    * Collapse data
    gcollapse (rawsum) im im_china im_nafta, by(year naics)
	
	foreach var in im im_china im_nafta {

	replace `var'=`var'/1000000

}
	rename naics naics_string
	destring naics_string, gen(naics) force
	drop if naics == .

    * Append to the main dataset
    if `first' {
        save "data/dta/imports_1989-2018_naics.dta", replace
        local first = 0
    }
    else {
        append using "data/dta/imports_1989-2018_naics.dta"
        save "data/dta/imports_1989-2018_naics.dta", replace
    }
}


* ======================================================================
* clean exports data
* ======================================================================

* First pass to initialize dataset
local first = 1

foreach yr of numlist 89/118{
	use "data/raw/trade/exp_detl_yearly_`yr'n", clear
	* Keep only manufacturing data
	keep if substr(naics,1,1)=="3" 
		
    * Rename variables
	rename all_val_yr ex
	
	*Collapse data
	gcollapse (rawsum) ex, by(year naics)
	
	replace ex=ex/1000000
	
	rename naics naics_string
	destring naics_string, gen(naics) force
	drop if naics == .

    * Append to the main dataset
	if `first' {
        save "data/dta/exports_1989-2018_naics.dta", replace
        local first = 0
    }
    else {
        append using "data/dta/exports_1989-2018_naics.dta"
        save "data/dta/exports_1989-2018_naics.dta", replace
    }
}


