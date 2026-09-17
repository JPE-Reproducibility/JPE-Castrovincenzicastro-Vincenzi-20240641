* =======================================================================
* PROGRAM: Build the two quantitative-model input CSVs from archived BEA data.
* Run from the Replication package root:
*     do "do/setup.do"
*     do "do/data_cleaning/model_inputs.do"
* Inputs: data/raw/model_inputs/ (five unmodified historical workbooks).
* Scratch: data/temp/model_inputs/; outputs: quant_model/data/.
* Source URLs, worksheet identifiers, and vintages are recorded in README.pdf.
* This build uses the supplied vintage and never downloads or changes raw data.
* =======================================================================

version 19.0
clear all
set more off
local previous_storage_type "`c(type)'"
set type float

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

* Use the current package root, including when running from a copied package.
local package_root "`c(pwd)'"
confirm file "`package_root'/quant_model/main.jl"
local raw_data "`package_root'/data/raw/model_inputs"
local int_data "`package_root'/data/temp/model_inputs"
local final_data "`package_root'/quant_model/data"
cap mkdir "`package_root'/data/temp"
cap mkdir "`int_data'"
cap mkdir "`final_data'"

* Extract the required worksheets to the intermediate-data folder.
import excel "`raw_data'/income_emp_tab.xlsx", sheet("T60200D-A")  clear
export excel "`int_data'/Comp_of_empl.xlsx", replace

import excel "`raw_data'/income_emp_tab.xlsx", sheet("T60600D-A")  clear
export excel "`int_data'/wages.xlsx", replace

import excel "`raw_data'/gross_output_tab.xlsx", sheet("TGO103-A")  clear
export excel "`int_data'/Gross_output_ind.xlsx", replace

import excel "`raw_data'/gross_output_tab.xlsx", sheet("TGO105-A")  clear
export excel "`int_data'/Gross_output.xlsx", replace

import excel "`raw_data'/int_input_tab.xlsx", sheet("TII105-A")  clear
export excel "`int_data'/materials.xlsx", replace

import excel "`raw_data'/int_input_tab.xlsx", sheet("TII104-A")  clear
export excel "`int_data'/materials_prices.xlsx", replace

import excel "`raw_data'/value_added_tab.xlsx", sheet("TVA105-A")  clear
export excel "`int_data'/Value_added.xlsx", replace

import excel "`raw_data'/fixed_assets_tab.xlsx", sheet("FAAt301ESI-A")  clear
export excel "`int_data'/Current_cost_capital.xlsx", replace

import excel "`raw_data'/fixed_assets_tab.xlsx", sheet("FAAt302ESI-A")  clear
export excel "`int_data'/real_capital.xlsx", replace

import excel "`raw_data'/fixed_assets_tab.xlsx", sheet("FAAt304ESI-A")  clear
export excel "`int_data'/depreciation.xlsx", replace

import excel "`raw_data'/fixed_assets_tab.xlsx", sheet("FAAt307ESI-A")  clear
export excel "`int_data'/Investment.xlsx", replace

import excel "`raw_data'/fixed_assets_tab.xlsx", sheet("FAAt308ESI-A")  clear
export excel "`int_data'/Investment_ind.xlsx", replace


cd "`int_data'"


* Loop over filenames
foreach filename in Comp_of_empl Current_cost_capital depreciation Gross_output Gross_output_ind Investment Investment_ind materials materials_prices real_capital wages Value_added{
	
	* Set a local to indicate it is the first iteration of the next loop
	local first = 1

* Loop over sub industries
	foreach x in "Manufacturing" "Durable goods" "Wood products" "Nonmetallic mineral products" "Primary metals" "Fabricated metal products" "Machinery" "Computer and electronic products" "Electrical equipment, appliances, and components" "Motor vehicles, bodies and trailers, and parts" "Other transportation equipment" "Furniture and related products" "Miscellaneous manufacturing" "Nondurable goods" "Food and beverage and tobacco products" "Textile mills and textile product mills" "Apparel and leather and allied products" "Paper products" "Printing and related support activities" "Petroleum and coal products" "Chemical products" "Plastics and rubber products" {
		
		* Clean industry name so that stata can use them as var names
		local cleanname = subinstr("`x'", " ", "_", .)
		local cleanname = subinstr("`cleanname'", ",", "_", .)
		local cleanname = lower("`cleanname'")
		local cleanname = substr("`cleanname'", 1, 10)
		
		* Import and clean raw data
		import excel "`filename'.xlsx", cellrange(B5) firstrow clear
		drop if _n <= 2
		drop if _n >= 80
		replace B = "year" if _n ==1
		replace B = trim(B)
		destring _all, replace
		keep if B == "`x'" | B == "year"
		assert B == "year" in 1
		assert B == "`x'" in 2
		* Some sheets repeat aggregate labels for other industry groups later.
		* Retain the first matching entry, which is in the manufacturing section.
		keep in 1/2
		xpose, clear
		drop if _n == 1
		rename v1 year
		rename v2 a`cleanname'
		label variable a`cleanname' "`x'"
		keep if year>1997
		keep if year<2024
		
		assert _N == 26
		isid year
		
		reshape long a, i(year) j(sector) string
		rename a `filename'
		
		replace sector = "`x'"		
		* For the first industry, keep dataset in memory as master
		if `first' == 1 {
			save `filename', replace
			local first = 0
		}
		* For other industries append the master file
		else {
			tempfile tempdata
			save "`tempdata'", replace
			use `filename', clear
			append using "`tempdata'"
			save `filename', replace
		}
	}

}


* Merge datasets for all vars of interest
clear all

cd "`int_data'"

use Comp_of_empl


foreach x in Current_cost_capital depreciation Gross_output_ind Gross_output Investment_ind Investment materials_prices materials real_capital Value_added wages{
	merge 1:1 year sector using `x', assert(match) nogen
}


rename Comp_of_empl Comp
rename Current_cost_capital Capitalmil
rename depreciation Dep
rename Gross_output GOmil
rename Gross_output_ind GO_ind
rename Investment_ind Inv_ind
rename Investment Investmentmil
rename materials_prices Pm
rename materials Mat
rename real_capital	Cap_ind
rename Value_added VA
rename wages Wage
rename sector sector_name
encode sector_name, gen(sector)
label drop sector

assert Capitalmil > 0 & !missing(Capitalmil)
replace Dep = Dep/Capitalmil

ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    assert !missing(`v')
    replace `v' = round(`v', .001)
}


isid sector year
assert _N == 572
bysort sector_name: assert _N == 26
sort sector_name year 

export delimited "`final_data'/subsector_data.csv", replace


keep if sector_name == "Manufacturing"
assert _N == 26

export delimited "`final_data'/data_manufacturing.csv", replace

* Leave the working directory ready for the next master-script stage.
cd "`package_root'"
set type `previous_storage_type'
