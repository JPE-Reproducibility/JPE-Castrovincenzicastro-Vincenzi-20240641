* =======================================================================
* PROGRAM:			create ss instrument
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

*===========================================================================
* Create ss instrument
*===========================================================================


* Load Commodity Prices
use "data/dta/IOLinkages.dta", replace
joinby commodity using "data/dta/Commodity_Prices_Weight_comtrade_new.dta"

* Renormalizing share_sums1 such that it sums to 1
bysort industry: egen share_sums_total = total(use_value) if year == 2000
gen share_sums1 = use_value/share_sums_total
bysort industry commodity: ereplace share_sums1 = max(share_sums1)

* Sort by year and commodity before constructing the instruments.
sort year commodity

* compute ss
gen shift = log(ind_tuv/100)
gen shift_share = share*shift
gen shift_share_sums1 = share_sums1*shift
gen shift_share_leontieff = share_leontieff*shift

gen shift_share_energy = 0
replace shift_share_energy = shift_share if energy == 1


gen shift_share_notenergy = 0
replace shift_share_notenergy = shift_share if energy == 0


drop share_sums_total

collapse (sum) share* shift_share* , by(year industry)
drop share_sums1
drop share_leontieff

sort industry year

* Merging NAICS codes crosswalk
replace industry=substr(industry, 1,6)
joinby industry using "data/raw/Concordances/IOT_NAICS.dta"

isid naics year
keep naics year share* shift_share*

rename (share shift_share shift_share_sums1 shift_share_leontieff ///
        shift_share_energy shift_share_notenergy) ///
       (share_ct shift_share_ct shift_share_sums1_ct shift_share_leontieff_ct ///
        shift_share_e_ct shift_share_ne_ct)
		
save "data/dta/shiftshare_ct.dta", replace

