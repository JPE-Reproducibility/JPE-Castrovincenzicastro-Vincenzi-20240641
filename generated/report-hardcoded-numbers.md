## Potentially Hardcoded Numeric Constants


We found the following set of hard coded numbers. This may be completely legitimate (parameter input, thresholds for computations, etc), and is hence only for information.

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/quant_model/functions.jl**

- Line 535, : θk2μ[Tdata] = clamp.(getθk2μ(β, γ, δ, E[Tdata] ./ E[Tdata-1], kdata[Tdata] ./ kdata[Tdata-1], k_after_data ./ kdata[Tdata], sidata[Tdata-1], si[Tdata]), 0.0001, 0.9999)
- Line 540, : θk2μ[t+1] = damp_si .* θk2μ[t+1] .+ (1 - damp_si) .* clamp.(getθk2μ(β, γ, δ, E[t+1] ./ E[t], k[t+1] ./ k[t], k[t+2] ./ k[t+1], si[t], si[t+1]), 0.0001, 0.9999)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/README.tex**

- Line 72, : \url{https://doi.org/10.14428/DVN/I0LTPH}. The complete workbook
- Line 246, : & \url{https://doi.org/10.14428/DVN/I0LTPH}
- Line 342, : variables to 0.001 before export. It checks the merge matches, nonmissing
- Line 802, : and the BLS nonfarm-business index rescaled to 0.639 in 2000Q1. Their

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/figC3.do**

- Line 69, : replace lb = _b[`coefname'] - 1.645 * _se[`coefname'] if year == `y'
- Line 70, : replace ub = _b[`coefname'] + 1.645 * _se[`coefname'] if year == `y'
- Line 96, : replace lb = _b[`coefname'] - 1.645 * _se[`coefname'] if year == `y'
- Line 97, : replace ub = _b[`coefname'] + 1.645 * _se[`coefname'] if year == `y'

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/data_cleaning/agg_labour_shares.do**

- Line 90, : gen ls2000q1 = 0.639 // taken from https://www.bls.gov/opub/mlr/2017/article/estimating-the-us-labor-share.htm

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/do/figures/figC5.do**

- Line 55, : line dlpimat year, xline(1970 1981 1997, lcolor(gray) lpattern(shortdash)) xtitle("") ytitle("Variance of changes in material prices") lc(black) xsize(5) ysize(2.5) yscale(range(0 0.003)) ylabel(0(0.001)0.003)

**/Users/florianoswald/actions-runner/_work/JPE-Castrovincenzicastro-Vincenzi-20240641/JPE-Castrovincenzicastro-Vincenzi-20240641/replication-package/Replication/quant_model/Manifest.toml**

- Line 167, : version = "0.0.20230411+1"
- Line 288, : version = "100.14003.0+0"
- Line 362, : version = "3.100.3+0"
- Line 925, : version = "1.3.243+0"
- Line 1144, : version = "2.4.134+0"

