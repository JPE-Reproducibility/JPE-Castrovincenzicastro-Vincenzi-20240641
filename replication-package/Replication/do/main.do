* =======================================================================
* PROGRAM:            Data construction and empirical analysis master.
* =======================================================================

clear all

* ======================================================================
* set path
* ======================================================================


* Always select the current package root, even if an old $path remains in memory.
global path ""
capture confirm file "do/setup.do"
if _rc {
    display as error "Change to the Replication package root before running do/main.do."
    display as error "The package root must contain do/setup.do."
    exit 601
}
do "do/setup.do"

cd "${path}"

* ======================================================================
* open log
* ======================================================================

* A named log is used so that it coexists with the log Stata opens
* automatically in batch mode (stata /e do do/main.do), which is named
* after this do-file and would otherwise collide.
capture log close replication
log using "replication_run.log", replace text name(replication)

* ======================================================================
* create working directories if missing
* ======================================================================

* data/temp is scratch space and may be empty (and therefore absent) in a
* freshly unzipped copy of the package; the output folders may be too.
cap mkdir "data"
cap mkdir "data/dta"
cap mkdir "data/temp"
cap mkdir "output"
cap mkdir "output/tables"
cap mkdir "output/figures"

* Install only missing user-written commands. Existing installations are
* retained; installation errors stop the run.
foreach dependency in coefplot unique gtools ereplace reghdfe ivreg2 ///
    ivreghdfe estout ranktest ftools binscatter renvarlab {
    capture which `dependency'
    if _rc ssc install `dependency'
}
capture which labmask
if _rc ssc install labutil
capture which _gnvals
if _rc ssc install egenmore
capture which binscatter2
if _rc {
    net install binscatter2, ///
        from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/d4d5c523ff315c2c2cc6105d590894d09cb724e0")
}

* Record the command locations and versions actually used by this run.
foreach dependency in labmask _gnvals coefplot unique gtools ereplace ///
    reghdfe ivreg2 ivreghdfe estout ranktest ftools binscatter renvarlab binscatter2 {
    which `dependency'
}

* ======================================================================
* data cleaning
* ======================================================================

do "do/data_cleaning/model_inputs"

do "do/data_cleaning/agg_labour_shares"

do "do/data_cleaning/agg_fred_prices"

do "do/data_cleaning/oilprices"

do "do/data_cleaning/BEA_KLEMS"

do "do/data_cleaning/bea_historical"

do "do/data_cleaning/build_censuscr_raw"

do "do/data_cleaning/concentration"

do "do/data_cleaning/exchange_rates"

do "do/data_cleaning/trade"

do "do/data_cleaning/create_shares"

do "do/data_cleaning/cep_cleaned"

do "do/data_cleaning/create_ss_instrument"

do "do/data_cleaning/create_ss_dataset"

do "do/data_cleaning/qcew_panels"

do "do/data_cleaning/bea_county"

do "do/data_cleaning/regional"

do "do/data_cleaning/disaster_iv_construct"

do "do/data_cleaning/crosscountry_panel_build"

do "do/data_cleaning/crosscountry_iv"

do "do/data_cleaning/crosscountry_panel_finalize"

* ======================================================================
* figures
* ======================================================================

do "do/figures/fig1"

do "do/figures/fig3"

do "do/figures/fig4"

do "do/figures/fig5"

do "do/figures/fig6"

do "do/figures/fig7"

do "do/figures/figB1"

do "do/figures/figC1"

do "do/figures/figC2"

do "do/figures/figC3"

do "do/figures/figC4"

do "do/figures/figC5"

do "do/figures/fig_crosscountry"

* ======================================================================
* tables
* ======================================================================

do "do/tables/tab1"

do "do/tables/tab2"

do "do/tables/tab3"

do "do/tables/tab4"

do "do/tables/tabC1"

do "do/tables/tabC2"

do "do/tables/tabC3"

do "do/tables/tabC4"

do "do/tables/tabC5"

do "do/tables/tabC6"

do "do/tables/tabC7"

do "do/tables/tabC8"

do "do/tables/tabC9"

do "do/tables/tabC10"

do "do/tables/tabC11"

do "do/tables/tabC12"

do "do/tables/tabD1"

do "do/tables/tabD2"

do "do/tables/tabD3"

* ======================================================================
* close log
* ======================================================================

capture log close replication
