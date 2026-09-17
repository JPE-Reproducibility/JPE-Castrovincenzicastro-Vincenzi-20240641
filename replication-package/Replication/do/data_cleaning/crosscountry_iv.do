* =======================================================================
* PROGRAM:          Build cross-country shift-share IV for materials prices
*                   (mirrors create_ss_instrument.do for the US)
* DATE:             March 2026
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

global wiod_dir "$path/data/raw/EUKLEMS/WIOD"

* ======================================================================
* Define WIOD sector codes (56 sectors, ISIC Rev.4)
* Note: Stata import excel strips dashes from firstrow variable names
*       e.g. "C10-C12" → "C10C12", but underscores are kept
* ======================================================================
* These are the Stata variable names after import excel firstrow:
* (dashes removed, underscores kept)
local wiod_vars "A01 A02 A03 B C10C12 C13C15 C16 C17 C18 C19 C20 C21 C22 C23 C24 C25 C26 C27 C28 C29 C30 C31_C32 C33 D35 E36 E37E39 F G45 G46 G47 H49 H50 H51 H52 H53 I J58 J59_J60 J61 J62_J63 K64 K65 K66 L68 M69_M70 M71 M72 M73 M74_M75 N O84 P85 Q R_S T U"

* These are the actual WIOD codes (with dashes where applicable):
local wiod_codes `""A01" "A02" "A03" "B" "C10-C12" "C13-C15" "C16" "C17" "C18" "C19" "C20" "C21" "C22" "C23" "C24" "C25" "C26" "C27" "C28" "C29" "C30" "C31_C32" "C33" "D35" "E36" "E37-E39" "F" "G45" "G46" "G47" "H49" "H50" "H51" "H52" "H53" "I" "J58" "J59_J60" "J61" "J62_J63" "K64" "K65" "K66" "L68" "M69_M70" "M71" "M72" "M73" "M74_M75" "N" "O84" "P85" "Q" "R_S" "T" "U""'

* WIOD ISO3 codes and corresponding 2-letter EU-KLEMS codes
local wiod_countries "AUS AUT BEL BGR BRA CAN CHE CHN CYP CZE DEU DNK ESP EST FIN FRA GBR GRC HRV HUN IDN IND IRL ITA JPN KOR LTU LUX LVA MEX MLT NLD NOR POL PRT ROU RUS SVK SVN SWE TUR TWN USA"
local euklems_codes  "AU  AT  BE  BG  BR  CA  CH  CN  CY  CZ  DE  DK  ES  EE  FI  FR  UK  EL  HR  HU  ID  IN  IE  IT  JP  KR  LT  LU  LV  MX  MT  NL  NO  PL  PT  RO  RU  SK  SI  SE  TR  TW  US"


* ======================================================================
* PART 1: Extract WIOD IO shares for year 2000
*         → wiod_io_shares_2000.dta
*         (parallels IOLinkages.dta in the US analysis)
* ======================================================================

di as text _n "=============================================="
di as text "Part 1: Extracting WIOD IO shares (year 2000)"
di as text "=============================================="

tempfile all_shares
save "`all_shares'", emptyok replace

local ncountries : word count `wiod_countries'

forvalues c = 1/`ncountries' {
    local iso3 : word `c' of `wiod_countries'
    local cc   : word `c' of `euklems_codes'

    di as text "  Processing `iso3' (`cc')..." _continue

    cap {
        qui import excel "$wiod_dir/`iso3'_NIOT_nov16.xlsx", ///
            sheet("National IO-tables") firstrow clear

        * Drop description row (row 2 in Excel = obs 1 in Stata after firstrow)
        drop in 1

        * Destring sector columns only (not Code/Description/Origin which are strings)
        foreach s of local wiod_vars {
            cap qui destring `s', replace force
        }
        cap qui destring CONS_h CONS_np CONS_g GFCF INVEN EXP GO, replace force

        * Keep year 2000 only
        qui keep if Year == 2000

        * Keep only the 56 industry rows (Domestic + Imports; drop summary rows)
        gen byte _keep = 0
        foreach s of local wiod_codes {
            qui replace _keep = 1 if strtrim(Code) == "`s'"
        }
        qui keep if _keep == 1
        drop _keep

        * Sum Domestic + Imports to get total flows per supplying sector
        * (industry rows only have Origin = "Domestic" or "Imports", not "TOT")
        drop Origin Description

        * Keep supplying sector code and the 56 using-sector columns
        rename Code supplying_sector
        replace supplying_sector = strtrim(supplying_sector)

        * Drop non-sector columns
        cap drop Year
        cap drop CONS_h CONS_np CONS_g GFCF INVEN EXP GO

        * Collapse to sum Domestic + Imports by supplying sector
        collapse (sum) `wiod_vars', by(supplying_sector)

        * Rename sector columns with flow_ prefix for reshape
        local i = 1
        foreach s of local wiod_vars {
            cap rename `s' flow_`i'
            local i = `i' + 1
        }

        * Reshape to long: each row = (supplying_sector, using_sector_num, flow)
        gen long _id = _n
        qui reshape long flow_, i(_id supplying_sector) j(sec_num)
        drop _id

        * Map sec_num back to sector code
        gen using_sector = ""
        local i = 1
        foreach s of local wiod_codes {
            qui replace using_sector = "`s'" if sec_num == `i'
            local i = `i' + 1
        }
        drop sec_num

        * Compute total intermediate inputs per using sector
        bys using_sector: egen double total_ii = total(flow_)

        * Compute IO share: share(k→j) = flow(k,j) / total_II(j)
        gen double share = flow_ / total_ii
        replace share = 0 if missing(share) | total_ii == 0

        * Keep non-zero shares to save space
        drop if share == 0

        * Add country identifier
        gen country = "`cc'"

        keep country using_sector supplying_sector share

        * Append
        append using "`all_shares'"
        qui save "`all_shares'", replace

        local n = _N
        di as text " done (`n' non-zero flows)"
    }
    if _rc != 0 {
        di as error " FAILED (rc=" _rc ")"
    }
}

use "`all_shares'", clear
di as text _n "Total IO share records: " _N
di as text "Countries: " _continue
qui tab country
di as text r(r)

save "$path/data/dta/wiod_io_shares_2000.dta", replace


* ======================================================================
* PART 2: Build HS92 → WIOD sector concordance
*         and aggregate ComTrade prices to WIOD sector level
*         → comtrade_wiod_prices.dta
*         (parallels Commodity_Prices_Weight_comtrade_new.dta)
* ======================================================================

di as text _n "=============================================="
di as text "Part 2: HS→WIOD concordance & ComTrade prices"
di as text "=============================================="

* --- Step 2a: Load HS92 → HS96 concordance ---
use "$path/data/raw/Concordances/HS696_Commodities.dta", clear
keep HS92 HS96
duplicates drop
tempfile hs92_hs96
save "`hs92_hs96'"

* --- Step 2b: Load HS96 → ISIC Rev.3 concordance (from WITS) ---
import delimited "$wiod_dir/JobID-19_Concordance_H1_to_I3.CSV", clear varnames(1)

* Standardize variable names (WITS file has spaces in column names)
cap rename hs1996productcode HS96
cap rename isicrevision3productcode ISIC3
* Alternate column names used by some WITS exports
cap rename v1 HS96
cap rename v3 ISIC3
* Otherwise identify the columns by position
ds
local allvars `r(varlist)'
local hs_var : word 1 of `allvars'
local isic_var : word 3 of `allvars'
cap confirm variable HS96
if _rc != 0 {
    rename `hs_var' HS96
    rename `isic_var' ISIC3
}

keep HS96 ISIC3
destring HS96 ISIC3, replace force
drop if missing(HS96) | missing(ISIC3)

* Map ISIC3 4-digit → 2-digit → WIOD sector
gen isic3_2d = floor(ISIC3/100)
tostring isic3_2d, replace
replace isic3_2d = "0" + isic3_2d if length(isic3_2d) == 1

gen wiod_sector = ""
replace wiod_sector = "A01"      if isic3_2d == "01"
replace wiod_sector = "A02"      if isic3_2d == "02"
replace wiod_sector = "A03"      if isic3_2d == "05"
replace wiod_sector = "B"        if inlist(isic3_2d, "10", "11", "12", "13", "14")
replace wiod_sector = "C10-C12"  if inlist(isic3_2d, "15", "16")
replace wiod_sector = "C13-C15"  if inlist(isic3_2d, "17", "18", "19")
replace wiod_sector = "C16"      if isic3_2d == "20"
replace wiod_sector = "C17"      if isic3_2d == "21"
replace wiod_sector = "C18"      if isic3_2d == "22"
replace wiod_sector = "C19"      if isic3_2d == "23"
replace wiod_sector = "C20"      if isic3_2d == "24"
* Split pharma out of ISIC3-24: ISIC3 4-digit 2423 = pharmaceuticals → C21
replace wiod_sector = "C21"      if ISIC3 == 2423
replace wiod_sector = "C22"      if isic3_2d == "25"
replace wiod_sector = "C23"      if isic3_2d == "26"
replace wiod_sector = "C24"      if isic3_2d == "27"
replace wiod_sector = "C25"      if isic3_2d == "28"
replace wiod_sector = "C28"      if isic3_2d == "29"
replace wiod_sector = "C26"      if inlist(isic3_2d, "30", "32", "33")
replace wiod_sector = "C27"      if isic3_2d == "31"
replace wiod_sector = "C29"      if isic3_2d == "34"
replace wiod_sector = "C30"      if isic3_2d == "35"
replace wiod_sector = "C31_C32"  if isic3_2d == "36"
replace wiod_sector = "E37-E39"  if isic3_2d == "37"
replace wiod_sector = "D35"      if isic3_2d == "40"
replace wiod_sector = "E36"      if isic3_2d == "41"

drop if wiod_sector == ""

keep HS96 wiod_sector
duplicates drop

tempfile hs96_wiod
save "`hs96_wiod'"

* --- Step 2c: Chain HS92 → HS96 → WIOD ---
use "`hs92_hs96'", clear
joinby HS96 using "`hs96_wiod'"
keep HS92 wiod_sector
duplicates drop

* Flag energy HS codes (27xxxx = mineral fuels)
gen byte energy = inrange(HS92, 270000, 279999)

di as text "Concordance: " _N " HS92→WIOD mappings"
tab wiod_sector

tempfile hs_wiod_conc
save "`hs_wiod_conc'"


* --- Step 2d: Aggregate ComTrade prices to WIOD sector level ---
di as text _n "Loading ComTrade HS-level data..."
use "$path/data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11.dta", clear

* The saved input price index is ind_tuv (1997 = 100); it is used as ind_tuv_ct below.
cap confirm variable ind_tuv_ct
if _rc != 0 {
    * Normalize the saved input name
    cap confirm variable ind_tuv
    if _rc == 0 {
        rename ind_tuv ind_tuv_ct
    }
}

keep year HS92 ind_tuv_ct
drop if missing(ind_tuv_ct) | missing(HS92) | missing(year)
destring HS92, replace force

* Merge with concordance: HS92 codes can map to multiple WIOD sectors
joinby HS92 using "`hs_wiod_conc'"

di as text "After concordance merge: " _N " rows"

* Compute the unweighted mean of matched HS price indices within each WIOD sector and year.
collapse (mean) ind_tuv = ind_tuv_ct (max) energy (count) n_hs = HS92, ///
    by(wiod_sector year)

* Interpolate missing years within each WIOD sector
* Some sectors have gaps in ComTrade coverage; fill by linear interpolation
* so that the shift-share IV has consistent coverage across years.
qui count
local pre_interp = r(N)
* Create balanced panel of sector × year
qui levelsof wiod_sector, local(sectors)
qui sum year
local ymin = r(min)
local ymax = r(max)
tempfile _prices_raw
save "`_prices_raw'"

clear
local nobs = 0
foreach s of local sectors {
    local ny = `ymax' - `ymin' + 1
    local nobs = `nobs' + `ny'
}
set obs `nobs'
gen wiod_sector = ""
gen year = .
local row = 1
foreach s of local sectors {
    forvalues y = `ymin'/`ymax' {
        qui replace wiod_sector = "`s'" in `row'
        qui replace year = `y' in `row'
        local row = `row' + 1
    }
}
merge 1:1 wiod_sector year using "`_prices_raw'", nogen

* Linear interpolation of ind_tuv within each sector
sort wiod_sector year
by wiod_sector: ipolate ind_tuv year, gen(ind_tuv_ip)
qui count if missing(ind_tuv) & !missing(ind_tuv_ip)
di as text "Interpolated " r(N) " missing sector-year price observations"
replace ind_tuv = ind_tuv_ip if missing(ind_tuv)
drop ind_tuv_ip

* Fill energy flag for interpolated rows
bys wiod_sector: egen _energy_max = max(energy)
replace energy = _energy_max if missing(energy)
drop _energy_max

* Drop sector-year rows whose prices remain missing after interpolation.
drop if missing(ind_tuv)

* Compute log shift (as in create_ss_instrument.do: shift = log(ind_tuv/100))
gen double shift = log(ind_tuv / 100)

qui count
di as text "Sector-level prices: " r(N) " rows (was `pre_interp' before interpolation)"
tab wiod_sector

save "$path/data/dta/comtrade_wiod_prices.dta", replace


* ======================================================================
* PART 3: Compute shift-share IV
*         → crosscountry_iv.dta
*         (parallels shiftshare_ct.dta in the US analysis)
* ======================================================================

di as text _n "=============================================="
di as text "Part 3: Computing shift-share IV"
di as text "=============================================="

* Load IO shares
use "$path/data/dta/wiod_io_shares_2000.dta", clear

* Join commodity prices by supplying sector
* (parallels: joinby commodity using "Commodity_Prices_Weight_comtrade_new.dta")
rename supplying_sector wiod_sector
joinby wiod_sector using "$path/data/dta/comtrade_wiod_prices.dta"
rename wiod_sector supplying_sector

* Note: After joinby, only supplying sectors with matched commodity prices
* remain, so IO shares sum to less than 1. We do NOT renormalize -- this
* mirrors the US shift-share instrument in Section 3, where shares capture both
* composition and overall commodity exposure.

* --- Rescale shares to match US definition: M_{jk}/(M_j + W_j) ---
* Current shares are M_{jk}/M_j. Scale by M_j/(M_j + W_j) = ii/(ii+comp)
* using year-2000 compensation from KLEMS panel.
gen indcode = ""
replace indcode = "C10-C12" if using_sector == "C10-C12"
replace indcode = "C13-C15" if using_sector == "C13-C15"
replace indcode = "C16-C18" if inlist(using_sector, "C16", "C17", "C18")
replace indcode = "C19"     if using_sector == "C19"
replace indcode = "C20"     if using_sector == "C20"
replace indcode = "C21"     if using_sector == "C21"
replace indcode = "C22-C23" if inlist(using_sector, "C22", "C23")
replace indcode = "C24-C25" if inlist(using_sector, "C24", "C25")
replace indcode = "C26"     if using_sector == "C26"
replace indcode = "C27"     if using_sector == "C27"
replace indcode = "C28"     if using_sector == "C28"
replace indcode = "C29-C30" if inlist(using_sector, "C29", "C30")
replace indcode = "C31-C33" if inlist(using_sector, "C31_C32", "C33")
replace indcode = "A01" if using_sector == "A01"
replace indcode = "A02" if using_sector == "A02"
replace indcode = "A03" if using_sector == "A03"
replace indcode = "B"   if using_sector == "B"

preserve
    * Read year-2000 compensation and intermediate expenditure from
    * klems_panel_2025.dta, produced by crosscountry_panel_build.do before this IV.
    use "$path/data/dta/klems_panel_2025.dta", clear
    keep if year == 2000
    keep country indcode comp ii
    replace indcode = subinstr(indcode, "_", "-", .)
    tempfile compdata
    save "`compdata'"
restore

replace indcode = subinstr(indcode, "_", "-", .)
merge m:1 country indcode using "`compdata'", keep(mas mat) nogen
gen double adj = ii / (ii + comp) if !missing(ii) & !missing(comp)
replace adj = 1 if missing(adj)
replace share = share * adj
drop indcode comp ii adj

* --- Merge exchange rates for FX-adjusted instrument ---
* Country codes in IO shares are already 2-letter KLEMS codes (US, UK, EL, etc.)
preserve
    use "$path/data/dta/fx.dta", clear
    keep country year fx
    * Recode BIS country codes to KLEMS codes
    replace country = "EL" if country == "GR"
    replace country = "UK" if country == "GB"
    * Normalize FX to base year 2000
    gen _fx2000 = fx if year == 2000
    bys country: egen fx_base = max(_fx2000)
    drop _fx2000
    bys country (year): replace fx_base = fx[1] if missing(fx_base)
    gen double lfx = log(fx / fx_base)
    keep country year lfx
    tempfile fxdata
    save "`fxdata'"
restore

merge m:1 country year using "`fxdata'", keep(mas mat) nogen
replace lfx = 0 if missing(lfx)  // US and countries without FX data: no adjustment

* --- Compute shift-share instruments ---
* Dollar-denominated (parallels: shift_share = share*shift in create_ss_instrument.do)
gen double shift_share = share * shift

* FX-adjusted: convert commodity prices to local currency before weighting
gen double shift_fx = shift + lfx
gen double shift_share_fx = share * shift_fx

* Energy decomposition (parallels energy/non-energy split)
gen double shift_share_energy = shift_share * energy
gen double shift_share_notenergy = shift_share * (1 - energy)

* Collapse to country × using_sector × year
* (parallels: collapse (sum) shift_share, by(year industry))
collapse (sum) shift_share shift_share_fx ///
         shift_share_energy shift_share_notenergy, ///
    by(country using_sector year)

rename (shift_share shift_share_fx shift_share_energy shift_share_notenergy) ///
       (shift_share_ct shift_share_fx_ct shift_share_e_ct shift_share_ne_ct)

* --- Map WIOD using_sector → EU-KLEMS sector code ---
gen indcode = ""
replace indcode = "A01"     if using_sector == "A01"
replace indcode = "A02"     if using_sector == "A02"
replace indcode = "A03"     if using_sector == "A03"
replace indcode = "B"       if using_sector == "B"
replace indcode = "C10-C12" if using_sector == "C10-C12"
replace indcode = "C13-C15" if using_sector == "C13-C15"
replace indcode = "C16-C18" if inlist(using_sector, "C16", "C17", "C18")
replace indcode = "C19"     if using_sector == "C19"
replace indcode = "C20"     if using_sector == "C20"
replace indcode = "C21"     if using_sector == "C21"
replace indcode = "C22_C23" if inlist(using_sector, "C22", "C23")
replace indcode = "C24_C25" if inlist(using_sector, "C24", "C25")
replace indcode = "C26"     if using_sector == "C26"
replace indcode = "C27"     if using_sector == "C27"
replace indcode = "C28"     if using_sector == "C28"
replace indcode = "C29_C30" if inlist(using_sector, "C29", "C30")
replace indcode = "C31-C33" if inlist(using_sector, "C31_C32", "C33")
replace indcode = "D35"     if using_sector == "D35"
replace indcode = "E36"     if using_sector == "E36"
replace indcode = "E37-E39" if using_sector == "E37-E39"
replace indcode = "F"       if using_sector == "F"
replace indcode = "G45"     if using_sector == "G45"
replace indcode = "G46"     if using_sector == "G46"
replace indcode = "G47"     if using_sector == "G47"
replace indcode = "H49"     if using_sector == "H49"
replace indcode = "H50"     if using_sector == "H50"
replace indcode = "H51"     if using_sector == "H51"
replace indcode = "H52"     if using_sector == "H52"
replace indcode = "H53"     if using_sector == "H53"
replace indcode = "I"       if using_sector == "I"
replace indcode = "J58"     if using_sector == "J58"
replace indcode = "J59_J60" if using_sector == "J59_J60"
replace indcode = "J61"     if using_sector == "J61"
replace indcode = "J62_J63" if using_sector == "J62_J63"
replace indcode = "K64"     if using_sector == "K64"
replace indcode = "K65"     if using_sector == "K65"
replace indcode = "K66"     if using_sector == "K66"
replace indcode = "L68"     if using_sector == "L68"
replace indcode = "M69_M70" if using_sector == "M69_M70"
replace indcode = "M71"     if using_sector == "M71"
replace indcode = "M72"     if using_sector == "M72"
replace indcode = "M73"     if using_sector == "M73"
replace indcode = "M74_M75" if using_sector == "M74_M75"
replace indcode = "N"       if using_sector == "N"
replace indcode = "O84"     if using_sector == "O84"
replace indcode = "P85"     if using_sector == "P85"
replace indcode = "Q"       if using_sector == "Q"
replace indcode = "R_S"     if using_sector == "R_S"
replace indcode = "T"       if using_sector == "T"
replace indcode = "U"       if using_sector == "U"

* Aggregate to EU-KLEMS sector level (for grouped sectors)
collapse (sum) shift_share_ct shift_share_fx_ct shift_share_e_ct shift_share_ne_ct, ///
    by(country indcode year)

label variable shift_share_ct    "Shift-share IV (dollar-denominated)"
label variable shift_share_fx_ct "Shift-share IV (FX-adjusted to local currency)"
label variable shift_share_e_ct  "Shift-share IV: energy component"
label variable shift_share_ne_ct "Shift-share IV: non-energy component"

di as text _n "Cross-country IV summary:"
di as text "  Observations: " _N
tab country
tab indcode if country == "US"
tab year if country == "US" & indcode == "C10-C12"

save "$path/data/dta/crosscountry_iv.dta", replace


* ======================================================================
* Summary
* ======================================================================
di as text _n "======================================================"
di as text "Output files:"
di as text "  wiod_io_shares_2000.dta      IO shares (country × sector × sector)"
di as text "  comtrade_wiod_prices.dta      Commodity prices (WIOD sector × year)"
di as text "  crosscountry_iv.dta           IV at EU-KLEMS sector level"
di as text "======================================================"
