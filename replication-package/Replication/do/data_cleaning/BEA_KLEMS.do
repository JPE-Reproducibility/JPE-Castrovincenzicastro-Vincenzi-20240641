* =======================================================================
* PROGRAM:			Clean BEA-BLS data
* DATE:				14 July 2025
* =======================================================================

clear all


* =======================================================================
* Define paths
* =======================================================================

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
* clean BEA KLEMS
* ======================================================================

*clean industry codes

local file "data/raw/BEA-KLEMS/BEA-BLS-industry-level-production-account-1987-2021.xlsx"
import excel using `file', clear sheet(NAICS codes) cellrange(A5:B87)
drop if missing(B)
replace B = strtrim(B)
replace A = strtrim(A)
rename A ind
rename B ind_code
save "${path}/data/temp/klems_ind_codes", replace

qui import excel using `file', describe
return list

forvalues i=3/30 {
    local sheet`i' "`r(worksheet_`i')'"
	local range`i' "`r(range_`i')'"
}

local filename "BEA_merged"

forvalues i=3/30 {

		import excel using `file', clear sheet(`"`sheet`i''"') cellrange(A2:AJ65) first
		renvarlab *, label
		foreach x of varlist _* {
			rename `x' val`x'
		}
		gen id = _n
		qui reshape long val_, i(id) j(year)
		drop id
		local name = subinstr(subinstr(lower("`sheet`i''"), "&" , "" , .) , " " , "_" , .)
		dis "`name'"
		rename val_ `name'	
		rename Industry_Description ind
		drop if `name' == .		
		* Save the first worksheet as the initial account panel.
		if `i' == 3 {
			save "${path}/data/temp/`filename'", replace
		}
		
		* Merge subsequent worksheets by year and industry.
		else {
			merge 1:1 year ind using "${path}/data/temp/`filename'", nogen
			save "${path}/data/temp/`filename'", replace
		}
		
		
}


* clean industry codes
replace ind = "Information and data processing services" if ind == "Data processing, internet publishing, and other information services"
replace ind = "Publishing industries (includes software)" if ind == "Publishing industries, except internet (includes software)"
replace ind = "Federal government" if ind == "Federal"
replace ind = "State and local government" if ind == "State and local"
merge m:1 ind using "${path}/data/temp/klems_ind_codes", nogen
drop if ind == "State and local government"
sort year ind_code
order year ind_code ind
compress
save "${path}/data/dta/BEA-BLS_klems_clean", replace
