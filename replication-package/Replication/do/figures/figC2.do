* =======================================================================
* PROGRAM:			Create Figure C.2: Labor Share and Relative Price of Materials Across U.S. Sectors
* DATE:				14 July 2025 (updated March 2026)
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

* Use the paper's graph style, then restore the caller's settings.
quietly graph set window
local _ls_style_saved_font `"`r(fontface)'"'
local _ls_style_saved_scheme `"`c(scheme)'"'
capture noisily {
do "do/figures/graph_style.do"

* ======================================================================
* Appendix Figure — Sector-level relative prices & labor shares
*
* For each of 4 sectors, compute:
*   (a) Tornqvist M+E price / VA price, normalized to 2000 = 100
*   (b) Labor share = (labor_col + labor_nocol) / VA
*
* Sectors:
*   1. Manufacturing   2. Trade   3. Transportation   4. All Other
* ======================================================================

use "data/dta/BEA-BLS_klems_clean.dta", clear
drop if year > 2019
drop if ind_code == "GF" | missing(ind_code)
drop if substr(ind_code, 1, 1) == "1"
drop if ind_code == "22"

* --- Assign sectors ---
gen sector = .
label define sectorlbl 1 "Manufacturing" 2 "Trade" 3 "Transportation" 4 "All Other"

* Manufacturing
replace sector = 1 if inlist(ind_code, "311FT","313TT","315AL","321","322","323","324") | ///
	inlist(ind_code, "325","326","327","331","332","333","334") | ///
	inlist(ind_code, "335","3361MV","3364OT","337","339")

* Trade
replace sector = 2 if inlist(ind_code, "42","44RT")

* Transportation
replace sector = 3 if inlist(ind_code, "481","482","483","484","485","486","487OS","493")

* All Other (everything remaining)
replace sector = 4 if missing(sector)

label values sector sectorlbl

* --- Compute implicit prices ---
gen p_mat = materials_compensation / materials_quantity ///
	if materials_quantity > 0 & !missing(materials_quantity)
gen p_ene = energy_compensation / energy_quantity ///
	if energy_quantity > 0 & !missing(energy_quantity)
gen p_va  = value_added / va_quantity ///
	if va_quantity > 0 & !missing(va_quantity)


* --- Labor share at sector-year level ---
gen WL = labor_nocol_compensation + labor_col_compensation
preserve
	collapse (sum) WL value_added, by(sector year)
	gen labshr = WL / value_added
	tempfile sec_ls
	save "`sec_ls'"
restore

* ======================================================================
* Tornqvist M+E price index by sector
*
* Uses industry-level composite M+E price index weighted by industry M,
* consistent with the approach in fig3.do.
* ======================================================================

* Industry-level Tornqvist M+E price
gen M = materials_compensation + energy_compensation
gen mshr = materials_compensation / M
sort ind_code year
by ind_code (year): gen dlog_pMAT = ln(p_mat) - ln(p_mat[_n-1])
by ind_code (year): gen dlog_pEE  = ln(p_ene) - ln(p_ene[_n-1])
by ind_code (year): gen mshr_L = mshr[_n-1]
gen w_torn = (mshr + mshr_L) / 2
gen dlog_pM = w_torn * dlog_pMAT + (1 - w_torn) * dlog_pEE

preserve
	* Within each sector: Tornqvist weights and aggregate
	forvalues s = 1/4 {
		bysort year: egen tot_M_`s' = total(M) if sector == `s'
		gen share_`s' = M / tot_M_`s' if sector == `s'
		sort ind_code year
		by ind_code: gen share_`s'_L = share_`s'[_n-1]
		gen w_`s' = (share_`s' + share_`s'_L) / 2
		gen c_`s' = w_`s' * dlog_pM if sector == `s'
		bysort year: egen dlog_me_`s' = total(c_`s')
	}

	collapse (first) dlog_me_*, by(year)
	sort year

	forvalues s = 1/4 {
		gen log_me_`s' = sum(dlog_me_`s')
		replace log_me_`s' = 0 if year == 1987
		gen p_me_`s' = exp(log_me_`s')
	}
	keep year p_me_*
	tempfile me_sec
	save "`me_sec'"
restore

* ======================================================================
* Tornqvist VA price index by sector
* ======================================================================

preserve
	egen item = group(ind_code)
	sort item year
	by item: gen dlog_p = ln(p_va) - ln(p_va[_n-1])

	forvalues s = 1/4 {
		bysort year: egen tot_va_`s' = total(value_added) if sector == `s'
		gen share_`s' = value_added / tot_va_`s' if sector == `s'
		sort item year
		by item: gen share_`s'_L = share_`s'[_n-1]
		gen w_`s' = (share_`s' + share_`s'_L) / 2
		gen c_`s' = w_`s' * dlog_p if sector == `s'
		bysort year: egen dlog_va_`s' = total(c_`s')
	}

	collapse (first) dlog_va_*, by(year)
	sort year

	forvalues s = 1/4 {
		gen log_va_`s' = sum(dlog_va_`s')
		replace log_va_`s' = 0 if year == 1987
		gen p_va_`s' = exp(log_va_`s')
	}
	keep year p_va_*
	merge 1:1 year using "`me_sec'", nogen

	* Relative price: M+E / VA, normalized to 2000 = 100
	forvalues s = 1/4 {
		gen rp_`s' = p_me_`s' / p_va_`s'
		summ rp_`s' if year == 2000, meanonly
		replace rp_`s' = rp_`s' / r(mean) * 100
	}
	keep year rp_*
	tempfile rp_sec
	save "`rp_sec'"
restore

* ======================================================================
* Merge and plot
* ======================================================================

use "`sec_ls'", clear
merge m:1 year using "`rp_sec'", nogen

* Assign the correct relative price to each sector
gen rp = .
forvalues s = 1/4 {
	replace rp = rp_`s' if sector == `s'
}
drop rp_1 - rp_4
label values sector sectorlbl

* ======================================================================
* Plot: 4-panel combined graph
* ======================================================================

local graphs ""
levelsof sector, local(secs)
foreach s of local secs {
	local slab : label sectorlbl `s'

	tw (line labshr year if sector == `s' & inrange(year,1987,2019), ///
			color(navy*1.5) lwidth(0.4) yaxis(1)) ///
	   (line rp year if sector == `s' & inrange(year,1987,2019), ///
			color(cranberry*1.2) lwidth(0.4) lpattern(dash) yaxis(2)) ///
	   , title("`slab'", size(small)) ///
		 ytitle("Labor share", axis(1) size(vsmall)) ///
		 ytitle("Rel. price (2000=100)", axis(2) size(vsmall)) ///
		 xtitle("") xlabel(1990(10)2020, labsize(vsmall)) ///
		 ylabel(, axis(1) labsize(vsmall)) ylabel(, axis(2) labsize(vsmall)) ///
		 legend(off) ///
		 scale(0.9) ///
		 name(sec_`s', replace) nodraw

	local graphs "`graphs' sec_`s'"
}

graph combine `graphs', cols(2) ///
	title("") ///
	note("Solid (left axis): Labor share. Dashed (right axis): Relative price of M+E to VA (2000=100).", size(vsmall)) ///
	xsize(7) ysize(5.5)

graph export "output/figures/figC2.png", replace width(2044) height(1606)

}
local _ls_style_run_rc = _rc
capture graph set window fontface `"`_ls_style_saved_font'"'
local _ls_style_font_restore_rc = _rc
capture set scheme `_ls_style_saved_scheme'
local _ls_style_scheme_restore_rc = _rc
if `_ls_style_run_rc' exit `_ls_style_run_rc'
if `_ls_style_font_restore_rc' exit `_ls_style_font_restore_rc'
if `_ls_style_scheme_restore_rc' exit `_ls_style_scheme_restore_rc'
