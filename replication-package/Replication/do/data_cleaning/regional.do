* =======================================================================
* PROGRAM:			clean regional dataset
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


*=====================================================================
* Clean the data
*=====================================================================

* Clean County Codes

program define cleancounties
    quietly {
        recode gcode ///
        (15901=15005) (51901=51003) (51903=51005) (51907=51015) (51911=51031) ///
        (51913=51035) (51918=51053) (51919=51059) (51921=51069) (51923=51081) ///
        (51929=51089) (51931=51095) (51933=51121) (51939=51143) (51941=51149) ///
        (51942=51153) (51944=51161) (51945=51163) (51947=51165) (51949=51620) ///
        (51951=51177) (51953=51191) (51955=51195) (51958=51199) (55901=55078)
    }
end


* Prepare Shocks

* 4-digit NAICS industry shocks
use "data/dta/mainregfile.dta", clear
keep if year >= 2001

gen naics4 = floor(naics / 100)
gen lpm_temp = log(pimat)
gen lpk_temp = log(piinv)
bys naics (year): gen lpm = lpm_temp - lpm_temp[1]
bys naics (year): gen lpk = lpk_temp - lpk_temp[1]
bys naics (year): gen lpmiv = shift_share_ct - shift_share_ct[1]

gen year2001 = (year == 2001)
bys naics: gegen ww = total(matcost * year2001)

gcollapse (rawsum) matcost im im_china vship ex (mean) lpm lpmiv lpk [w=ww], by(naics4 year)
save "data/temp/naics4shocks.dta", replace

* Regional shift-share shocks
use "data/dta/QCEW_naics4_panel", clear
keep if inrange(year, 2001, 2018)
destring naics4, replace
keep if inlist(floor(naics4 / 100), 31, 32, 33)

* counties absent from the 1990 commuting-zone crosswalk carry a missing
* cz1990; drop them before the share is formed, as in the BEA blocks below
drop if missing(cz1990)

merge m:1 year naics4 using "data/temp/naics4shocks.dta", keep(3) nogen
bys year naics4: egen s = pc(wage), prop

foreach var in matcost im im_china vship ex {
    replace `var' = `var' * s
}

gcollapse (rawsum) matcost im im_china vship ex (mean) lpm lpmiv lpk [w=wage], by(cz1990 year)
save "data/temp/czshocks.dta", replace



* County-level characteristics
use "data/dta/bea_county_otheraggdata", clear
keep if inrange(year, 2001, 2018)
cleancounties
rename (cainc3090 cainc30250 cainc30190 cainc30200 cainc30180 cainc3010 cainc30100 gcode) ///
       (div_int_rent wages_emp wages_val wages_supp earnings_place_work personal_inc pop fips)

merge m:1 fips using "data/raw/Concordances/cty_czone.dta", keepusing(cz1990 cz1990city) keep(3) nogen
gcollapse (rawsum) div_int_rent wages_emp wages_val wages_supp earnings_place_work personal_inc pop, by(year cz1990 cz1990city)
rename cz1990city largestcity
drop if missing(cz1990)
save "data/temp/czgeneraldata.dta", replace

* CZ GDP by sector
use "data/dta/bea_county_gdp", clear
keep if inrange(year, 2001, 2018)
cleancounties
rename (cagdp21 cagdp212 gcode) (gdp_total gdp_manuf fips)
merge m:1 fips using "data/raw/Concordances/cty_czone.dta", keepusing(cz1990) keep(3) nogen
gcollapse (rawsum) gdp*, by(year cz1990)
drop if missing(cz1990)
save "data/temp/czgdp.dta", replace

* CZ manufacturing payroll and wages
use "data/dta/QCEW_naics2_panel", clear
keep if inrange(year, 2001, 2018)
drop if missing(cz1990)
gen manuf = naics2 == "31-33"
rename (wage annual_avg_wkly_wage) (comp avgwage)
gen comp_manuf = comp if manuf
gen avgwage_manuf = avgwage if manuf
gen est_manuf = est if manuf
gen emp_manuf = emp if manuf
gcollapse (rawsum) est* emp* comp* (mean) avg* [w=emp], by(cz1990 year)
save "data/temp/czcomp.dta", replace


* Merge datasets


use "data/temp/czgeneraldata.dta", clear
merge 1:1 cz1990 year using "data/temp/czcomp.dta", keep(3) nogen
merge 1:1 cz1990 year using "data/temp/czgdp.dta", keep(3) nogen
merge 1:1 cz1990 year using "data/temp/czshocks.dta", keep(3) nogen

* Keep complete panels
bys cz1990: keep if _N == 18

* Labor shares
gen LS  = (comp_manuf / 1000) / gdp_manuf

rename avgwage_manuf w

* Manufacturing share and import penetration
gen manuf_share = emp_manuf / emp
gen impen = im / (vship + im - ex)
gen impen_china = im_china / (vship + im - ex)

* Log transformations used in Table 2
foreach var of varlist LS w emp {
    gen l`var' = log(`var')
}

* Treatment and IV variables
gen M2VA = matcost * 1000 / gdp_manuf
gen year2001 = (year == 2001)
bys cz1990: gegen ww = total(gdp_manuf * year2001)
bys cz1990: gegen M2VA2001 = total(M2VA * year2001)
gen treat = M2VA2001 * lpm
gen iv = M2VA2001 * lpmiv

save "data/dta/regional.dta", replace
