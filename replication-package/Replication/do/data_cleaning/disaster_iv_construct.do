* =======================================================================
* PROGRAM:  Construct the disaster-based shift-share IV.
*           Writes data/dta/disaster_iv_data.dta
* SPEC:     HS4, deaths metric, 90th-percentile threshold (Stata egen pctile),
*           activation window t/t-1/t-2, specialist g>=5% & e>=5%,
*           shock weighted by 1997 world export share, products mapped
*           directly to I-O commodities via the BEA HS-I-O concordance.
* =======================================================================
clear all
set more off

* Appendix D sample window. Used at EM-DAT ingestion, for the country-year
* disaster panel, for the NAICS-year panel, and at the final merge. Changing it
* here changes it in all four places.
global divY1 1991
global divY2 2016

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
* BACI trade 1997 -> HS4 exports, global & export shares (exp4)
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
gen str3 country = iso3
bysort hs:   egen double _hstot = total(exports)
gen double global_share = exports/_hstot
bysort iso3: egen double _ctot  = total(exports)
gen double export_share = exports/_ctot
drop _hstot _ctot
tempfile exp4
save "`exp4'"

* ---------------------------------------------------------------------
* IO concordance + linkages
* ---------------------------------------------------------------------
use "data/raw/Concordances/IOT_NAICS.dta", clear
count
di "  NAICS->IO concordance: " r(N)
tempfile conc_io
save "`conc_io'"

use "data/dta/IOLinkages.dta", clear
keep commodity industry share
gen str6 comm_io_code = substr(commodity,1,6)
rename industry using_industry
tempfile io_data
save "`io_data'"

preserve
    keep comm_io_code
    duplicates drop
    tempfile io_codes
    save "`io_codes'"
restore

* ---------------------------------------------------------------------
* EM-DAT natural disasters -> nat (country, year, deaths)
* ---------------------------------------------------------------------
import excel "data/raw/disaster_iv/disaster_iv_emdat.xlsx", firstrow clear
keep if DisasterGroup == "Natural"
drop if inlist(DisasterType, "Epidemic", "Infestation", "Animal incident")
rename ISO iso3
gen str3 country = iso3
gen double year = StartYear
gen double deaths = TotalDeaths
replace deaths = 0 if missing(deaths)
keep country year deaths
keep if inrange(year, $divY1, $divY2)
tempfile nat
save "`nat'"

keep country
duplicates drop
count
di "  EM-DAT countries: " r(N)
tempfile ctys
save "`ctys'"

* ---------------------------------------------------------------------
* Death thresholds: 90th percentile of each country's positive-death events
* ---------------------------------------------------------------------
* Events with no reported death toll were set to zero above and are excluded
* here, so the percentile is taken over reported fatal events only.
use "`nat'", clear
keep if deaths > 0
bysort country: egen double threshold = pctile(deaths), p(90)
by country: keep if _n==1
keep country threshold
tempfile thr
save "`thr'"

* ---------------------------------------------------------------------
* Disaster dummy panel (country x year 1991-2016), activation window t/t-1/t-2
* ---------------------------------------------------------------------
use "`nat'", clear
merge m:1 country using "`thr'", nogen
gen byte flagged = (deaths >= threshold) & !missing(threshold)
gcollapse (max) flagged, by(country year)
tempfile cyflag
save "`cyflag'"

use "`ctys'", clear
gen byte _k = 1
tempfile ctys1
save "`ctys1'"
clear
local _nyr = $divY2 - $divY1 + 1
set obs `_nyr'
gen double year = $divY1 - 1 + _n
gen byte _k = 1
joinby _k using "`ctys1'"
drop _k
merge 1:1 country year using "`cyflag'", keep(1 3) nogen
replace flagged = 0 if missing(flagged)
rename flagged large_disaster
sort country year
* Activation window: a country counts as disrupted in t if it had a large
* disaster in t, t-1 or t-2. 
by country: gen byte disaster_active = large_disaster
by country: replace disaster_active = max(large_disaster, large_disaster[_n-1]) if _n>1
by country: replace disaster_active = max(disaster_active, large_disaster[_n-2]) if _n>2
keep country year disaster_active
tempfile dummy_panel
save "`dummy_panel'"

* ---------------------------------------------------------------------
* Specialists (g>=5% & e>=5%) -> HS4 shocks
* ---------------------------------------------------------------------
use "`exp4'", clear
keep if global_share>=0.05 & export_share>=0.05
keep country hs global_share
count
di "  Specialist pairs: " r(N)
joinby country using "`dummy_panel'"
gen double SH = global_share*disaster_active
gcollapse (sum) shock_hs = SH, by(hs year)
tempfile hs_shock
save "`hs_shock'"

* Step 2: HS4 shocks -> I-O commodity, using the same BEA HS-I-O concordance
* that the baseline shift-share instrument uses
use "data/raw/Concordances/HS696_to_IOT.dta", clear
gen long _hs4n = floor(HS96/100)
gen str4 hs = string(_hs4n, "%04.0f")
drop _hs4n
joinby hs using "`hs_shock'"
gen double weighted_shock = weight*shock_hs
gcollapse (sum) shock = weighted_shock, by(commodity year)
gen str6 comm_io_code = substr(commodity,1,6)
keep comm_io_code year shock
count
di "  commodity-year shocks: " r(N)

* Report shocked commodity codes absent from IOLinkages.dta.
* The following inner join excludes these codes from the constructed instrument.
preserve
    keep comm_io_code
    duplicates drop
    merge 1:1 comm_io_code using "`io_codes'", keep(1) nogen
    count
    di "  shocked commodities absent from IOLinkages: " r(N)
    if r(N) > 0 {
        list comm_io_code, noobs clean
    }
restore

* Step 3: commodity shocks -> using industries via the 1997 Use table
joinby comm_io_code using "`io_data'"
gen double io_shock = share*shock
gcollapse (sum) io_shock, by(using_industry year)

* Step 4: I-O industry -> NAICS.
gen str6 industry = substr(using_industry,1,6)
joinby industry using "`conc_io'"
gcollapse (mean) io_shock, by(naics year)
rename io_shock iv
tempfile iv_final
save "`iv_final'"

* Step 5a: convert NAICS 1997 -> NAICS 2012.
preserve
    use "data/raw/Concordances/IOT_NAICS.dta", clear
    keep naics
    duplicates drop
    gen byte _k = 1
    tempfile n97
    save "`n97'"
    clear
    local _nyr = $divY2 - $divY1 + 1
    set obs `_nyr'
    gen double year = $divY1 - 1 + _n
    gen byte _k = 1
    joinby _k using "`n97'"
    drop _k
    merge 1:1 naics year using "`iv_final'", keep(1 3) nogen
    replace iv = 0 if missing(iv)
    tempfile ivfull
    save "`ivfull'"
restore

use "data/raw/Concordances/conc_naics97_naics12.dta", clear
rename naics97 naics
merge 1:m naics using "data/raw/NBER-CES/nberces_1958-2018.dta", keep(3) nogen
keep naics naics12 year vadd vship
qui merge 1:1 naics year using "`ivfull'", nogen
collapse (mean) iv [w=vship], by(naics12 year)
rename naics12 naics
tempfile iv_final12
save "`iv_final12'"

* Step 5b: merge into naics-year skeleton
use "data/dta/mainregfile.dta", clear
keep if inrange(year,$divY1,$divY2)
keep naics year
duplicates drop
merge 1:1 naics year using "`iv_final12'", keep(1 3) nogen
replace iv = 0 if missing(iv)
rename iv div_1
order naics year div_1
count
qui count if div_1!=0
di "  IV non-zero: " r(N)
sort naics year
save "data/dta/disaster_iv_data.dta", replace
di "Disaster IV saved to data/dta/disaster_iv_data.dta"
