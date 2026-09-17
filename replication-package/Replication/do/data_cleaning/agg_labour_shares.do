* =======================================================================
* PROGRAM:			clean labour share data
* DATE:				14 July 2025
* =======================================================================

clear all


* =======================================================================
* Define paths
* =======================================================================

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
* Aggregate Labor Shares from Different Sources
* ======================================================================

* Fernald (2014) data (pre-downloaded to data/raw/aggregate/fernald.xlsx)
* Source: https://www.frbsf.org/economic-research/files/quarterly_tfp.xlsx
import excel "data/raw/aggregate/fernald.xlsx", sheet(quarterly) clear cellrange(A2:K315) first
keep date alpha
replace alpha = 1 - alpha
rename alpha ls_fernald
gen date2 = quarterly(date, "YQ")
format date2 %tq
drop date
rename date2 date
save data/temp/agglabshr_fernald, replace

* NIPA quarterly data (pre-downloaded to data/raw/aggregate/)
* Sources: https://apps.bea.gov/national/Release/TXT/NipaDataQ.txt
*          https://apps.bea.gov/national/Release/TXT/TablesRegister.txt
*          https://apps.bea.gov/national/Release/TXT/SeriesRegister.txt
* compute labor shares
import delimite data/raw/aggregate/nipaQuarterly.csv, clear varn(1)
rename period date
rename seriescode code
rename value val
keep if inlist(code,"A033RC","A048RC","A051RC","W255RC","A262RC","A455RC","A457RC","A460RC")
*A033RC - Compensation of employees; A048RC - Rental income; A051RC - Corporate profits; W255RC - Net interest; A262RC - Depreciation
reshape wide val, i(date) j(code) string
destring val*, replace i(",")
rename valA033RC ce
rename valA048RC ri
rename valA051RC cp
rename valW255RC ni
rename valA262RC dep
rename valA455RC nonfincorp_grossva
rename valA457RC nonfincorp_netva
rename valA460RC nonfincorp_comp
gen ls_nipa_gr = ce/(ce+ri+cp+ni+dep)
gen ls_nipa_nfcorp_gross = nonfincorp_comp/nonfincorp_grossva
gen ls_nipa_nfcorp_net = nonfincorp_comp/nonfincorp_netva
gen date2 = quarterly(date, "YQ")
format date2 %tq
drop date
rename date2 date
keep ls* date
save data/temp/agglabshr_nipa, replace

* BLS non-farm business labor share (pre-downloaded to data/raw/aggregate/)
* Source: FRED series PRS85006173 (https://fred.stlouisfed.org/series/PRS85006173)
import delimited "data/raw/aggregate/PRS85006173.csv", clear
rename prs85006173 ls_bls_nonfarm
gen date2 = qofd(date(observation_date, "YMD"))
format date2 %tq
keep ls* date2
rename date2 date
gen ls2000q1 = 0.639 // taken from https://www.bls.gov/opub/mlr/2017/article/estimating-the-us-labor-share.htm
gen factor = ls2000q1/ls_bls_nonfarm if date == tq(2000q1)
ereplace factor = max(factor)
replace ls_bls_nonfarm = ls_bls_nonfarm*factor
keep date ls_bls_nonfarm
save data/temp/agglabshr_bls_nonfarm, replace

* combine all labor shares
use data/temp/agglabshr_nipa, clear
qui merge 1:1 date using data/temp/agglabshr_fernald, nogen
qui merge 1:1 date using data/temp/agglabshr_bls_nonfarm, nogen
drop ls_nipa_nfcorp_net
gen ls_mean = 0.25*(ls_nipa_gr+ls_nipa_nfcorp_gross+ls_fernald+ls_bls_nonfarm)
label var ls_nipa_gr "NIPA data, based on Gomme and Rupert (2004)"
label var ls_nipa_nfcorp_gross "NIPA data, nonfinancial-corporations"
label var ls_fernald "Data from Fernald (2014)"
label var ls_bls_nonfarm "BLS non-farm business sector"
label var ls_mean "Mean across all sources"
save data/dta/agglabshr, replace


