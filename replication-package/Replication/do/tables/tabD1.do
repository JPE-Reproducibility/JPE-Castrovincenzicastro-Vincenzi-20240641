* =======================================================================
* PROGRAM:  Create Table D.1: Examples of Major Disasters and Associated Export Products
*           Writes output/tables/tabD1.tex as a LaTeX
*           fragment, to be wrapped in tabular{l|l|c|l|c|c} by the caller.
* =======================================================================
clear all
set more off

* Sample window and instrument parameters -- must match disaster_iv_construct.do
global divY1  1991
global divY2  2016
global divPct 90
global divG   0.05
global divE   0.05
global divTop 20

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

* ---------------------------------------------------------------------
* Specialist country-product pairs (BACI HS92, 1997)
* ---------------------------------------------------------------------
import delimited "data/raw/disaster_iv/disaster_iv_baci_country_codes.csv", varnames(1) clear
keep country_code country_iso3
rename country_code i
rename country_iso3 iso3
tempfile cc
save "`cc'"

import delimited "data/raw/disaster_iv/disaster_iv_baci_trade_1997.csv", varnames(1) clear
gen str6 hs6 = string(k, "%06.0f")
gen str4 hs  = substr(hs6,1,4)
merge m:1 i using "`cc'", keep(3) nogen
gcollapse (sum) exports = v, by(iso3 hs)
bysort hs:   egen double _hstot = total(exports)
gen double global_share = exports/_hstot
bysort iso3: egen double _ctot  = total(exports)
gen double export_share = exports/_ctot
keep if global_share >= $divG & export_share >= $divE
keep iso3 hs global_share export_share
tempfile spec
save "`spec'"

preserve
	keep iso3
	duplicates drop
	tempfile speccty
	save "`speccty'"
restore

* ---------------------------------------------------------------------
* Qualifying disaster events (EM-DAT)
* ---------------------------------------------------------------------
import excel "data/raw/disaster_iv/disaster_iv_emdat.xlsx", firstrow clear
keep if DisasterGroup == "Natural"
drop if inlist(DisasterType, "Epidemic", "Infestation", "Animal incident")
rename ISO iso3
gen double year   = StartYear
gen double deaths = TotalDeaths
replace deaths = 0 if missing(deaths)
keep iso3 Country year deaths DisasterType DisasterSubtype
keep if inrange(year, $divY1, $divY2)
tempfile nat
save "`nat'"

use "`nat'", clear
keep if deaths > 0
bysort iso3: egen double threshold = pctile(deaths), p($divPct)
by iso3: keep if _n==1
keep iso3 threshold
tempfile thr
save "`thr'"

use "`nat'", clear
merge m:1 iso3 using "`thr'", nogen
keep if (deaths >= threshold) & !missing(threshold)
tempfile qualifying
save "`qualifying'"

* Export the full list of countries with a qualifying disaster, which the note
* to the table states is available in the replication materials.
preserve
    gcollapse (max) threshold (count) n_qualifying = deaths, by(iso3 Country)
    gsort -n_qualifying iso3
    capture mkdir "output"
    capture mkdir "output/tables"
    export delimited iso3 Country n_qualifying threshold ///
        using "output/tables/tabD1_qualifying_countries.csv", replace
    count
    di "  tabD1: " r(N) " countries with a qualifying disaster -> output/tables/tabD1_qualifying_countries.csv"
restore

* keep only countries that are major exporters of at least one product
merge m:1 iso3 using "`speccty'", keep(3) nogen

* deadliest qualifying event per country, then the $divTop deadliest countries
gsort iso3 -deaths
by iso3: keep if _n==1
gsort -deaths
keep if _n <= $divTop
gen long rank = _n
keep rank iso3 Country year deaths DisasterSubtype
joinby iso3 using "`spec'"
gsort rank -global_share
by rank: gen byte first = (_n==1)

* ---------------------------------------------------------------------
* Display labels
* ---------------------------------------------------------------------
* Short country names where EM-DAT uses the long UN form
gen str40 cname = Country
replace cname = "Iran"       if iso3=="IRN"
replace cname = "Russia"     if iso3=="RUS"
replace cname = "Venezuela"  if iso3=="VEN"
replace cname = "Vietnam"    if iso3=="VNM"
replace cname = "Bolivia"    if iso3=="BOL"
replace cname = "Tanzania"   if iso3=="TZA"
replace cname = "South Korea" if iso3=="KOR"
replace cname = "Moldova"    if iso3=="MDA"
replace cname = "Laos"       if iso3=="LAO"
replace cname = "Syria"      if iso3=="SYR"

* Disaster label: EM-DAT subtype, except generic ground movement -> "Earthquake"
gen str40 dlabel = DisasterSubtype
replace dlabel = "Earthquake" if inlist(DisasterSubtype, "Ground movement", "")

* HS4 product names
gen str40 pname = ""
replace pname = "Bananas"                 if hs=="0803"
replace pname = "Coffee"                  if hs=="0901"
replace pname = "Tea"                     if hs=="0902"
replace pname = "Leguminous vegetables"   if hs=="0713"
replace pname = "Rice"                    if hs=="1006"
replace pname = "Crude petroleum"         if hs=="2709"
replace pname = "Refined petroleum"       if hs=="2710"
replace pname = "Petroleum gases"         if hs=="2711"
replace pname = "Leather apparel"         if hs=="4203"
replace pname = "Plywood"                 if hs=="4412"
replace pname = "Cotton yarn"             if hs=="5205"
replace pname = "Cotton fabrics"          if hs=="5209"
replace pname = "Carpets"                 if hs=="5701"
replace pname = "Men's shirts"            if hs=="6205"
replace pname = "Bed linen"               if hs=="6302"
replace pname = "Leather footwear"        if hs=="6403"
replace pname = "Textile footwear"        if hs=="6404"
replace pname = "Diamonds"                if hs=="7102"
replace pname = "Integrated circuits"     if hs=="8542"
replace pname = "Motor vehicles"          if hs=="8703"
replace pname = "Aircraft"                if hs=="8802"

* Any HS4 without a hand-written label falls back to its code, and is listed so
* the label table above can be extended.
count if pname == ""
if r(N) > 0 {
	di as error "  tabD1: HS4 codes with no product label (showing code only):"
	levelsof hs if pname=="", local(_nolab)
	di as error "  `_nolab'"
	replace pname = "HS " + hs if pname == ""
}

* ---------------------------------------------------------------------
* Write the LaTeX fragment
* ---------------------------------------------------------------------
gsort rank -global_share
capture mkdir "output"
capture mkdir "output/tables"
tempname fh
file open `fh' using "output/tables/tabD1.tex", write replace text

file write `fh' "Country & Disaster Example & Deaths & Major Export Product (HS4) & \multicolumn{1}{c|}{Global} & \multicolumn{1}{c}{Export} \\" _n
file write `fh' "& & & & \multicolumn{1}{c|}{Share (\%)} & \multicolumn{1}{c}{Share (\%)} \bigstrut[b]\\" _n
file write `fh' "\hline" _n
file write `fh' "\hline" _n

local N = _N
forvalues r = 1/`N' {
	local prod   = pname[`r'] + " (" + hs[`r'] + ")"
	local gsh    = string(100*global_share[`r'], "%4.1f")
	local esh    = string(100*export_share[`r'], "%4.1f")
	local strut  = ""
	if `r' == 1     local strut " \bigstrut[t]"
	if `r' == `N'   local strut " \bigstrut[b]"
	if first[`r'] == 1 {
		local cty = cname[`r']
		local dis = string(year[`r'], "%4.0f") + " " + dlabel[`r']
		local dth = trim(string(deaths[`r'], "%12.0fc"))
		file write `fh' "`cty' & `dis' & `dth' & `prod' & `gsh' & `esh'`strut'\\" _n
	}
	else {
		file write `fh' " & & & `prod' & `gsh' & `esh'`strut'\\" _n
	}
}
file write `fh' "\hline" _n
file close `fh'

di "  tabD1: wrote output/tables/tabD1.tex"
qui levelsof rank, local(_rk)
di "  tabD1: " wordcount("`_rk'") " countries, " _N " country-product rows"
