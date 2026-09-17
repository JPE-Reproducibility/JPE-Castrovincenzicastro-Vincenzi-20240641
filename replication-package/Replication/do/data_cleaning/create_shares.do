* =======================================================================
* PROGRAM:			create shares
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

set matsize 11000

* ======================================================================
* Create Shares
* ======================================================================

import delimited "data/raw/census/NAICSUseDetail.txt", clear

rename v1 commodity
rename v2 industry
rename v3 Year
rename v4 refnum
rename v5 use_value
rename v6 margins
rename v7 railcost
rename v8 truckcost
rename v9 watercost
rename v10 aircost
rename v11 oilpipecost
rename v12 gaspipecost
rename v13 wholesale
rename v14 retail
rename v15 purchaser

* Verify that margins (transportation costs, wholesale and retail margins) are a component of use values
assert sign(margins) == sign(use_value) if margins != 0
assert abs(margins) <= abs(use_value) + 1

/* industries with negative use value:
491000 - Postal service
532230 - Video tape and disc rental
F01000 - Personal consumption expenditures
F02000 - Private fixed investment
F03000 - Change in private inventories
F05000 - Exports of goods and services
F06C00 - Imports of goods and services
F06I00 - Federal government national defense: gross investment
F07C00 - Federal government nondefense: consumption expenditures
F07I00 - Federal government national defense: gross investment
F08C00 - State and local government education:gross investment
F09C00 - State and local government other: consumption expenditures
S00201 - State and local government passenger transit
*/

gen compensation = use_value if commodity == "V00100 "
bys industry: ereplace compensation = mean(compensation)

drop if inlist( substr(industry,1,1) , "F", "S", "V" )
drop if inlist( substr(commodity,1,1) , "F", "S", "V" )

* Keeping variables of interest
keep Year commodity industry use_value compensation

* Note that industry-commodity pairs uniquely identify observations
bysort commodity industry: assert _N == 1

* Filling Panel
fillin industry commodity
replace use_value = 0 if _fillin==1

* Creating Shares
bys industry: ereplace compensation = mean(compensation)
bysort industry: egen industry_sum = total(use_value)
gen share = use_value/(industry_sum+compensation)


* Direct commodity-input expenditure divided by total intermediate expenditure plus compensation.

tempfile direct_exp
save "`direct_exp'.dta", replace




* ======================================================================
* Construct direct and indirect input-exposure shares.
* ======================================================================


* Use file

import delimited "data/raw/census/NAICSUseDetail.txt", clear

rename v1 commodity
rename v2 industry
rename v3 Year
rename v4 refnum
rename v5 use_value
rename v6 margins
rename v7 railcost
rename v8 truckcost
rename v9 watercost
rename v10 aircost
rename v11 oilpipecost
rename v12 gaspipecost
rename v13 wholesale
rename v14 retail
rename v15 purchaser

* Verify that margins (transportation costs, wholesale and retail margins) are a component of use values
assert sign(margins) == sign(use_value) if margins != 0
assert abs(margins) <= abs(use_value) + 1

/* industries with negative use value:
491000 - Postal service
532230 - Video tape and disc rental
F01000 - Personal consumption expenditures
F02000 - Private fixed investment
F03000 - Change in private inventories
F05000 - Exports of goods and services
F06C00 - Imports of goods and services
F06I00 - Federal government national defense: gross investment
F07C00 - Federal government nondefense: consumption expenditures
F07I00 - Federal government national defense: gross investment
F08C00 - State and local government education:gross investment
F09C00 - State and local government other: consumption expenditures
S00201 - State and local government passenger transit
*/

gen compensation = use_value if commodity == "V00100 "
bys industry: ereplace compensation = mean(compensation)

drop if inlist( substr(industry,1,1) , "F", "S", "V" )
drop if inlist( substr(commodity,1,1) , "F", "S", "V" )

* Keeping variables of interest
keep commodity industry use_value compensation

fillin commodity industry

replace use_value = 0 if use_value==.

gen test = ( commodity == industry )
bys industry: egen test_down = max(test)
bys commodity: egen test_up = max(test)
tab test_up
tab test_down
keep if test_down == test_up

unique commodity
unique industry

egen industry_down = group( industry )
egen industry_up = group( commodity )
keep commodity industry_up industry industry_down use_value compensation

bys industry: ereplace compensation = mean(compensation)
bysort industry: egen industry_sum = total(use_value)

*With compensation
gen share = use_value/(industry_sum+compensation)

assert use_value<industry_sum
assert share<1




preserve
	collapse (mean) industry_up , by(commodity)
	tempfile up_code
	save "`up_code'.dta", replace
restore


keep industry_up industry industry_down share
sort industry_up industry_down
quietly levelsof industry_down, clean local(codes)


reshape wide share, i(industry_down) j(industry_up)

mkmat share*, matrix(A)

* Compute direct and indirect requirements as A * inverse(I - A).
mat leontief = A*inv(I(450) - A) 
mat rownames leontief = `codes'
mat colnames leontief = `codes'

drop share*
svmat leontief, names(matcol)
reshape long leontief, i(industry_down) j(leontiefr)
rename leontief share_leontieff
rename leontiefr industry_up

merge m:1 industry_up using "`up_code'.dta", keepus(commodity) nogen

keep commodity share_leontieff industry 

tempfile indirect_exp
save "`indirect_exp'.dta", replace


use "`direct_exp'.dta", replace

merge 1:1 commodity industry using "`indirect_exp'.dta", nogen

replace share_leontieff = 0 if share_leontieff == .


save "data/dta/IOLinkages.dta", replace
