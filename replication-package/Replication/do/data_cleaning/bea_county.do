* =======================================================================
* PROGRAM:			construct data/dta/bea_county_gdp.dta
*					          data/dta/bea_county_otheraggdata.dta
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

global beacsvdir "data/raw/regional_data/bea_county"
global beaendyear = 2020

* ======================================================================
* helper: read a table's ALL_AREAS csv, keep counties, reshape long by
*         year, destring
* ======================================================================

capture program drop _bea_read
program define _bea_read
	args table

	* the ALL_AREAS file carries a year range in its name, so glob for it
	local flist : dir "${beacsvdir}" files "`table'__ALL_AREAS_*.csv"
	local fname ""
	foreach f of local flist {
		local fname "`f'"
	}
	if "`fname'" == "" {
		di as error "could not find `table'__ALL_AREAS_*.csv in ${beacsvdir}"
		exit 601
	}
	di as text "  reading `fname'"

	import delimited "${beacsvdir}/`fname'", varnames(1) stringcols(_all) ///
		encoding("latin1") clear

	* year columns arrive as v9, v10, ... with the year held in the
	* variable label, because "2001" is not a legal Stata name
	foreach v of varlist _all {
		local lab : variable label `v'
		if regexm("`lab'", "^(19|20)[0-9][0-9]$") rename `v' yr`lab'
	}

	* GeoFIPS is quoted and space-padded in the raw file
	replace geofips = subinstr(geofips, char(34), "", .)
	replace geofips = strtrim(geofips)
	keep if regexm(geofips, "^[0-9][0-9][0-9][0-9][0-9]$")
	drop if substr(geofips, 3, 3) == "000"

	destring geofips, gen(gcode)
	destring linecode, replace

	keep gcode linecode yr*
	greshape long yr, i(gcode linecode) j(year)
	destring yr, replace force
	keep if year <= ${beaendyear}
end

* ======================================================================
* CAGDP2 -> bea_county_gdp
* ======================================================================

di as text _n "{hline 60}" _n "CAGDP2" _n "{hline 60}"

_bea_read CAGDP2

rename yr value
greshape wide value, i(gcode year) j(linecode)
rename value# cagdp2#

order year gcode
sort year gcode
compress
save "data/dta/bea_county_gdp.dta", replace
di as text "bea_county_gdp.dta: " _N " obs"

* ======================================================================
* CAINC30 -> bea_county_otheraggdata
* ======================================================================

di as text _n "{hline 60}" _n "CAINC30" _n "{hline 60}"

_bea_read CAINC30

rename yr value
greshape wide value, i(gcode year) j(linecode)
rename value# cainc30#

order year gcode
sort year gcode
compress
save "data/dta/bea_county_otheraggdata.dta", replace
di as text "bea_county_otheraggdata.dta: " _N " obs"

