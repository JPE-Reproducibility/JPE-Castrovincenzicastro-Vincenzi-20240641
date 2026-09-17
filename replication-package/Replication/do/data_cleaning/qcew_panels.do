* =======================================================================
* PROGRAM:			construct data/dta/QCEW_naics4_panel.dta
*					          data/dta/QCEW_naics2_panel.dta
* DATE:				24 July 2026
* =======================================================================


clear all
set more off

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

local firstyear = 1990
local lastyear  = 2020

local csvdir "data/raw/regional_data/QCEW"
local czfile "data/raw/Concordances/cty_czone.dta"

* ======================================================================
* initialise the two accumulators
* ======================================================================

tempfile n4 n2 yr

clear
save "`n4'", emptyok replace
clear
save "`n2'", emptyok replace

* ======================================================================
* loop over years
* ======================================================================

forvalues y = `firstyear'/`lastyear' {

	di as text _n "{hline 60}" _n "QCEW `y'" _n "{hline 60}"

	capture confirm file "`csvdir'/`y'.annual.singlefile.csv"
	if _rc != 0 {
		di as error "missing csv for `y' -- skipping"
		continue
	}

	* --- read ----------------------------------------------------------
	import delimited "`csvdir'/`y'.annual.singlefile.csv", varnames(1) clear

	keep area_fips own_code industry_code agglvl_code year ///
		 annual_avg_estabs annual_avg_emplvl total_annual_wages ///
		 annual_avg_wkly_wage

	* area_fips and industry_code hold non-numeric values (MSA/national
	* codes; sector codes such as "31-33"), so they normally import as
	* strings. Force it in case a given vintage reads as numeric.
	capture confirm string variable area_fips
	if _rc != 0 tostring area_fips, replace format(%05.0f)
	capture confirm string variable industry_code
	if _rc != 0 tostring industry_code, replace

	* --- steps 1-4: row selection --------------------------------------
	keep if own_code == 5
	keep if inlist(agglvl_code, 74, 76)
	drop if strpos(area_fips, "999")
	drop if annual_avg_emplvl == 0

	* --- step 5: county -> 1990 commuting zone -------------------------
	destring area_fips, gen(fips) force
	merge m:1 fips using "`czfile'", keepusing(cz1990) keep(master match) nogen

	save "`yr'", replace

	* --- step 6a: NAICS 4-digit panel ----------------------------------
	use "`yr'", clear
	keep if agglvl_code == 76
	rename industry_code naics4
	gcollapse (rawsum) emp = annual_avg_emplvl        ///
	                   est = annual_avg_estabs        ///
	                   wage = total_annual_wages      ///
	          (mean)   annual_avg_wkly_wage           ///
	          [aw = annual_avg_emplvl], by(year naics4 cz1990)
	append using "`n4'"
	save "`n4'", replace

	* --- step 6b: NAICS sector panel -----------------------------------
	use "`yr'", clear
	keep if agglvl_code == 74
	rename industry_code naics2
	gcollapse (rawsum) emp = annual_avg_emplvl        ///
	                   est = annual_avg_estabs        ///
	                   wage = total_annual_wages      ///
	          (mean)   annual_avg_wkly_wage           ///
	          [aw = annual_avg_emplvl], by(year naics2 cz1990)
	append using "`n2'"
	save "`n2'", replace
}

* ======================================================================
* finalise and save
* ======================================================================

use "`n4'", clear
order year naics4 cz1990 emp est wage annual_avg_wkly_wage
sort year naics4 cz1990
compress
save "data/dta/QCEW_naics4_panel.dta", replace
di as text "QCEW_naics4_panel.dta: " _N " obs"

use "`n2'", clear
order year naics2 cz1990 emp est wage annual_avg_wkly_wage
sort year naics2 cz1990
compress
save "data/dta/QCEW_naics2_panel.dta", replace
di as text "QCEW_naics2_panel.dta: " _N " obs"
