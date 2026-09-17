* =======================================================================
* PROGRAM:			clean exchange rate dataset
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
import delimited "data/raw/BIS/mod.csv"
generate stata_date = date(date, "MDY")
format stata_date %td
drop date
rename stata_date date
generate year = year(date)


foreach var in aeunitedarabemirates alalbania arargentina ataustria auaustralia babosniaandherzegovina bebelgium bgbulgaria bhbahrain bnbrunei brbrazil cacanada chswitzerland clchile cnchina cocolombia cycyprus czczechia degermany dkdenmark dzalgeria eeestonia esspain fifinland frfrance gbunitedkingdom grgreece hkhongkongsar hrcroatia huhungary idindonesia ieireland ilisrael inindia iriran isiceland ititaly jpjapan krkorea kwkuwait kzkazakhstan lksrilanka ltlithuania luluxembourg lvlatvia mamorocco mknorthmacedonia mtmalta mumauritius mxmexico mymalaysia nlnetherlands nonorway npnepal nznewzealand omoman peperu phphilippines pkpakistan plpoland ptportugal qaqatar roromania rsserbia rurussia sasaudiarabia sesweden sgsingapore sislovenia skslovakia ththailand tntunisia trtürkiye tttrinidadandtobago twchinesetaipei uaukraine usunitedstates uyuruguay vevenezuela xmeuroarea xwworld zasouthafrica {
	
	ren `var' fx`var'
	
}



/*
The exchange rates of the euro area legacy currencies are expressed in euro. For the
period preceding the introduction of the euro, the legacy currency/USD exchange
rate is divided by the fixed irrevocable euro conversion rate
*/

reshape long fx, i(date) j(country_name) string

drop if fx == .


bys country year (date): egen fx_mean = mean(fx)

bys country year: drop if _n>1
egen country_id = group(country_name)
xtset country_id year

drop fx
rename fx_mean fx


gen country = substr(country_name,1,2)
replace country = upper(country)


save "data/dta/fx.dta", replace
