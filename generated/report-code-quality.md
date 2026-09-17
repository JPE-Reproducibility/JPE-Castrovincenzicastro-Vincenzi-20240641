## Code Quality

### Python

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (export_stata_csv.py, line 89)
  → av[~missing] = a.loc[~missing].to_numpy(dtype=np.float64)

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (export_stata_csv.py, line 92)
  → wanted = a.loc[missing].map(number_text).to_numpy(dtype=str)

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (export_stata_csv.py, line 93)
  → good[missing] = wanted == b.loc[missing].to_numpy(dtype=str)

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (export_stata_csv.py, line 94)
  → tokens = b.loc[~missing].to_numpy(dtype=str)

### Stata

[CRITICAL] `merge m:m` uses positional row-matching within key groups, not relational join semantics. Use `joinby` for a true many-to-many join, or identify the correct unique key and use `1:m`/`m:1`. (concentration.do, line 49)
  → * Process years separately to avoid merge m:m (which pairs sequentially,

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (BEA_KLEMS.do, line 43)
  → drop if missing(B)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (BEA_KLEMS.do, line 74)
  → drop if `name' == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (BEA_KLEMS.do, line 96)
  → drop if ind == "State and local government"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (agg_labour_shares.do, line 60)
  → keep if inlist(code,"A033RC","A048RC","A051RC","W255RC","A262RC","A455RC","A457RC","A460RC")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (bea_county.do, line 72)
  → keep if regexm(geofips, "^[0-9][0-9][0-9][0-9][0-9]$")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (bea_county.do, line 73)
  → drop if substr(geofips, 3, 3) == "000"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (bea_county.do, line 81)
  → keep if year <= ${beaendyear}

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (bea_historical.do, line 223)
  → keep if inrange(year, 1947, 2018)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (build_censuscr_raw.do, line 127)
  → keep if strlen(naics6) == 6

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 84)
  → keep if aggregatelevel == 6 & isleafcode == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 85)
  → keep if commoditycode > 10000

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 87)
  → drop if missing(year, commoditycode, qty, tradevalueus)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 88)
  → drop if qty <= 0 | tradevalueus <= 0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 129)
  → drop if missing(uv, source_qty)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 133)
  → drop if smallflow_qty | smallflow_value

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 178)
  → drop if !energy_hs & missing(qtyunitcode1997)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 179)
  → drop if !energy_hs & qtyunitcode != qtyunitcode1997

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 198)
  → drop if change_flag

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 229)
  → keep if cepii_target

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 243)
  → keep if cepii_target

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 248)
  → drop if missing(uv_1999)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 256)
  → keep if !missing(uv_cepii_splice)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 266)
  → drop if !energy_hs & missing(qtyunitcode1997)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 267)
  → drop if !energy_hs & qtyunitcode != qtyunitcode1997

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 276)
  → drop if change_flag

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 299)
  → drop if missing(HS92)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 301)
  → drop if missing(ind_tuv_ct)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 321)
  → keep if any_mapped_outlier

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (cep_cleaned.do, line 331)
  → drop if drop_hs == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (concentration.do, line 44)
  → drop if substr(naics6,1,1)!="3"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (concentration.do, line 91)
  → drop if substr(n2007,1,1)!="3" & !missing(n2007)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (concentration.do, line 94)
  → drop if substr(n2012,1,1)!="3" & !missing(n2012)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (concentration.do, line 105)
  → drop if substr(n2012,1,1)!="3" & !missing(n2012)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (create_shares.do, line 80)
  → drop if inlist( substr(industry,1,1) , "F", "S", "V" )

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (create_shares.do, line 81)
  → drop if inlist( substr(commodity,1,1) , "F", "S", "V" )

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (create_shares.do, line 155)
  → drop if inlist( substr(industry,1,1) , "F", "S", "V" )

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (create_shares.do, line 156)
  → drop if inlist( substr(commodity,1,1) , "F", "S", "V" )

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (create_shares.do, line 170)
  → keep if test_down == test_up

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_iv.do, line 210)
  → drop if missing(HS96) | missing(ISIC3)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_iv.do, line 245)
  → drop if wiod_sector == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_iv.do, line 284)
  → drop if missing(ind_tuv_ct) | missing(HS92) | missing(year)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 140)
  → drop if inlist(indcode, "A", "D", "E", "G", "H", "J", "K", "M", "O-Q")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 141)
  → drop if inlist(indcode, "M-N", "R", "S", "Q86", "Q87-Q88", "L68A", "R-S")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 192)
  → drop if inlist(indcode, "TOT", "TOT_IND", "MARKT", "MARKTxAG")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 267)
  → drop if missing(value)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 332)
  → drop if _seq > 1 & agg_group != ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 527)
  → drop if missing(ii) | missing(va) | missing(comp)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 605)
  → drop if _seq > 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 624)
  → drop if va <= 0 | ii <= 0 | comp <= 0 | emp <= 0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_build.do, line 625)
  → drop if comp > va

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_finalize.do, line 86)
  → drop if comp > va

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_finalize.do, line 91)
  → drop if ii > go

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_finalize.do, line 97)
  → drop if mat2va > 10

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_finalize.do, line 102)
  → drop if labshr < 0.05 | labshr > 0.95

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (crosscountry_panel_finalize.do, line 108)
  → drop if _nobs < 5

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (disaster_iv_construct.do, line 92)
  → drop if inlist(DisasterType, "Epidemic", "Infestation", "Animal incident")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (disaster_iv_construct.do, line 99)
  → keep if inrange(year, $divY1, $divY2)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (exchange_rates.do, line 60)
  → drop if fx == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (model_inputs.do, line 106)
  → drop if _n >= 80

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (model_inputs.do, line 110)
  → keep if B == "`x'" | B == "year"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (model_inputs.do, line 117)
  → drop if _n == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (model_inputs.do, line 121)
  → keep if year>1997

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (model_inputs.do, line 122)
  → keep if year<2024

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (model_inputs.do, line 196)
  → keep if sector_name == "Manufacturing"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (oilprices.do, line 50)
  → drop if missing(year)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (oilprices.do, line 65)
  → drop if missing(year)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (oilprices.do, line 72)
  → keep if year <= `endyear'

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (qcew_panels.do, line 85)
  → drop if strpos(area_fips, "999")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (qcew_panels.do, line 86)
  → drop if annual_avg_emplvl == 0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (regional.do, line 74)
  → keep if inlist(floor(naics4 / 100), 31, 32, 33)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (regional.do, line 102)
  → drop if missing(cz1990)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (regional.do, line 112)
  → drop if missing(cz1990)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (regional.do, line 118)
  → drop if missing(cz1990)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (trade.do, line 62)
  → drop if naics == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (trade.do, line 98)
  → drop if naics == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig3.do, line 44)
  → drop if year > 2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig3.do, line 49)
  → drop if ind_code == "22"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig4.do, line 45)
  → keep if inlist(substr(ind_code,1,2),"31","32","33")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig4.do, line 46)
  → drop if year > 2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig6.do, line 63)
  → keep if inrange(year,1991,2018)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig7.do, line 46)
  → keep if inrange(year,1991,2016)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig7.do, line 47)
  → keep if !missing(shift_share_ct)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (fig7.do, line 270)
  → keep if inrange(year, 1988, 2019)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figC2.do, line 51)
  → drop if year > 2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figC2.do, line 52)
  → drop if ind_code == "GF" | missing(ind_code)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figC2.do, line 53)
  → drop if substr(ind_code, 1, 1) == "1"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figC2.do, line 54)
  → drop if ind_code == "22"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figC3.do, line 45)
  → keep if inrange(year,1991,2016)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tab1.do, line 38)
  → keep if inrange(year,1991,2016)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabC2.do, line 61)
  → drop if missing(price_shock) | missing(delta_labshr) | missing(commodity_intensity)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabC2.do, line 65)
  → keep if rank <= 15

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabC4.do, line 38)
  → keep if inrange(year,1991,2016)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD1.do, line 57)
  → keep if global_share >= $divG & export_share >= $divE

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD1.do, line 74)
  → drop if inlist(DisasterType, "Epidemic", "Infestation", "Animal incident")

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD1.do, line 80)
  → keep if inrange(year, $divY1, $divY2)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD1.do, line 85)
  → keep if deaths > 0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD1.do, line 94)
  → keep if (deaths >= threshold) & !missing(threshold)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD1.do, line 118)
  → keep if _n <= $divTop

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD2.do, line 33)
  → keep if inrange(year,1991,2016)

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (tabD3.do, line 33)
  → keep if inrange(year,1991,2016)

