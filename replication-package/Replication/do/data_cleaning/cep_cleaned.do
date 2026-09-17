* =======================================================================
* PROGRAM:            Clean Comtrade unit values using
*                     full annual EIA price paths for 271111 and 271121,
*                     plus a CEPII-growth splice for the 11 residual
*                     problematic HS6 codes
* DATE:               12 March 2026
* =======================================================================

clear all
set more off

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

* -----------------------------------------------------------------------
* EIA prices for LNG and gaseous natural gas
*
* Both 271111 (LNG) and 271121 (gaseous natural gas) switch from liter-
* based reporting pre-2000 to kg-based reporting later in the sample.
* Replace the full annual price paths for both HS6 codes with the
* official EIA annual import price series stored in
* data/raw/external_gas_prices.csv:
*   - 271111: EIA series n9103us3A
*             "Price of U.S. Natural Gas LNG Imports
*              (Dollars per Thousand Cubic Feet)"
*             https://www.eia.gov/dnav/ng/hist/n9103us3a.htm
*   - 271121: EIA series n9100us3A
*             "Price of U.S. Natural Gas Imports
*              (Dollars per Thousand Cubic Feet)"
*             https://www.eia.gov/dnav/ng/hist/n9100us3a.htm
* The external series are used only for within-code time variation. Each
* code is still normalized to its own 1997 level in the final ind_tuv step,
* so the cleaner imports the EIA growth path, not the EIA level itself.
* -----------------------------------------------------------------------

local yearlist 1991 1996 2001 2006 2011 2016
local first = 1

local energy_qtyscale_hs 270111 270112 270119 270210 270220
local nonenergy_qtyscale_hs ///
    250100 250850 251010 251020 251110 251200 251910 ///
    252310 252321 252329 252330 252620 252910 252921 252922 ///
    260111 260112 260600 310420 310430 310490 690220 720110 720529

* For the selected HS6 series, the observed level is
* kept through 1999. From 2000 onward, the series follows CEPII median
* year-to-year growth, anchored so that the CEPII path equals the 1999
* observed level at year 2000.
local residual_cepii_hs ///
    121291 250590 251710 252010 252400 260900 261000 310410 720120 720130 740120

tempname filters
postfile `filters' str30 step long hs_years long hs_codes using ///
    "data/temp/cep_lit_energysafe_gassplice_cepiisplice11_filter_summary.dta", replace

foreach y of local yearlist {
    import delimited using "data/raw/comtrade/comtrade_`y'.csv", clear

    keep year aggregatelevel isleafcode commoditycode qtyunitcode qty ///
        netweightkg tradevalueus

    cap drop if commoditycode == "TOTAL"
    destring commoditycode aggregatelevel isleafcode qtyunitcode qty ///
        netweightkg tradevalueus, replace force

    keep if aggregatelevel == 6 & isleafcode == 1
    keep if commoditycode > 10000

    drop if missing(year, commoditycode, qty, tradevalueus)
    drop if qty <= 0 | tradevalueus <= 0

    rename commoditycode HS92
    gen byte energy_hs = inrange(HS92, 270000, 279999)

    replace qtyunitcode = . if qtyunitcode < 0

    gen qty_adj = qty
    gen byte qtyscale_fix_hs = 0
    foreach hs of local energy_qtyscale_hs {
        replace qtyscale_fix_hs = 1 if HS92 == `hs'
    }
    foreach hs of local nonenergy_qtyscale_hs {
        replace qtyscale_fix_hs = 1 if HS92 == `hs'
    }
    replace qty_adj = 1000 * qty_adj if qtyscale_fix_hs & inrange(year, 2000, 2005)

    gen uv = tradevalueus / qty_adj
    gen source_qty = qty_adj
    gen str18 denom_source = "qty"

    * Crude oil and post-2000 gas use observed kilogram weights.
    replace uv = tradevalueus / netweightkg if ///
        inlist(HS92, 270900, 271111, 271121) & !missing(netweightkg) & netweightkg > 0
    replace source_qty = netweightkg if ///
        inlist(HS92, 270900, 271111, 271121) & !missing(netweightkg) & netweightkg > 0
    replace denom_source = "netweight" if ///
        inlist(HS92, 270900, 271111, 271121) & !missing(netweightkg) & netweightkg > 0

    * For both gas codes, keep the raw series at this stage. The full annual
    * path will be replaced with external benchmark prices after stacking.
    replace denom_source = "ng_liter_raw" if ///
        HS92 == 271121 & missing(netweightkg) & qtyunitcode == 7 & qty_adj > 0
    replace denom_source = "lng_liter_raw" if ///
        HS92 == 271111 & missing(netweightkg) & qtyunitcode == 7 & qty_adj > 0

    * Drop gas rows with no usable denominator (no netweightkg, not liter unit).
    replace uv = . if inlist(HS92, 271121, 271111) & missing(netweightkg) & qtyunitcode != 7
    replace source_qty = . if inlist(HS92, 271121, 271111) & missing(netweightkg) & qtyunitcode != 7
    replace denom_source = "" if inlist(HS92, 271121, 271111) & missing(netweightkg) & qtyunitcode != 7

    drop if missing(uv, source_qty)

    gen byte smallflow_qty = source_qty <= 1
    gen byte smallflow_value = tradevalueus < 1000
    drop if smallflow_qty | smallflow_value

    keep year HS92 energy_hs qtyunitcode uv source_qty denom_source ///
        qtyscale_fix_hs smallflow_qty smallflow_value

    if `first' {
        save "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11_raw", replace
        local first = 0
    }
    else {
        append using "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11_raw"
        save "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11_raw", replace
    }
}

use "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11_raw", clear

quietly count
local n_rows = r(N)
quietly egen hs_tag = tag(HS92)
quietly count if hs_tag
local n_hs = r(N)
drop hs_tag
post `filters' ("after_smallflow") (`n_rows') (`n_hs')

* -----------------------------------------------------------------------
* Replace LNG and gaseous natural gas with external annual EIA price series.
* The source file stores the full 1991-2020 annual path for both HS6 codes.
* Only within-code growth matters because each HS6 is normalized to its own
* 1997 level later on.
* -----------------------------------------------------------------------
tempfile gas_external
import delimited using "data/raw/external_gas_prices.csv", clear
capture confirm variable hs92
if _rc == 0 rename hs92 HS92
save "`gas_external'"

use "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11_raw", clear
merge m:1 year HS92 using "`gas_external'", keep(master match) nogen

replace uv = ext_price if inlist(HS92, 271111, 271121) & !missing(ext_price)
replace denom_source = "external_price" if inlist(HS92, 271111, 271121) & !missing(ext_price)
drop ext_price ext_source

bys HS92: egen qtyunitcode1997 = max(cond(year == 1997, qtyunitcode, .))
drop if !energy_hs & missing(qtyunitcode1997)
drop if !energy_hs & qtyunitcode != qtyunitcode1997

quietly count
local n_rows = r(N)
quietly egen hs_tag = tag(HS92)
quietly count if hs_tag
local n_hs = r(N)
drop hs_tag
post `filters' ("after_unit_consistency") (`n_rows') (`n_hs')

sort HS92 year
by HS92: gen uv_lag = uv[_n-1] if year == year[_n-1] + 1
gen uv_ratio = uv / uv_lag
by HS92: egen med_uv_ratio = median(uv_ratio)
replace med_uv_ratio = 1 if missing(med_uv_ratio)

gen byte change_flag = !energy_hs & !missing(uv_ratio) & ///
    (uv_ratio < 0.2 * med_uv_ratio | uv_ratio > 5 * med_uv_ratio)

drop if change_flag

quietly count
local n_rows = r(N)
quietly egen hs_tag = tag(HS92)
quietly count if hs_tag
local n_hs = r(N)
drop hs_tag
post `filters' ("after_change_screen") (`n_rows') (`n_hs')

* -----------------------------------------------------------------------
* CEPII growth splice for the residual problematic HS6 series.
* Keep the observed path through 1999. For 2000+, replace the level with
* a CEPII-median growth path scaled so that CEPII year 2000 equals the
* observed 1999 level. This preserves the pre-2000 level while importing
* an external post-2000 growth profile.
* -----------------------------------------------------------------------
tempfile cepii11 anchors splice11

preserve
    clear
    save "`cepii11'", emptyok replace
    forvalues y = 2000/2016 {
        import delimited using "data/raw/cepii_tuv/tuv_96_x_`y'.csv", clear
        keep hs6_96 uv yr
        rename hs6_96 HS92
        destring HS92 uv yr, replace force
        gen byte cepii_target = 0
        foreach hs of local residual_cepii_hs {
            replace cepii_target = 1 if HS92 == `hs'
        }
        keep if cepii_target
        drop cepii_target
        collapse (p50) cepii_med_ton = uv, by(HS92 yr)
        rename yr year
        append using "`cepii11'"
        save "`cepii11'", replace
    }
restore

preserve
    gen byte cepii_target = 0
    foreach hs of local residual_cepii_hs {
        replace cepii_target = 1 if HS92 == `hs'
    }
    keep if cepii_target
    drop cepii_target
    bys HS92: egen uv_1999 = max(cond(year == 1999, uv, .))
    keep HS92 uv_1999
    bys HS92: keep if _n == 1
    drop if missing(uv_1999)
    save "`anchors'", replace
restore

use "`anchors'", clear
joinby HS92 using "`cepii11'"
bys HS92: egen cepii_2000_ton = max(cond(year == 2000, cepii_med_ton, .))
gen uv_cepii_splice = uv_1999 * (cepii_med_ton / cepii_2000_ton)
keep if !missing(uv_cepii_splice)
save "`splice11'", replace

use "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11_raw", clear
merge m:1 year HS92 using "`gas_external'", keep(master match) nogen
replace uv = ext_price if inlist(HS92, 271111, 271121) & !missing(ext_price)
replace denom_source = "external_price" if inlist(HS92, 271111, 271121) & !missing(ext_price)
drop ext_price ext_source

bys HS92: egen qtyunitcode1997 = max(cond(year == 1997, qtyunitcode, .))
drop if !energy_hs & missing(qtyunitcode1997)
drop if !energy_hs & qtyunitcode != qtyunitcode1997

sort HS92 year
by HS92: gen uv_lag = uv[_n-1] if year == year[_n-1] + 1
gen uv_ratio = uv / uv_lag
by HS92: egen med_uv_ratio = median(uv_ratio)
replace med_uv_ratio = 1 if missing(med_uv_ratio)
gen byte change_flag = !energy_hs & !missing(uv_ratio) & ///
    (uv_ratio < 0.2 * med_uv_ratio | uv_ratio > 5 * med_uv_ratio)
drop if change_flag

merge 1:1 HS92 year using "`splice11'", nogen
replace uv = uv_cepii_splice if !missing(uv_cepii_splice) & year >= 2000
replace denom_source = "cepii_growth" if !missing(uv_cepii_splice) & year >= 2000
replace source_qty = . if !missing(uv_cepii_splice) & year >= 2000
drop uv_cepii_splice cepii_med_ton cepii_2000_ton uv_1999

quietly count
local n_rows = r(N)
quietly egen hs_tag = tag(HS92)
quietly count if hs_tag
local n_hs = r(N)
drop hs_tag
post `filters' ("after_cepii_splice") (`n_rows') (`n_hs')

bys HS92: egen tuv1997 = max(cond(year == 1997, uv, .))
gen tuvbase = tuv1997

gen ind_tuv = 100 * uv / tuvbase
drop tuv1997 tuvbase
rename (uv ind_tuv) (uv_ct ind_tuv_ct)

drop if missing(HS92)
isid year HS92
drop if missing(ind_tuv_ct)

tempfile hs_pre flagfile
save "`hs_pre'", replace

* HS92 → HS96 is one-to-many; use joinby for Cartesian join
tempfile _hs_conc
preserve
	use "data/raw/Concordances/HS696_Commodities.dta", clear
	keep HS92 HS96 Description
	duplicates drop
	save "`_hs_conc'"
restore
joinby HS92 using "`_hs_conc'"
joinby HS96 using "data/raw/Concordances/HS696_to_IOT.dta"

gen byte mapped_outlier = !energy_hs & ind_tuv_ct > 20000
bys HS92: egen any_mapped_outlier = max(mapped_outlier)

preserve
    keep if any_mapped_outlier
    bysort HS92: keep if _n == 1
    keep HS92
    gen byte drop_hs = 1
    save "`flagfile'", replace
restore

use "`hs_pre'", clear
merge m:1 HS92 using "`flagfile'", nogen
replace drop_hs = 0 if missing(drop_hs)
drop if drop_hs == 1
drop drop_hs

rename ind_tuv_ct ind_tuv

quietly count
local n_rows = r(N)
quietly egen hs_tag = tag(HS92)
quietly count if hs_tag
local n_hs = r(N)
drop hs_tag
post `filters' ("after_series_drop") (`n_rows') (`n_hs')
postclose `filters'

save "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11.dta", replace

use "data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11.dta", clear

* HS92 → HS96 is one-to-many; use joinby for Cartesian join
tempfile _hs_conc2
preserve
	use "data/raw/Concordances/HS696_Commodities.dta", clear
	keep HS92 HS96 Description
	duplicates drop
	save "`_hs_conc2'"
restore
joinby HS92 using "`_hs_conc2'"
joinby HS96 using "data/raw/Concordances/HS696_to_IOT.dta"

sort HS96 year
gen energy = inrange(HS96, 270000, 279999)

* Save HS96-level data before collapsing to IOT commodity level
save "data/dta/Commodity_Prices_HS96.dta", replace

collapse (mean) ind_tuv energy [aw=weight], by(year commodity)

save "data/dta/Commodity_Prices_Weight_comtrade_new.dta", replace


