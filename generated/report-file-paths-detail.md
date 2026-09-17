## Filepaths Analysis Details

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/agg_fred_prices.do**

- Line 86, unix : save data/temp/fred_prices, replace

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/create_ss_dataset.do**

- Line 64, unix : gen naics3=int(naics/1000)
- Line 68, unix : gen labshr = pay/vadd
- Line 69, unix : gen mat2va = matcost/vadd
- Line 70, unix : gen mat2lab = matcost/pay
- Line 73, unix : gen w = prodw/prodh
- Line 74, unix : gen cap2lab = cap/prodh
- Line 75, unix : gen prodshr = prode/emp

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/fig3.do**

- Line 133, unix : forvalues g = 0/1 {
- Line 147, unix : forvalues g = 0/1 {

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/cep_cleaned.do**

- Line 220, unix : forvalues y = 2000/2016 {

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/tables/tabD1.do**

- Line 54, unix : gen double global_share = exports/_hstot
- Line 56, unix : gen double export_share = exports/_ctot

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/figC2.do**

- Line 113, unix : forvalues s = 1/4 {
- Line 126, unix : forvalues s = 1/4 {
- Line 145, unix : forvalues s = 1/4 {
- Line 158, unix : forvalues s = 1/4 {
- Line 167, unix : forvalues s = 1/4 {
- Line 186, unix : forvalues s = 1/4 {

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/concentration.do**

- Line 55, unix : use data/raw/Concordances/naics_97to12, clear
- Line 61, unix : use data/raw/Concordances/naics_02to07, clear
- Line 67, unix : use data/raw/Concordances/naics_07to12, clear
- Line 140, unix : save data/dta/concentration, replace

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/fig1.do**

- Line 43, unix : use data/dta/agglabshr, clear
- Line 44, unix : qui merge 1:1 date using data/temp/fred_prices.dta, nogen

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/tables/tabC5.do**

- Line 39, unix : gen lM2VA = log(matcost/vadd)
- Line 40, unix : gen lVA2R = log(vadd/vship)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/model_inputs.do**

- Line 115, unix : keep in 1/2
- Line 179, unix : replace Dep = Dep/Capitalmil

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/figC3.do**

- Line 64, unix : forvalues y = 1991/2016 {
- Line 91, unix : forvalues y = 1991/2016 {

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/utilities/export_stata_csv.py**

- Line 5, unix : python do/utilities/export_stata_csv.py --source data/raw --output data/raw_csv_copy
- Line 189, unix : parser.error('Resume report roots/mode must match this invocation.')
- Line 205, unix : 'validation': 'Row/column order, strings and missing codes exactly; numeric values at original float32/float64 storage precision. Newly written files also compare exactly after promotion to float64.',

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/fig4.do**

- Line 61, unix : gen pMAT_noEE = MAT_noEE/materials_quantity
- Line 62, unix : gen pEE = EE/energy_quantity
- Line 63, unix : gen pVA = VA/va_quantity
- Line 108, unix : gen labshr = WL/VA
- Line 109, unix : gen WL2M = WL/M

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/tables/tabC7.do**

- Line 63, unix : gen mat2vadd = matcost/vadd
- Line 66, unix : gen cap2lab = cap/labor_hours_quantity
- Line 68, unix : gen prodshr = prode/emp
- Line 72, unix : gen pimat =  materials_compensation/materials_quantity
- Line 73, unix : gen piserv =  service_compensation/services_quantity

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/figC1.do**

- Line 40, unix : use data/dta/agglabshr, clear

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/fig2.tex**

- Line 30, windows : {Expenditure on materials:\\[2pt]$\theta_m(1-\pi)$};
- Line 33, windows : {Expenditure on primary inputs:\\[2pt]$(1-\theta_m)(1-\pi)$};
- Line 48, windows : {Total Value Added $= 1-\theta_m(1-\pi)$};

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/BEA_KLEMS.do**

- Line 53, unix : forvalues i=3/30 {
- Line 60, unix : forvalues i=3/30 {

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/agg_labour_shares.do**

- Line 49, unix : save data/temp/agglabshr_fernald, replace
- Line 56, unix : import delimite data/raw/aggregate/nipaQuarterly.csv, clear varn(1)
- Line 73, unix : gen ls_nipa_nfcorp_gross = nonfincorp_comp/nonfincorp_grossva
- Line 74, unix : gen ls_nipa_nfcorp_net = nonfincorp_comp/nonfincorp_netva
- Line 80, unix : save data/temp/agglabshr_nipa, replace
- Line 91, unix : gen factor = ls2000q1/ls_bls_nonfarm if date == tq(2000q1)
- Line 95, unix : save data/temp/agglabshr_bls_nonfarm, replace
- Line 98, unix : use data/temp/agglabshr_nipa, clear
- Line 99, unix : qui merge 1:1 date using data/temp/agglabshr_fernald, nogen
- Line 100, unix : qui merge 1:1 date using data/temp/agglabshr_bls_nonfarm, nogen
- Line 108, unix : save data/dta/agglabshr, replace

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/tables/tabC3.do**

- Line 39, unix : gen lM2VA = log(matcost/vadd)
- Line 40, unix : gen lM2W = log(matcost/pay)
- Line 41, unix : gen lM2K = log(matcost/cap)
- Line 42, unix : gen lK2VA = log(cap/vadd)
- Line 43, unix : gen lK2L = log(cap/emp)
- Line 44, unix : gen lVA2R = log(vadd/vship)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/trade.do**

- Line 41, unix : foreach yr of numlist 89/118 {
- Line 83, unix : foreach yr of numlist 89/118{
- Line 94, unix : replace ex=ex/1000000

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/disaster_iv_construct.do**

- Line 57, unix : gen double global_share = exports/_hstot
- Line 59, unix : gen double export_share = exports/_ctot
- Line 174, unix : gen long _hs4n = floor(HS96/100)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/create_ss_instrument.do**

- Line 44, unix : gen share_sums1 = use_value/share_sums_total
- Line 51, unix : gen shift = log(ind_tuv/100)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/tables/tab3.do**

- Line 43, unix : gen iv = energy/vadd if year==1972

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/README.tex**

- Line 48, unix : in \pkgfile{data/raw/model_inputs/}; their original access dates were not
- Line 75, unix : \pkgfile{data/raw/disaster_iv/disaster_iv_emdat.xlsx}.
- Line 90, unix : \pkgfile{data/raw_csv_copy/disaster_iv/disaster_iv_emdat__EM-DAT_Data.csv}.
- Line 138, unix : \pkgfile{aggregate/WPSID61.csv}
- Line 148, unix : \pkgfile{aggregate/nipaQuarterly.csv}
- Line 153, unix : \pkgfile{aggregate/fernald.xlsx}
- Line 158, unix : \pkgfile{aggregate/BEA_GDPbyInd_SIC_1947-1997.xls}
- Line 163, unix : \pkgfile{aggregate/BEA_GDPbyInd_ValueAdded.xlsx}
- Line 168, unix : \pkgfile{aggregate/BEA_GDPbyInd_GrossOutput.xlsx}
- Line 173, unix : \pkgfile{aggregate/BEA_NIPA_Section6_Dec2019.xlsx}
- Line 178, unix : \pkgfile{model_inputs/income_emp_tab.xlsx}
- Line 183, unix : \pkgfile{model_inputs/gross_output_tab.xlsx}
- Line 188, unix : \pkgfile{model_inputs/int_input_tab.xlsx}
- Line 193, unix : \pkgfile{model_inputs/value_added_tab.xlsx}
- Line 198, unix : \pkgfile{model_inputs/fixed_assets_tab.xlsx}
- Line 208, unix : \pkgfile{BEA-KLEMS/BEA-BLS-industry-level-production-account-1987-2021.xlsx}
- Line 213, unix : \pkgfile{BIS/mod.csv}
- Line 218, unix : \pkgfile{census/NAICSUseDetail.txt}
- Line 223, unix : \pkgfile{census/concentration_ratios/1997/}, \pkgfile{census/concentration_ratios/2002/}, \pkgfile{census/concentration_ratios/2007/}, \pkgfile{census/concentration_ratios/2012/} --- 46 \pkgfile{.dat} files
- Line 225, unix : & URLs listed in \pkgfile{census/concentration_ratios/SOURCE_URLS.txt}
- Line 229, unix : \pkgfile{cepii_tuv/tuv_96_x_2000.csv} through \pkgfile{tuv_96_x_2016.csv} (17 files)
- Line 234, unix : \pkgfile{comtrade/comtrade_1991.csv} through \pkgfile{comtrade_2016.csv} (6 files)
- Line 239, unix : \pkgfile{disaster_iv/disaster_iv_baci_trade_1997.csv}, \pkgfile{disaster_iv_baci_country_codes.csv}
- Line 244, unix : \pkgfile{disaster_iv/disaster_iv_emdat.xlsx}
- Line 249, unix : \pkgfile{EUKLEMS/EUKLEMS_2025vintage_national_accounts.dta}, \pkgfile{..._capital_accounts.dta}
- Line 254, unix : \pkgfile{EUKLEMS/EUKLEMS_2020vintage.dta}
- Line 259, unix : \pkgfile{EUKLEMS/WorldKLEMS_Canada_2012.xlsx}, \pkgfile{WorldKLEMS_Korea_2015.xlsx}
- Line 264, unix : \pkgfile{EUKLEMS/WIOD/} 43 workbooks, \pkgfile{AUS_NIOT_nov16.xlsx} through \pkgfile{USA_NIOT_nov16.xlsx}
- Line 269, unix : \pkgfile{misc/CMO-Historical-Data-Annual.xlsx}
- Line 274, unix : \pkgfile{NBER-CES/nberces_1958-2018.dta}, \pkgfile{nberces-1958_2018_naics2012.dta}
- Line 279, unix : \pkgfile{NBER-CES/nberces_1958-2011_naics.dta}
- Line 285, unix : \pkgfile{regional_data/QCEW/1990.annual.singlefile.csv} through \pkgfile{2020.annual.singlefile.csv} (31 files)
- Line 290, unix : \pkgfile{regional_data/bea_county/CAGDP2__ALL_AREAS_2001_2020.csv}, \pkgfile{CAINC30__ALL_AREAS_1969_2020.csv}
- Line 301, unix : \pkgfile{trade/imp_detl_yearly_89n.dta} through \pkgfile{118n.dta} and the \pkgfile{exp_detl_yearly_} equivalents (60 files)
- Line 311, unix : The Stata script \pkgfile{do/data_cleaning/model_inputs.do} constructs the
- Line 313, unix : \pkgfile{data/raw/model_inputs/}:
- Line 314, unix : \pkgfile{quant_model/data/data_manufacturing.csv}, covering total
- Line 315, unix : manufacturing, and \pkgfile{quant_model/data/subsector_data.csv}, covering
- Line 344, unix : files are written to \pkgfile{data/temp/model_inputs/}.
- Line 348, unix : \pkgfile{data/raw_csv_copy/model_inputs/}. Each filename consists of the
- Line 459, unix : \pkgfile{Concordances/naics_97to12.dta}, \pkgfile{naics_02to07.dta}, \pkgfile{naics_07to12.dta}
- Line 463, unix : \pkgfile{Concordances/conc_naics97_naics12.dta}
- Line 467, unix : \pkgfile{Concordances/naics2012_to_bea.dta}
- Line 471, unix : \pkgfile{Concordances/IOT_NAICS.dta}
- Line 475, unix : \pkgfile{Concordances/HS696_to_IOT.dta}
- Line 479, unix : \pkgfile{Concordances/HS696_Commodities.dta}
- Line 483, unix : \pkgfile{Concordances/cty_czone.dta}
- Line 487, unix : \pkgfile{EUKLEMS/WIOD/JobID-19_Concordance_H1_to_I3.CSV}
- Line 491, unix : \pkgfile{misc/naicsnames12.dta}, \pkgfile{naics3names12.dta}
- Line 510, unix : \pkgfile{do/main.do} & Stata driver: constructs model inputs and runs all empirical analyses\\
- Line 511, unix : \pkgfile{do/setup.do} & Validates the current package root and initializes Stata paths\\
- Line 512, unix : \pkgfile{do/data_cleaning/} & 21 scripts: raw data $\rightarrow$ model inputs and analysis data; \pkgfile{model_inputs.do} runs first\\
- Line 513, unix : \pkgfile{do/figures/} & 13 Stata analysis scripts, one per figure (or figure family), the shared style helper \pkgfile{graph_style.do}, and an editable schematic drawing, \pkgfile{fig2.tex}\\
- Line 514, unix : \pkgfile{do/tables/} & 19 scripts, one per table\\
- Line 515, unix : \pkgfile{data/raw/} & Source files, including preserved downloads and assembled source extracts\\
- Line 516, unix : \pkgfile{data/raw/model_inputs/} & Five archived BEA workbooks used to construct the quantitative model inputs\\
- Line 517, unix : \pkgfile{data/raw_csv_copy/} & Plain-text \texttt{.csv} copies of every raw file supplied in \texttt{.dta}, \texttt{.xls} or \texttt{.xlsx} format. Provided for readability only; no program reads from this folder\\
- Line 518, unix : \pkgfile{data/dta/} & Analysis data built by the cleaning scripts from \pkgfile{data/raw/}. Created by \pkgfile{do/main.do}, which rebuilds its contents\\
- Line 519, unix : \pkgfile{data/temp/} & Scratch space created by \pkgfile{do/main.do} when needed. The model-input builder creates its intermediates in \pkgfile{model_inputs/}\\
- Line 520, unix : \pkgfile{output/tables/} & 19 generated \texttt{.tex} tables and the supporting Table~D.1 country-list CSV\\
- Line 521, unix : \pkgfile{output/figures/} & 25 generated \texttt{.png} panels and the supplied Figure~2 schematic\\
- Line 523, unix : \pkgfile{quant_model/data/} & Two prebuilt model-input CSV files, regenerated from the archived BEA workbooks by \pkgfile{do/data_cleaning/model_inputs.do}\\
- Line 524, unix : \pkgfile{quant_model/Project.toml}, \pkgfile{Manifest.toml} & Pinned Julia environment used by the supplied model and the verified replication run\\
- Line 525, unix : \pkgfile{quant_model/results/} & Model figures and table\\
- Line 533, unix : \pkgfile{quant_model/results/} directory required by the Julia driver.
- Line 534, unix : The supplied Figure~2 schematic, \pkgfile{output/figures/fig2.png}, is
- Line 536, unix : prebuilt model-input CSV files in \pkgfile{quant_model/data/} are also
- Line 558, unix : \pkgfile{data/raw_csv_copy/stata_csv_validation.json}.
- Line 560, unix : The optional conversion utility \pkgfile{do/utilities/export_stata_csv.py}
- Line 567, unix : python do/utilities/export_stata_csv.py --source data/raw --output data/raw_csv_copy
- Line 579, unix : The listed scripts are included under \pkgfile{do/data_cleaning/};
- Line 580, unix : \pkgfile{do/main.do} runs them in their required order. Source data remain
- Line 581, unix : in \pkgfile{data/raw/}; transformations are written to \pkgfile{data/dta/},
- Line 582, unix : \pkgfile{data/temp/} or \pkgfile{quant_model/data/}.
- Line 594, unix : \pkgfile{do/data_cleaning/create_ss_dataset.do} builds
- Line 595, unix : \pkgfile{data/dta/mainregfile.dta}, indexed by six-digit NAICS-2012 industry
- Line 611, unix : & \pkgfile{pay/vadd}, and its log: payroll share of value added.\\
- Line 613, unix : & \pkgfile{matcost/vadd} and \pkgfile{matcost/pay}; the latter's log is
- Line 616, unix : & \pkgfile{prodw/prodh}, and its log: production-worker wages per hour
- Line 619, unix : & \pkgfile{cap/prodh}, and its log: real capital stock per production-worker
- Line 621, unix : \pkgfile{lK2L=log(cap/emp)}, which uses total employees.\\
- Line 623, unix : & \pkgfile{prode/emp}: production workers divided by total employment.\\
- Line 631, unix : & Industry value added and materials/value added in 1990, held fixed
- Line 638, unix : & The first three NAICS digits, and the three-digit-industry/year group
- Line 648, unix : additional logged ratios locally: materials/value added, value added/sales,
- Line 649, unix : materials/payroll, materials/real capital, real capital/value added, and
- Line 650, unix : real capital/total employees, as applicable to each table.
- Line 653, unix : \pkgfile{do/data_cleaning/trade.do} reads the 1989--2018 import and export
- Line 654, unix : files under \pkgfile{data/raw/trade/}, retaining records whose supplied
- Line 660, unix : \pkgfile{data/dta/imports_1989-2018_naics.dta} and
- Line 661, unix : \pkgfile{data/dta/exports_1989-2018_naics.dta}.
- Line 665, unix : \pkgfile{data/raw/Concordances/conc_naics97_naics12.dta}, retaining links
- Line 669, unix : in the corresponding year. The resulting industry/year records are merged
- Line 673, unix : \pkgfile{do/data_cleaning/cep_cleaned.do} reads the six bundled Comtrade
- Line 684, unix : annual paths in \pkgfile{data/raw/external_gas_prices.csv} when available:
- Line 706, unix : \pkgfile{data/raw/Concordances/HS696_Commodities.dta}; HS96-to-IO links and
- Line 708, unix : \pkgfile{data/raw/Concordances/HS696_to_IOT.dta}. The cleaner saves the
- Line 709, unix : mapped product data as \pkgfile{data/dta/Commodity_Prices_HS96.dta}
- Line 710, unix : and the weighted-mean IO-commodity/year price indexes as
- Line 711, unix : \pkgfile{data/dta/Commodity_Prices_Weight_comtrade_new.dta}.
- Line 716, unix : \pkgfile{do/data_cleaning/create_shares.do} reads
- Line 717, unix : \pkgfile{data/raw/census/NAICSUseDetail.txt}. Compensation is the
- Line 719, unix : rows/columns, missing industry/commodity combinations are filled with zero.
- Line 724, unix : exposures are saved in \pkgfile{data/dta/IOLinkages.dta}.
- Line 726, unix : \pkgfile{do/data_cleaning/create_ss_instrument.do} joins these exposures
- Line 728, unix : $\log(P/100)$, and sums by industry and year.
- Line 737, unix : \pkgfile{data/raw/Concordances/IOT_NAICS.dta} maps these results to
- Line 738, unix : NAICS-1997 in \pkgfile{data/dta/shiftshare_ct.dta}; the main-panel mapping
- Line 742, unix : \pkgfile{do/data_cleaning/build_censuscr_raw.do} extracts the Census
- Line 746, unix : \pkgfile{data/dta/censuscr_97-02-07-12_n6.dta}.
- Line 747, unix : \pkgfile{do/data_cleaning/concentration.do} retains manufacturing and
- Line 752, unix : harmonic means. The output is \pkgfile{data/dta/concentration.dta}.
- Line 759, unix : \pkgfile{do/data_cleaning/BEA_KLEMS.do} reshapes worksheets 3--30 of the
- Line 762, unix : saves \pkgfile{data/dta/BEA-BLS_klems_clean.dta}. Nominal compensation,
- Line 774, unix : \pkgfile{do/tables/tabC7.do} separately maps the main panel to BEA summary
- Line 777, unix : outcomes. Missing aggregated import/export values are set to zero in this
- Line 778, unix : specification. Its labor share uses BEA compensation/value added, whereas
- Line 780, unix : \pkgfile{matcost/vadd}. Its materials price is BEA materials
- Line 781, unix : compensation/materials quantity, without adding energy. The services share
- Line 789, unix : \pkgfile{do/data_cleaning/oilprices.do} reads the nominal and real annual
- Line 791, unix : retains years through 2021 and writes \pkgfile{data/dta/oilprices.dta}.
- Line 793, unix : its treatment is 1972 materials/value added times log materials price,
- Line 794, unix : and its instrument is 1972 energy expenditure/value added times log real
- Line 798, unix : \pkgfile{do/data_cleaning/agg_labour_shares.do} constructs four quarterly
- Line 801, unix : compensation/gross value added; one minus Fernald's capital-share series;
- Line 804, unix : \pkgfile{data/dta/agglabshr.dta}.
- Line 805, unix : \pkgfile{do/data_cleaning/agg_fred_prices.do} averages the listed FRED
- Line 806, unix : series to quarters in \pkgfile{data/temp/fred_prices.dta}. Figure~1 then
- Line 811, unix : For Figure~B.1, \pkgfile{do/data_cleaning/bea_historical.do} assembles
- Line 812, unix : \pkgfile{data/dta/bea_historical.dta}: BEA SIC-basis accounts supply years
- Line 823, unix : \pkgfile{do/data_cleaning/qcew_panels.do} reads the 1990--2020 annual
- Line 824, unix : QCEW CSV files in \pkgfile{data/raw/regional_data/QCEW/}. It retains private
- Line 828, unix : commuting zones with \pkgfile{data/raw/Concordances/cty_czone.dta}.
- Line 831, unix : \pkgfile{data/dta/QCEW_naics2_panel.dta} and
- Line 832, unix : \pkgfile{data/dta/QCEW_naics4_panel.dta}, indexed by commuting zone,
- Line 836, unix : \pkgfile{do/data_cleaning/bea_county.do} reads the CAGDP2 and CAINC30
- Line 837, unix : CSV files in \pkgfile{data/raw/regional_data/bea_county/}, retains county
- Line 839, unix : markers to missing. Its outputs are \pkgfile{data/dta/bea_county_gdp.dta}
- Line 840, unix : and \pkgfile{data/dta/bea_county_otheraggdata.dta}, indexed by county
- Line 843, unix : \pkgfile{do/data_cleaning/regional.do} combines these panels with
- Line 844, unix : \pkgfile{data/dta/mainregfile.dta}. It first averages six-digit industry
- Line 848, unix : prices and instruments within each commuting-zone/year using that year's
- Line 855, unix : The output \pkgfile{data/dta/regional.dta} has key
- Line 867, unix : \pkgfile{do/tables/tab2.do} uses log labor share, log weekly wages,
- Line 868, unix : \texttt{lpk}, and the additional employment/trade controls specified there;
- Line 870, unix : \pkgfile{output/tables/tab2.tex}.
- Line 874, unix : \pkgfile{do/data_cleaning/crosscountry_panel_build.do} combines the
- Line 875, unix : EU-KLEMS national and capital accounts in \pkgfile{data/raw/EUKLEMS/},
- Line 879, unix : vintage scaled by the mean overlap ratio for that country/industry;
- Line 885, unix : are nominal/real ratios normalized to 2000=100. Canada has no separate
- Line 890, unix : The intermediate \pkgfile{data/dta/klems_panel_2025.dta} retains source
- Line 891, unix : currency units. It defines \texttt{labshr=comp/va},
- Line 892, unix : \texttt{mat2va=ii/va}, \texttt{w=comp/h\_empe} (compensation per employee
- Line 893, unix : hour in source units), and \texttt{pmat2pva=ii\_pi/va\_pi}; the variables \texttt{llabshr}, \texttt{lmat2va}, \texttt{lw},
- Line 899, unix : \pkgfile{do/data_cleaning/exchange_rates.do} averages the nonmissing daily
- Line 900, unix : BIS rates in \pkgfile{data/raw/BIS/mod.csv} by country/year to create
- Line 901, unix : \pkgfile{data/dta/fx.dta}. Rates are local currency per US dollar; the BIS
- Line 904, unix : \pkgfile{do/data_cleaning/crosscountry_iv.do} uses the year-2000 sheets of
- Line 906, unix : \pkgfile{data/dta/comtrade_lit_energysafe_gassplice_cepiisplice11.dta}.
- Line 909, unix : supplied HS/WITS concordances. Prices are simple means within supplying
- Line 910, unix : sector/year; interior missing years are linearly interpolated. The log
- Line 911, unix : shock is \texttt{log(ind\_tuv/100)}. Matched IO shares are multiplied by
- Line 915, unix : \texttt{log(fx/fx\_base)} to each commodity shock, using 2000 FX or the
- Line 918, unix : is \pkgfile{data/dta/crosscountry_iv.dta}; its unadjusted and FX-adjusted
- Line 922, unix : \pkgfile{do/data_cleaning/crosscountry_panel_finalize.do} merges the IV by
- Line 926, unix : country/industry pairs with fewer than five years. Baseline intensity is
- Line 927, unix : the year-2000 \texttt{ii/va}, falling back to the first retained year.
- Line 930, unix : sectors, using the same year-2000/first-year rule. Rows missing the outcome,
- Line 932, unix : \pkgfile{data/dta/crosscountry_panel.dta} contains 6,318 observations for
- Line 934, unix : \texttt{ci} identifies country/industry pairs, and the FX instrument is
- Line 935, unix : renamed \texttt{shift\_share\_fx}. \pkgfile{do/tables/tab4.do} produces
- Line 936, unix : \pkgfile{output/tables/tab4.tex} from this panel.
- Line 938, unix : \pkgfile{do/figures/fig_crosscountry.do} writes the four
- Line 940, unix : \pkgfile{output/figures/}. Figure F.2 chains changes in
- Line 941, unix : \texttt{ii\_pi/va\_pi} within countries using current/lag intermediate
- Line 949, unix : \pkgfile{do/data_cleaning/disaster_iv_construct.do} reads the archived
- Line 950, unix : EM-DAT workbook and the 1997 BACI trade/country CSVs in
- Line 951, unix : \pkgfile{data/raw/disaster_iv/}. It retains natural disasters starting in
- Line 955, unix : country/year indicator covers the event year and the next two years,
- Line 957, unix : country/product is retained if it supplies at least 5\% of world exports
- Line 959, unix : The HS4/year shock sums these exporters' 1997 world shares times the
- Line 963, unix : \pkgfile{data/raw/Concordances/HS696_to_IOT.dta} using its supplied weights,
- Line 964, unix : then through \pkgfile{data/dta/IOLinkages.dta} and
- Line 965, unix : \pkgfile{data/raw/Concordances/IOT_NAICS.dta}. It converts NAICS 1997 to
- Line 968, unix : \pkgfile{data/raw/NBER-CES/nberces_1958-2018.dta}. It merges onto the
- Line 969, unix : 1991--2016 NAICS/year skeleton from \pkgfile{data/dta/mainregfile.dta};
- Line 971, unix : \pkgfile{data/dta/disaster_iv_data.dta} has key \texttt{naics, year} and
- Line 974, unix : \pkgfile{do/tables/tabD1.do} separately constructs the disaster/product
- Line 975, unix : examples from these sources. \pkgfile{do/tables/tabD2.do} merges
- Line 977, unix : specifications; \pkgfile{do/tables/tabD3.do} reports their actual first
- Line 979, unix : \pkgfile{output/tables/tabD1.tex}, \pkgfile{tabD2.tex} and
- Line 982, unix : \pkgfile{do/tables/tabD1.do} also writes
- Line 983, unix : \pkgfile{output/tables/tabD1_qualifying_countries.csv}, the full country
- Line 993, unix : \pkgfile{do/data_cleaning/model_inputs.do} produces the two CSVs using the
- Line 1002, unix : In \pkgfile{quant_model/functions.jl}, \texttt{load\_data} first restricts
- Line 1019, unix : series. Plot normalization is performed in \pkgfile{quant_model/plots.jl}.
- Line 1021, unix : \pkgfile{quant_model/main.jl} sets the substitution elasticity to 0.20,
- Line 1022, unix : the adjustment-cost parameter to 0.75, the discount factor to $1/1.03$,
- Line 1039, unix : contribution statistics are calculated in \pkgfile{quant_model/main.jl}
- Line 1040, unix : and serialized to \pkgfile{quant_model/results/results.jls}. The
- Line 1043, unix : \pkgfile{quant_model/plots.jl} reads the cache to write the figures and
- Line 1076, unix : \pkgfile{do/main.do} (all 53 Stata scripts) & 16.43 minutes\\
- Line 1077, unix : \pkgfile{quant_model/main.jl} (model, figures, table) & 79.00 seconds\\
- Line 1107, unix : Each Stata figure script calls \pkgfile{do/figures/graph_style.do} to select
- Line 1129, unix : \pkgfile{do/main.do} checks for the following user-written packages and
- Line 1155, unix : The model-input builder \pkgfile{do/data_cleaning/model_inputs.do} uses
- Line 1178, unix : Julia~1.12.5. The packages loaded in \pkgfile{quant_model/loadpackages.jl} are
- Line 1184, unix : loaded with \texttt{using}: \pkgfile{quant_model/plots.jl} selects the PyPlot
- Line 1190, unix : \pkgfile{quant_model/loadpackages.jl} activates the supplied environment
- Line 1194, unix : \pkgfile{quant_model/Project.toml} and \pkgfile{quant_model/Manifest.toml}.
- Line 1223, unix : The first cleaning script, \pkgfile{do/data_cleaning/model_inputs.do},
- Line 1225, unix : \pkgfile{quant_model/data/} from the archived BEA workbooks.
- Line 1227, unix : It is supplied as \pkgfile{output/figures/fig2.png}.
- Line 1234, unix : julia --startup-file=no --project=quant_model quant_model/main.jl
- Line 1236, unix : Alternatively, run \pkgfile{quant_model/main.jl} from Julia. The script
- Line 1237, unix : reads the rebuilt files from \pkgfile{quant_model/data/} and activates
- Line 1247, unix : Then run \pkgfile{quant_model/main.jl} in Julia. Prebuilt input CSVs are
- Line 1290, unix : Stata exhibits are written to \pkgfile{output/tables/} and
- Line 1291, unix : \pkgfile{output/figures/}. Model exhibits are written to
- Line 1292, unix : \pkgfile{quant_model/results/}. Output files are named after the exhibit
- Line 1299, unix : \pkgfile{do/figures/fig7.do} prints the two counterfactual contribution
- Line 1301, unix : \pkgfile{quant_model/main.jl} prints the manufacturing contribution
- Line 1305, unix : \pkgfile{quant_model/results/results.jls}. This cache also contains
- Line 1317, unix : Table 1 & \pkgfile{do/tables/tab1.do} & \pkgfile{output/tables/tab1.tex}\\
- Line 1318, unix : Table 2 & \pkgfile{do/tables/tab2.do} & \pkgfile{output/tables/tab2.tex}\\
- Line 1319, unix : Table 3 & \pkgfile{do/tables/tab3.do} & \pkgfile{output/tables/tab3.tex}\\
- Line 1320, unix : Table 4 & \pkgfile{do/tables/tab4.do} & \pkgfile{output/tables/tab4.tex}\\
- Line 1321, unix : Table C.1 & \pkgfile{do/tables/tabC1.do} & \pkgfile{output/tables/tabC1.tex}\\
- Line 1322, unix : Table C.2 & \pkgfile{do/tables/tabC2.do} & \pkgfile{output/tables/tabC2.tex}\\
- Line 1323, unix : Table C.3 & \pkgfile{do/tables/tabC3.do} & \pkgfile{output/tables/tabC3.tex}\\
- Line 1324, unix : Table C.4 & \pkgfile{do/tables/tabC4.do} & \pkgfile{output/tables/tabC4.tex}\\
- Line 1325, unix : Table C.5 & \pkgfile{do/tables/tabC5.do} & \pkgfile{output/tables/tabC5.tex}\\
- Line 1326, unix : Table C.6 & \pkgfile{do/tables/tabC6.do} & \pkgfile{output/tables/tabC6.tex}\\
- Line 1327, unix : Table C.7 & \pkgfile{do/tables/tabC7.do} & \pkgfile{output/tables/tabC7.tex}\\
- Line 1328, unix : Table C.8 & \pkgfile{do/tables/tabC8.do} & \pkgfile{output/tables/tabC8.tex}\\
- Line 1329, unix : Table C.9 & \pkgfile{do/tables/tabC9.do} & \pkgfile{output/tables/tabC9.tex}\\
- Line 1330, unix : Table C.10 & \pkgfile{do/tables/tabC10.do} & \pkgfile{output/tables/tabC10.tex}\\
- Line 1331, unix : Table C.11 & \pkgfile{do/tables/tabC11.do} & \pkgfile{output/tables/tabC11.tex}\\
- Line 1332, unix : Table C.12 & \pkgfile{do/tables/tabC12.do} & \pkgfile{output/tables/tabC12.tex}\\
- Line 1333, unix : Table D.1 & \pkgfile{do/tables/tabD1.do} & \pkgfile{output/tables/tabD1.tex}\\
- Line 1334, unix : Table D.1 country list & \pkgfile{do/tables/tabD1.do} & \pkgfile{output/tables/tabD1_qualifying_countries.csv}\\
- Line 1335, unix : Table D.2 & \pkgfile{do/tables/tabD2.do} & \pkgfile{output/tables/tabD2.tex}\\
- Line 1336, unix : Table D.3 & \pkgfile{do/tables/tabD3.do} & \pkgfile{output/tables/tabD3.tex}\\
- Line 1339, unix : Table E.1 & \pkgfile{quant_model/main.jl} & \pkgfile{quant_model/results/subsector_contributions_table.tex}\\
- Line 1345, unix : Stata filenames below are relative to \pkgfile{output/figures/}; Julia
- Line 1346, unix : filenames are relative to \pkgfile{quant_model/results/}. A range such as
- Line 1355, unix : Figure 1 & \pkgfile{do/figures/fig1.do} & \pkgfile{fig1.png}\\
- Line 1356, unix : Figure 3 & \pkgfile{do/figures/fig3.do} & \pkgfile{fig3a.png}, \pkgfile{fig3b.png}, \pkgfile{fig3c.png}\\
- Line 1357, unix : Figure 4 & \pkgfile{do/figures/fig4.do} & \pkgfile{fig4a.png}, \pkgfile{fig4b.png}\\
- Line 1358, unix : Figure 5 & \pkgfile{do/figures/fig5.do} & \pkgfile{fig5a.png}, \pkgfile{fig5b.png}, \pkgfile{fig5a_ld.png}, \pkgfile{fig5b_ld.png}\\
- Line 1359, unix : Figure 6 & \pkgfile{do/figures/fig6.do} & \pkgfile{fig6a.png}, \pkgfile{fig6b.png}\\
- Line 1360, unix : Figure 7 & \pkgfile{do/figures/fig7.do} & \pkgfile{fig7a.png}, \pkgfile{fig7b.png}\\
- Line 1361, unix : Figure B.1 & \pkgfile{do/figures/figB1.do} & \pkgfile{figB1.png}\\
- Line 1362, unix : Figure C.1 & \pkgfile{do/figures/figC1.do} & \pkgfile{figC1.png}\\
- Line 1363, unix : Figure C.2 & \pkgfile{do/figures/figC2.do} & \pkgfile{figC2.png}\\
- Line 1364, unix : Figure C.3 & \pkgfile{do/figures/figC3.do} & \pkgfile{figC3a.png}, \pkgfile{figC3b.png}\\
- Line 1365, unix : Figure C.4 & \pkgfile{do/figures/figC4.do} & \pkgfile{figC4.png}\\
- Line 1366, unix : Figure C.5 & \pkgfile{do/figures/figC5.do} & \pkgfile{figC5.png}\\
- Line 1367, unix : Figures F.1, F.2 & \pkgfile{do/figures/fig_crosscountry.do} & \pkgfile{figF1a.png}, \pkgfile{figF1b.png}, \pkgfile{figF2a.png}, \pkgfile{figF2b.png}\\
- Line 1369, unix : Figure 2 & Supplied fixed schematic (no computation) & \pkgfile{output/figures/fig2.png}\\
- Line 1370, unix : Figure 8 & \pkgfile{quant_model/main.jl} & \pkgfile{main_inversion_a-c.pdf}\\
- Line 1371, unix : Figure 9 & \pkgfile{quant_model/main.jl} & \pkgfile{main_counterfactuals_a-f.pdf}\\
- Line 1372, unix : Figure E.1 & \pkgfile{quant_model/main.jl} & \pkgfile{appendix_inversion.pdf}\\
- Line 1373, unix : Figure E.2 & \pkgfile{quant_model/main.jl} & \pkgfile{main_counterfactuals_g.pdf}\\
- Line 1374, unix : Figure E.3 & \pkgfile{quant_model/main.jl} & \pkgfile{appendix_subsector_counterfactuals.pdf}\\

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/crosscountry_iv.do**

- Line 213, unix : gen isic3_2d = floor(ISIC3/100)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/exchange_rates.do**

- Line 54, unix : period preceding the introduction of the euro, the legacy currency/USD exchange

