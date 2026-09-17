* =======================================================================
* PROGRAM:          Build cross-country panel from 2025 EU-KLEMS vintage
*                   (+ 2020 splice) and World KLEMS (Canada, Korea)
*                   Writes klems_panel_2025.dta before IV construction.
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


* ======================================================================
* PART 0: Clean 2025 EU-KLEMS vintage
* ======================================================================

di _n "=============================================="
di "Part 0: Cleaning 2025 EU-KLEMS vintage"
di "=============================================="

use "$path/data/raw/EUKLEMS/EUKLEMS_2025vintage_national_accounts.dta", clear

* Rename to standard names
rename geo_code country
rename nace_r2_code indcode
rename (GO_CP II_CP VA_CP) (go ii va)
rename (GO_PI II_PI VA_PI) (go_pi ii_pi va_pi)
rename (GO_PYP II_PYP VA_PYP) (go_pyp ii_pyp va_pyp)
rename (GO_Q II_Q VA_Q) (go_q ii_q va_q)
rename COMP comp
rename EMP emp
rename EMPE empe
rename H_EMP h_emp
rename H_EMPE h_empe

* Drop aggregates of countries
drop if inlist(country, "EA19", "EU15", "EU27", "EU27_2020", "EU28")
drop if inlist(country, "EU11", "EU12", "EU19", "EU20")

* ---- Splice with 2020 vintage to fill gaps ----
* Aggregate sectors are retained at this stage; the splice ratios need them

di _n "--- Splicing with 2020 EU-KLEMS vintage ---"

* Prepare 2020 vintage (long format -> wide by variable)
preserve
    use "$path/data/raw/EUKLEMS/EUKLEMS_2020vintage.dta", clear
    * Keep relevant variables
    keep if inlist(var, "II_PI", "GO_PI", "VA_PI", "COMP", "H_EMPE", "H_EMP")
    keep country code year var value
    * Harmonize sector codes: the 2020 vintage writes multi-sector NACE codes
    * with underscores where the 2025 vintage uses dashes (C22_C23 vs C22-C23).
    replace code = subinstr(code, "_", "-", .) if code != "TOT_IND"
    rename code indcode
    reshape wide value, i(country indcode year) j(var) string
    rename valueII_PI ii_pi_v20
    rename valueGO_PI go_pi_v20
    rename valueVA_PI va_pi_v20
    rename valueCOMP comp_v20
    rename valueH_EMPE h_empe_v20
    rename valueH_EMP h_emp_v20
    tempfile v20
    save "`v20'"
restore

merge 1:1 country indcode year using "`v20'", keep(mas mat)
di "2020 vintage merge:"
tab _merge
drop _merge

* Splice price indices: fill gaps from 2020 vintage
* Note: 2025 vintage stores zeros (not missing) for sectors without price data
* Treat zeros as missing for price indices
foreach pvar in ii_pi go_pi va_pi {
    replace `pvar' = . if `pvar' == 0
}

foreach pvar in ii_pi go_pi va_pi {
    * Step 1: Where overlap exists, compute splice ratio at country×industry level
    gen double _ratio = `pvar' / `pvar'_v20 if !missing(`pvar') & !missing(`pvar'_v20) & `pvar'_v20 > 0
    bys country indcode: egen double _splice_ratio = mean(_ratio)

    gen byte _filled_splice = missing(`pvar') & !missing(`pvar'_v20) & !missing(_splice_ratio)
    replace `pvar' = `pvar'_v20 * _splice_ratio if _filled_splice
    qui count if _filled_splice
    di "`pvar': filled " r(N) " obs via splice (with ratio)"

    * For country-industry pairs with at most three original 2025 observations,
    * use the 2020-vintage value wherever it is available.
    bys country indcode: egen _nv25 = total(!missing(`pvar') & !_filled_splice)
    gen byte _replace_all = _nv25 <= 3 & !missing(`pvar'_v20)
    replace `pvar' = `pvar'_v20 if _replace_all
    qui count if _replace_all & missing(`pvar') == 0
    di "`pvar': replaced " r(N) " obs with 2020 vintage (sparse 2025 coverage)"

    * Report countries with filled or replaced observations.
    tab country if _filled_splice | _replace_all

    drop _ratio _splice_ratio _filled_splice _nv25 _replace_all
}

* Fill level variables directly where 2025 is missing
foreach lvar in comp h_empe h_emp {
    gen byte _filled = missing(`lvar') & !missing(`lvar'_v20)
    replace `lvar' = `lvar'_v20 if _filled
    qui count if _filled
    di "`lvar': filled " r(N) " observations from 2020 vintage"
    drop _filled
}

* Clean up 2020 vintage variables
drop *_v20

* ---- Now drop aggregate sectors ----
drop if inlist(indcode, "TOT", "TOT_IND", "MARKT", "MARKTxAG")
drop if inlist(indcode, "C", "D-E", "C20-C21", "C26-C27")
drop if inlist(indcode, "A", "D", "E", "G", "H", "J", "K", "M", "O-Q")
drop if inlist(indcode, "M-N", "R", "S", "Q86", "Q87-Q88", "L68A", "R-S")

* Keep years <= 2019
keep if year <= 2019

* Drop if negative or zero key variables
drop if va <= 0 | ii <= 0 | comp <= 0 | emp <= 0
drop if comp > va

* Country names
gen country_name = ""
replace country_name = "Austria"          if country == "AT"
replace country_name = "Belgium"          if country == "BE"
replace country_name = "Bulgaria"         if country == "BG"
replace country_name = "Cyprus"           if country == "CY"
replace country_name = "Czech Republic"   if country == "CZ"
replace country_name = "Germany"          if country == "DE"
replace country_name = "Denmark"          if country == "DK"
replace country_name = "Estonia"          if country == "EE"
replace country_name = "Greece"           if country == "EL"
replace country_name = "Spain"            if country == "ES"
replace country_name = "Finland"          if country == "FI"
replace country_name = "France"           if country == "FR"
replace country_name = "Croatia"          if country == "HR"
replace country_name = "Hungary"          if country == "HU"
replace country_name = "Ireland"          if country == "IE"
replace country_name = "Italy"            if country == "IT"
replace country_name = "Lithuania"        if country == "LT"
replace country_name = "Luxembourg"       if country == "LU"
replace country_name = "Latvia"           if country == "LV"
replace country_name = "Malta"            if country == "MT"
replace country_name = "Netherlands"      if country == "NL"
replace country_name = "Poland"           if country == "PL"
replace country_name = "Portugal"         if country == "PT"
replace country_name = "Romania"          if country == "RO"
replace country_name = "Sweden"           if country == "SE"
replace country_name = "Slovenia"         if country == "SI"
replace country_name = "Slovak Republic"  if country == "SK"
replace country_name = "United Kingdom"   if country == "UK"
replace country_name = "Japan"            if country == "JP"
replace country_name = "USA"              if country == "US"

* ---- Merge capital accounts ----
preserve
    use "$path/data/raw/EUKLEMS/EUKLEMS_2025vintage_capital_accounts.dta", clear
    rename geo_code country
    rename nace_r2_code indcode
    keep country indcode year I_GFCF Ip_GFCF K_GFCF Kq_GFCF
    * Drop country aggregates and total-sector codes before the capital-data merge.
    drop if inlist(country, "EA19", "EU15", "EU27", "EU27_2020", "EU28")
    drop if inlist(country, "EU11", "EU12", "EU19", "EU20")
    drop if inlist(indcode, "TOT", "TOT_IND", "MARKT", "MARKTxAG")
    tempfile capdata
    save "`capdata'"
restore

merge 1:1 country indcode year using "`capdata'", keep(mas mat)
di "Capital accounts merge:"
tab _merge
drop _merge

* Generate derived variables
gen labshr = comp / va
gen mat2va = ii / va
gen w = comp / h_empe
gen pmat2pva = ii_pi / va_pi
gen cap2lab = K_GFCF / h_empe
gen piinv = Ip_GFCF

* Take logs
foreach v of varlist labshr mat2va w ii_pi va_pi go_pi pmat2pva {
    gen l`v' = log(`v')
}
gen lpiinv = log(piinv)
gen lcap2lab = log(cap2lab)

* Dummies
gen manuf = ///
    indcode == "C10-C12" | indcode == "C13-C15" | indcode == "C16-C18" | ///
    indcode == "C19" | indcode == "C20" | indcode == "C21" | ///
    indcode == "C22-C23" | indcode == "C24-C25" | ///
    indcode == "C26" | indcode == "C27" | indcode == "C28" | ///
    indcode == "C29-C30" | indcode == "C31-C33"

gen us = country == "US"
gen eu = !inlist(country, "US", "JP", "CA", "KR")

* Group identifiers
egen ci = group(country indcode)

di "EU-KLEMS 2025 vintage cleaned:"
di "  Observations: " _N
tab country if manuf

save "$path/data/dta/klems_panel_2025.dta", replace


* ======================================================================
* PART 0b: Append Canada from World KLEMS
* ======================================================================

di _n "=============================================="
di "Part 0b: Adding Canada (World KLEMS 2012)"
di "=============================================="

preserve
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Canada_2012.xlsx", sheet("DATA") firstrow clear

    * Reshape from wide (year columns) to long
    rename _* v*
    reshape long v, i(Variable code) j(year)
    rename v value
    rename Variable var
    rename code indcode

    * Keep manufacturing sectors + key variables only
    keep if inlist(var, "GO", "II", "VA", "COMP", "H_EMPE", "H_EMP", "EMP", "EMPE") | ///
           inlist(var, "II_P", "GO_P", "VA_P", "GO_Q", "VA_Q", "II_QI")

    * Keep manufacturing sectors (ISIC Rev.3 codes)
    keep if inlist(indcode, "15t16", "17t19", "20", "21t22", "23", "24", "25") | ///
           inlist(indcode, "26", "27t28", "29", "30t33", "34t35", "36t37")

    * Keep 1995-2008 (2009-2010 have missing data)
    keep if year >= 1995 & year <= 2008

    drop if missing(value)

    * Reshape to wide by variable
    reshape wide value, i(indcode year) j(var) string
    rename value* *

    * --- Map ISIC Rev.3 to NACE Rev.2 ---
    * Direct mappings (1:1):
    *   15t16    -> C10-C12  (Food, beverages, tobacco)
    *   17t19    -> C13-C15  (Textiles, apparel, leather)
    *   23       -> C19      (Coke, petroleum)
    *   27t28    -> C24-C25  (Basic & fabricated metals)
    *   29       -> C28      (Machinery)
    *   34t35    -> C29-C30  (Transport equipment)
    *   36t37    -> C31-C33  (Other manufacturing)
    *
    * Aggregation needed (sum levels, VA-weighted price indices):
    *   20 + 21t22  -> C16-C18 (Wood, paper, printing)
    *   25 + 26     -> C22-C23 (Rubber, plastics, non-metallic minerals)
    *
    * Cannot separate (map combined):
    *   24       -> C20      (Chemicals; includes pharma C21)
    *   30t33    -> C26      (Electronics; includes electrical C27)
    * Drop C21 and C27 for Canada (no separate data)

    * First, handle sectors needing aggregation
    * Tag sectors to aggregate
    gen agg_group = ""
    replace agg_group = "C16-C18" if inlist(indcode, "20", "21t22")
    replace agg_group = "C22-C23" if inlist(indcode, "25", "26")

    * For aggregated sectors: sum levels, compute VA-weighted price indices
    * Save sub-sector VA shares for price index weighting
    bys agg_group year: egen _va_sum = total(VA) if agg_group != ""
    gen _va_wt = VA / _va_sum if agg_group != ""

    * Weighted average of price indices within aggregation group
    foreach pvar in II_P GO_P VA_P {
        gen _wp_`pvar' = `pvar' * _va_wt if agg_group != ""
        bys agg_group year: egen _agg_`pvar' = total(_wp_`pvar') if agg_group != ""
    }

    * Sum levels within aggregation group
    foreach lvar in GO II VA COMP H_EMPE H_EMP EMP EMPE {
        cap confirm variable `lvar'
        if !_rc {
            bys agg_group year: egen _agg_`lvar' = total(`lvar') if agg_group != ""
        }
    }

    * Collapse aggregated sectors: keep one row per group
    * Replace values with aggregated values and recode indcode
    replace II_P  = _agg_II_P  if agg_group != ""
    replace GO_P  = _agg_GO_P  if agg_group != ""
    replace VA_P  = _agg_VA_P  if agg_group != ""
    foreach lvar in GO II VA COMP H_EMPE H_EMP EMP EMPE {
        cap confirm variable `lvar'
        if !_rc {
            replace `lvar' = _agg_`lvar' if agg_group != ""
        }
    }

    * Now keep only one observation per aggregation group (drop duplicate)
    replace indcode = agg_group if agg_group != ""
    bys indcode year: gen _seq = _n
    drop if _seq > 1 & agg_group != ""
    drop _va_sum _va_wt _wp_* _agg_* _seq agg_group

    * Remap remaining 1:1 sectors
    replace indcode = "C10-C12" if indcode == "15t16"
    replace indcode = "C13-C15" if indcode == "17t19"
    replace indcode = "C19"     if indcode == "23"
    replace indcode = "C20"     if indcode == "24"
    replace indcode = "C26"     if indcode == "30t33"
    replace indcode = "C24-C25" if indcode == "27t28"
    replace indcode = "C28"     if indcode == "29"
    replace indcode = "C29-C30" if indcode == "34t35"
    replace indcode = "C31-C33" if indcode == "36t37"

    * Rename to match EU-KLEMS variable names
    rename (GO II VA COMP H_EMPE H_EMP EMP EMPE) (go ii va comp h_empe h_emp emp empe)
    rename (II_P GO_P VA_P) (ii_pi go_pi va_pi)

    * Add country identifier
    gen country = "CA"
    gen country_name = "Canada"

    * Generate derived variables (same as EU-KLEMS section)
    gen labshr = comp / va
    gen mat2va = ii / va
    gen w = comp / h_empe
    gen pmat2pva = ii_pi / va_pi

    * Take logs
    foreach v of varlist labshr mat2va w ii_pi va_pi go_pi pmat2pva {
        gen l`v' = log(`v')
    }

    gen manuf = 1

    * Drop if negative or zero key variables
    drop if va <= 0 | ii <= 0 | comp <= 0 | emp <= 0
    drop if comp > va

    gen us = 0
    gen eu = 0

    * No capital accounts for Canada World KLEMS in this file
    * Generate missing capital variables for compatibility
    gen I_GFCF = .
    gen Ip_GFCF = .
    gen K_GFCF = .
    gen Kq_GFCF = .
    gen cap2lab = .
    gen piinv = .
    gen lpiinv = .
    gen lcap2lab = .

    tempfile canada
    save "`canada'"
restore

append using "`canada'"

di "After appending Canada:"
tab country if manuf


* ======================================================================
* PART 0c: Append South Korea from World KLEMS
* ======================================================================

di _n "=============================================="
di "Part 0c: Adding South Korea (World KLEMS 2015)"
di "=============================================="

preserve
    * Import nominal II
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("II") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v ii
    tempfile kor_ii
    save "`kor_ii'"

    * Import real II
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("II(real)") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v ii_real
    tempfile kor_iireal
    save "`kor_iireal'"

    * Import GO nominal
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("GO") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v go
    tempfile kor_go
    save "`kor_go'"

    * Import GO real
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("GO(real)") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v go_real
    tempfile kor_goreal
    save "`kor_goreal'"

    * Import VA nominal
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("VA") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v va
    tempfile kor_va
    save "`kor_va'"

    * Import VA real
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("VA(real)") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v va_real
    tempfile kor_vareal
    save "`kor_vareal'"

    * Import LAB (compensation)
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("LAB") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v comp
    tempfile kor_lab
    save "`kor_lab'"

    * Import H_EMPE (hours worked by employees)
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("H_EMPE") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v h_empe
    tempfile kor_hempe
    save "`kor_hempe'"

    * Import EMP
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("EMP") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v emp
    tempfile kor_emp
    save "`kor_emp'"

    * Import H_EMP
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("H_EMP") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v h_emp
    tempfile kor_hemp
    save "`kor_hemp'"

    * Import EMPE
    import excel "$path/data/raw/EUKLEMS/WorldKLEMS_Korea_2015.xlsx", sheet("EMPE") firstrow clear
    rename EUKLEMScode indcode
    rename _* v*
    reshape long v, i(indcode) j(year)
    rename v empe
    tempfile kor_empe
    save "`kor_empe'"

    * Merge all Korea variables
    use "`kor_ii'", clear
    merge 1:1 indcode year using "`kor_iireal'", nogen
    merge 1:1 indcode year using "`kor_go'", nogen
    merge 1:1 indcode year using "`kor_goreal'", nogen
    merge 1:1 indcode year using "`kor_va'", nogen
    merge 1:1 indcode year using "`kor_vareal'", nogen
    merge 1:1 indcode year using "`kor_lab'", nogen
    merge 1:1 indcode year using "`kor_hempe'", nogen
    merge 1:1 indcode year using "`kor_emp'", nogen
    merge 1:1 indcode year using "`kor_hemp'", nogen
    merge 1:1 indcode year using "`kor_empe'", nogen

    * Keep manufacturing sectors (ISIC Rev.3 codes)
    keep if inlist(indcode, "_15", "_16", "_17", "_18", "_19", "_20", "_21") | ///
           inlist(indcode, "_221", "_22x", "_23", "_244", "_24x", "_25") | ///
           inlist(indcode, "_26", "_27", "_28", "_29", "_30") | ///
           inlist(indcode, "_313", "_31x", "_321", "_322", "_323") | ///
           inlist(indcode, "_331t3", "_334t5", "_34", "_351", "_353", "_35x") | ///
           inlist(indcode, "_36", "_37")

    * Keep 1995-2012
    keep if year >= 1995 & year <= 2012

    drop if missing(ii) | missing(va) | missing(comp)

    * Compute implicit price deflators: nominal / real
    * Normalize to base year 2000 = 100
    foreach v in ii go va {
        gen double _defl_`v' = `v' / `v'_real if `v'_real > 0
        gen _base_`v' = _defl_`v' if year == 2000
        bys indcode: egen _base2_`v' = max(_base_`v')
        gen `v'_pi = (_defl_`v' / _base2_`v') * 100
        drop _defl_`v' _base_`v' _base2_`v'
    }
    drop ii_real go_real va_real

    * --- Map ISIC Rev.3 sub-sectors to NACE Rev.2 ---
    * Korea has finer detail, need to aggregate up
    * Mapping:
    *   _15 + _16           -> C10-C12 (Food, beverages, tobacco)
    *   _17 + _18 + _19     -> C13-C15 (Textiles, apparel, leather)
    *   _20 + _21 + _221 + _22x -> C16-C18 (Wood, paper, printing)
    *   _23                 -> C19     (Coke, petroleum)
    *   _24x                -> C20     (Chemicals excl pharma)
    *   _244                -> C21     (Pharmaceuticals)
    *   _25 + _26           -> C22-C23 (Rubber, plastics, non-metallic minerals)
    *   _27 + _28           -> C24-C25 (Basic & fabricated metals)
    *   _30 + _321 + _322 + _323 -> C26 (Computer, electronic, optical)
    *   _313 + _31x         -> C27     (Electrical equipment)
    *   _29                 -> C28     (Machinery)
    *   _34 + _351 + _353 + _35x -> C29-C30 (Transport equipment)
    *   _36                 -> C31-C33 (Other manufacturing; _37=Recycling dropped)
    *   _331t3 + _334t5     -> part of C26 (instruments -> add to C26)

    gen nace = ""
    replace nace = "C10-C12" if inlist(indcode, "_15", "_16")
    replace nace = "C13-C15" if inlist(indcode, "_17", "_18", "_19")
    replace nace = "C16-C18" if inlist(indcode, "_20", "_21", "_221", "_22x")
    replace nace = "C19"     if indcode == "_23"
    replace nace = "C20"     if indcode == "_24x"
    replace nace = "C21"     if indcode == "_244"
    replace nace = "C22-C23" if inlist(indcode, "_25", "_26")
    replace nace = "C24-C25" if inlist(indcode, "_27", "_28")
    replace nace = "C26"     if inlist(indcode, "_30", "_321", "_322", "_323", "_331t3", "_334t5")
    replace nace = "C27"     if inlist(indcode, "_313", "_31x")
    replace nace = "C28"     if indcode == "_29"
    replace nace = "C29-C30" if inlist(indcode, "_34", "_351", "_353", "_35x")
    replace nace = "C31-C33" if indcode == "_36"
    * _37 (Recycling) is not manufacturing — drop it
    drop if indcode == "_37"

    * Aggregate: sum levels, VA-weighted price indices within each NACE group
    bys nace year: egen _va_sum = total(va)
    gen _va_wt = va / _va_sum

    foreach pvar in ii_pi go_pi va_pi {
        gen _wp_`pvar' = `pvar' * _va_wt
        bys nace year: egen _agg_`pvar' = total(_wp_`pvar')
    }

    foreach lvar in go ii va comp h_empe h_emp emp empe {
        cap confirm variable `lvar'
        if !_rc {
            bys nace year: egen _agg_`lvar' = total(`lvar')
        }
    }

    * Replace with aggregated values
    foreach pvar in ii_pi go_pi va_pi {
        replace `pvar' = _agg_`pvar'
    }
    foreach lvar in go ii va comp h_empe h_emp emp empe {
        cap confirm variable `lvar'
        if !_rc {
            replace `lvar' = _agg_`lvar'
        }
    }

    * Keep one row per NACE×year
    replace indcode = nace
    bys indcode year: gen _seq = _n
    drop if _seq > 1
    drop _va_sum _va_wt _wp_* _agg_* _seq nace

    * Add country identifier
    gen country = "KR"
    gen country_name = "South Korea"

    * Generate derived variables
    gen labshr = comp / va
    gen mat2va = ii / va
    gen w = comp / h_empe
    gen pmat2pva = ii_pi / va_pi

    foreach v of varlist labshr mat2va w ii_pi va_pi go_pi pmat2pva {
        gen l`v' = log(`v')
    }

    gen manuf = 1

    drop if va <= 0 | ii <= 0 | comp <= 0 | emp <= 0
    drop if comp > va

    gen us = 0
    gen eu = 0

    * No capital accounts
    gen I_GFCF = .
    gen Ip_GFCF = .
    gen K_GFCF = .
    gen Kq_GFCF = .
    gen cap2lab = .
    gen piinv = .
    gen lpiinv = .
    gen lcap2lab = .

    tempfile korea
    save "`korea'"
restore

append using "`korea'"

di "After appending South Korea:"
tab country if manuf

* Drop unused fine-sector fields that do not define aggregate panel series.
foreach v in GO_Q II_QI VA_Q desc {
    capture drop `v'
}

save "$path/data/dta/klems_panel_2025.dta", replace

di "crosscountry_panel_build: klems_panel_2025.dta saved."
