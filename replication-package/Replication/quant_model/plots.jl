#==================================================#
# Figures and Tables
# Loads saved results and generates all output.
# Can be run standalone: julia plots.jl
#==================================================#

# Setup paths (only needed when running standalone)
if !@isdefined(results)
        # Run from the directory this script lives in, on any platform.
        cd(@__DIR__)
        include("loadpackages.jl")
        include("functions.jl")
        results = deserialize("results/results.jls")
        println("Loaded results from results/results.jls")
end

# Unpack results
years = results["years"]
Tdata = results["Tdata"]
parms = results["parms"]
sm = results["sm"]
sl = results["sl"]
si = results["si"]
λ_nosmooth = results["λ_nosmooth"]
sm_nosmooth = results["sm_nosmooth"]
si_nosmooth = results["si_nosmooth"]
sl_nosmooth = results["sl_nosmooth"]
k_nosmooth = results["k_nosmooth"]
eq0 = results["eq0"]
eq_cf1 = results["eq_cf1"]
eq_cf2 = results["eq_cf2"]
funds_rec = results["funds_rec"]
ppath = results["ppath"]
rw_path = results["rw_path"]
contribution_cf1 = results["contribution_cf1"]
contribution_cf2 = results["contribution_cf2"]
subsector_results = results["subsector_results"]
subsector_df = results["subsector_df"]
max_year = results["max_year"]

T = parms.T

#==================================================#
# Figure 8: Model inversion results (main text)
#==================================================#

pyplot()
fmt2 = x -> abs(x) >= 10 ? @sprintf("%.0f", x) : @sprintf("%.2f", x)
default(tickfontsize=12, guidefontsize=14, legendfontsize=11, titlefontsize=14, yformatter=fmt2)

plt1 = plot(years[1:end-1], [funds_rec[t].μ[1] for t = 1:(Tdata-1)], xlabel="", ylabel="Gross markup", label="", lw=2, color=:darkred, legend=:topright, grid=true, framestyle=:box, size=(500, 350), line=:dash)
plt2 = plot(years[1:end-1], [sm[t][1] for t = 1:(Tdata-1)], xlabel="", ylabel="Share", label="Sales-share of Materials (data)", lw=2, color=:black, grid=true, framestyle=:box, legend=2, size=(500,350))
plot!(years[1:end-1], [eq0[t].θm[1] for t = 1:(Tdata-1)], label="Materials output elasticity " * L"θ_{m}", lw=2, color=:darkred, line=:dash)
plt3 = plot(years[1:end-1], div1([ppath[t].Pm[1] for t = 1:(Tdata-1)]), xlabel="", ylabel="Index (Normalized 1998=1)", label="Materials price index (data)", lw=2, color=:black, grid=true, framestyle=:box, legend=:bottomright, size=(500,350))
plot!(years[1:end-1], div1([rw_path[t] for t = 1:(Tdata-1)]), label="Shadow cost of capital-labor bundle", lw=2, color=:darkred, line=:dash)
Plots.savefig(plt1, "results/main_inversion_a.pdf")
Plots.savefig(plt2, "results/main_inversion_b.pdf")
Plots.savefig(plt3, "results/main_inversion_c.pdf")
println("Saved results/main_inversion_a.pdf, main_inversion_b.pdf, main_inversion_c.pdf")

#==================================================#
# Figure E.1: Recovered fundamentals (appendix)
#==================================================#

plt = plot(years[1:end-1], div1([funds_rec[t].B[1] for t = 1:(Tdata-1)]), label="B (Materials augmenting productivity)", lw=2, color=:navy, legend=:topleft, line=:dash)
plot!(years[1:end-1], div1([funds_rec[t].A[1] for t = 1:(Tdata-1)]), label="A (Primary factors augmenting productivity)", lw=2, color=:darkred, line=:dot)
plot!(years[1:end-1], div1([funds_rec[t].χ[1] for t = 1:(Tdata-1)]), label="χ (Investment efficiency)", lw=2, color=:black)
plot!(years[1:end-1], div1([funds_rec[t].α[1] for t = 1:(Tdata-1)]), label="α (Labor share in capital-labor bundle)", lw=2, color=:darkorange, line=:dashdot)
ylabel!("Index (Normalized 1998=1)")
Plots.savefig(plt, "results/appendix_inversion.pdf")
println("Saved results/appendix_inversion.pdf")

#==================================================#
# Figure 9 (panels a-f, main text) and Figure E.2 (panel g, appendix)
#==================================================#

# common plot settings
plot_defaults = (grid=true, framestyle=:box, gridalpha=0.3, gridstyle=:dot,
                 left_margin=3Plots.mm, bottom_margin=2Plots.mm)

# Panel (a): Labor Share - includes legend
plt1 = plot(years[1:end-1], [eq0[t].λ[1] for t = 1:(Tdata-1)], label="Baseline (smoothed data)", lw=2.5, color=:black, ylabel="Share"; plot_defaults...)
plot!(years[1:end-1], [eq_cf1[t].λ[1] for t = 1:(Tdata-1)], label="Constant " * L"P_m", lw=2.5, color=:darkred, line=:dash)
plot!(years[1:end-1], [eq_cf2[t].λ[1] for t = 1:(Tdata-1)], label="Constant effective " * L"P_m", lw=2.5, color=:darkblue, line=(:dot, 3), legend=:bottomleft, legendfontsize=8)

# Panel (b): Materials share of value added - no legend
plt2 = plot(years[1:end-1], [eq0[t].sm[1] / (1 - eq0[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:black, ylabel="Share"; plot_defaults...)
plot!(years[1:end-1], [eq_cf1[t].sm[1] / (1 - eq_cf1[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkred, line=:dash)
plot!(years[1:end-1], [eq_cf2[t].sm[1] / (1 - eq_cf2[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkblue, line=(:dot, 3))

# Panel (c): Materials output elasticity - no legend
plt3 = plot(years[1:end-1], [eq0[t].θm[1] for t = 1:(Tdata-1)], label="", lw=2.5, color=:black, ylabel="Share"; plot_defaults...)
plot!(years[1:end-1], [eq_cf1[t].θm[1] for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkred, line=:dash)
plot!(years[1:end-1], [eq_cf2[t].θm[1] for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkblue, line=(:dot, 3))

# Panel (d): Investment share of value added - no legend
plt4 = plot(years[1:end-1], [eq0[t].si[1] / (1 - eq0[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:black, ylabel="Share", xlabel="Year"; plot_defaults...)
plot!(years[1:end-1], [eq_cf1[t].si[1] / (1 - eq_cf1[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkred, line=:dash)
plot!(years[1:end-1], [eq_cf2[t].si[1] / (1 - eq_cf2[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkblue, line=(:dot, 3))

# Panel (e): Free cash flow share of value added - no legend
plt5 = plot(years[1:end-1], [eq0[t].sπ[1] / (1 - eq0[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:black, ylabel="Share", xlabel="Year"; plot_defaults...)
plot!(years[1:end-1], [eq_cf1[t].sπ[1] / (1 - eq_cf1[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkred, line=:dash)
plot!(years[1:end-1], [eq_cf2[t].sπ[1] / (1 - eq_cf2[t].sm[1]) for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkblue, line=(:dot, 3))

# Panel (f): Capital stock - no legend
plt6 = plot(years[1:end-1], [eq0[t].k[1] for t = 1:(Tdata-1)], label="", lw=2.5, color=:black, ylabel="Capital Stock", xlabel="Year"; plot_defaults...)
plot!(years[1:end-1], [eq_cf1[t].k[1] for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkred, line=:dash)
plot!(years[1:end-1], [eq_cf2[t].k[1] for t = 1:(Tdata-1)], label="", lw=2.5, color=:darkblue, line=(:dot, 3))

Plots.savefig(plt1, "results/main_counterfactuals_a.pdf")
Plots.savefig(plt2, "results/main_counterfactuals_b.pdf")
Plots.savefig(plt3, "results/main_counterfactuals_c.pdf")
Plots.savefig(plt4, "results/main_counterfactuals_d.pdf")
Plots.savefig(plt5, "results/main_counterfactuals_e.pdf")
# Panel (g): VA decomposition — λ, κ, π in baseline (solid) and CF1 (dashed)
λ_bl = [eq0[t].λ[1] for t = 1:(Tdata-1)]
κ_bl = [(1 - funds_rec[t].α[1]) * (1 - eq0[t].θm[1]) / (funds_rec[t].μ[1] - eq0[t].θm[1]) for t = 1:(Tdata-1)]
π_bl = [(funds_rec[t].μ[1] - 1) / (funds_rec[t].μ[1] - eq0[t].θm[1]) for t = 1:(Tdata-1)]

λ_c1 = [eq_cf1[t].λ[1] for t = 1:(Tdata-1)]
κ_c1 = [(1 - funds_rec[t].α[1]) * (1 - eq_cf1[t].θm[1]) / (funds_rec[t].μ[1] - eq_cf1[t].θm[1]) for t = 1:(Tdata-1)]
π_c1 = [(funds_rec[t].μ[1] - 1) / (funds_rec[t].μ[1] - eq_cf1[t].θm[1]) for t = 1:(Tdata-1)]

plt7 = plot(years[1:end-1], λ_bl, label="Labor (baseline)", lw=2.5, color=:black, ylabel="Share of Value Added", xlabel="Year", ylims=(0.1, 0.7), size=(600, 700); plot_defaults...)
plot!(years[1:end-1], κ_bl, label="Capital (baseline)", lw=2.5, color=:navy)
plot!(years[1:end-1], π_bl, label="Profit (baseline)", lw=2.5, color=:darkred)
plot!(years[1:end-1], λ_c1, label=L"Labor (const. $P_m$)", lw=2.5, color=:black, line=:dash)
plot!(years[1:end-1], κ_c1, label=L"Capital (const. $P_m$)", lw=2.5, color=:navy, line=:dash)
plot!(years[1:end-1], π_c1, label=L"Profit (const. $P_m$)", lw=2.5, color=:darkred, line=:dash)
plot!(legend=(0.02, 0.45), legendfontsize=9)

Plots.savefig(plt6, "results/main_counterfactuals_f.pdf")
Plots.savefig(plt7, "results/main_counterfactuals_g.pdf")
println("Saved results/main_counterfactuals_a.pdf through main_counterfactuals_g.pdf")

#==================================================#
# Figure E.3: Subsector counterfactuals (appendix)
#==================================================#

# Dictionary of abbreviated names for long sector names
name_abbreviations = Dict(
        "Apparel and leather and allied products" => "Apparel & Leather",
        "Chemical products" => "Chemicals",
        "Computer and electronic products" => "Computers & Electronics",
        "Electrical equipment, appliances, and components" => "Electrical Equipment",
        "Fabricated metal products" => "Fabricated Metals",
        "Food and beverage and tobacco products" => "Food & Beverage",
        "Furniture and related products" => "Furniture",
        "Machinery" => "Machinery",
        "Miscellaneous manufacturing" => "Miscellaneous",
        "Motor vehicles, bodies and trailers, and parts" => "Motor Vehicles",
        "Nonmetallic mineral products" => "Nonmetallic Minerals",
        "Other transportation equipment" => "Other Transportation",
        "Paper products" => "Paper",
        "Petroleum and coal products" => "Petroleum & Coal",
        "Plastics and rubber products" => "Plastics & Rubber",
        "Primary metals" => "Primary Metals",
        "Printing and related support activities" => "Printing",
        "Textile mills and textile product mills" => "Textiles",
        "Wood products" => "Wood"
)

# NAICS codes for manufacturing subsectors
naics_codes = Dict(
        "Food and beverage and tobacco products" => "311-312",
        "Textile mills and textile product mills" => "313-314",
        "Apparel and leather and allied products" => "315-316",
        "Wood products" => "321",
        "Paper products" => "322",
        "Printing and related support activities" => "323",
        "Petroleum and coal products" => "324",
        "Chemical products" => "325",
        "Plastics and rubber products" => "326",
        "Nonmetallic mineral products" => "327",
        "Primary metals" => "331",
        "Fabricated metal products" => "332",
        "Machinery" => "333",
        "Computer and electronic products" => "334",
        "Electrical equipment, appliances, and components" => "335",
        "Motor vehicles, bodies and trailers, and parts" => "3361-3363",
        "Other transportation equipment" => "3364-3369",
        "Furniture and related products" => "337",
        "Miscellaneous manufacturing" => "339"
)

n_subsectors = length(subsector_results)
n_cols = 5
n_rows = ceil(Int, n_subsectors / n_cols)
sorted_names = sort(collect(keys(subsector_results)))

subsector_plots = []
for (i, name) in enumerate(sorted_names)
        res = subsector_results[name]
        short_name = get(name_abbreviations, name, name)
        naics = get(naics_codes, name, "")
        panel_title = short_name * " (" * naics * ")"

        if i == 1
                p = plot(res.years[1:end-1], res.λ_data_ns, label="Data", color=:gray, linewidth=1, linealpha=0.7; plot_defaults...)
                plot!(res.years[1:end-1], res.λ_baseline, label="Baseline", lw=2, color=:black)
                plot!(res.years[1:end-1], res.λ_cf1, label="Const. " * L"P_m", lw=2, color=:darkred, line=:dash)
                plot!(res.years[1:end-1], res.λ_cf2, label="Const. eff. " * L"P_m", lw=2, color=:darkblue, line=(:dot, 2))
                plot!(title=panel_title, titlefontsize=11, legend=:bottomleft, legendfontsize=8)
        else
                p = plot(res.years[1:end-1], res.λ_data_ns, label="", color=:gray, linewidth=1, linealpha=0.7; plot_defaults...)
                plot!(res.years[1:end-1], res.λ_baseline, label="", lw=2, color=:black)
                plot!(res.years[1:end-1], res.λ_cf1, label="", lw=2, color=:darkred, line=:dash)
                plot!(res.years[1:end-1], res.λ_cf2, label="", lw=2, color=:darkblue, line=(:dot, 2))
                plot!(title=panel_title, titlefontsize=11)
        end
        push!(subsector_plots, p)
end

plt_subsectors = plot(subsector_plots...; layout=grid(n_rows, n_cols), size=(340*n_cols, 260*n_rows), margin=4Plots.mm)
Plots.savefig(plt_subsectors, "results/appendix_subsector_counterfactuals.pdf")
println("Saved results/appendix_subsector_counterfactuals.pdf")

#==================================================#
# Table: Subsector contributions and VA shares
#==================================================#

# Compute VA shares (average over sample period)
va_by_subsector = Dict{String, Float64}()
for name in sorted_names
        sub_data = filter(row -> row.sector_name == name && row.year <= max_year, subsector_df)
        va_by_subsector[name] = mean(sub_data.VA)
end
total_va = sum(values(va_by_subsector))

### Compute table metrics for each subsector
subsector_table = Dict{String, NamedTuple}()
for name in sorted_names
        res = subsector_results[name]
        λ_bl = res.λ_baseline
        λ_cf1 = res.λ_cf1
        λ_cf2 = res.λ_cf2

        # End period (last - first)
        end_data = (λ_bl[end] - λ_bl[1]) * 100
        end_due_pm = (λ_bl[end] - λ_cf1[end]) * 100
        end_due_epm = (λ_bl[end] - λ_cf2[end]) * 100

        # Average across all periods
        avg_data = mean(λ_bl .- λ_bl[1]) * 100
        avg_due_pm = mean(λ_bl .- λ_cf1) * 100
        avg_due_epm = mean(λ_bl .- λ_cf2) * 100

        subsector_table[name] = (
                end_data=end_data, end_due_pm=end_due_pm, end_due_epm=end_due_epm,
                avg_data=avg_data, avg_due_pm=avg_due_pm, avg_due_epm=avg_due_epm
        )
end

# Sort by average effect of P_m (most negative first = largest effect)
sorted_by_contrib = sort(sorted_names, by=name -> subsector_table[name].avg_due_pm)

# Generate LaTeX table
table_lines = String[]
push!(table_lines, "\\begin{table}[htbp]")
push!(table_lines, "\\centering")
push!(table_lines, "\\caption{Effect of Materials Prices on Subsector Labor Shares}")
push!(table_lines, "\\label{tab:subsector_contributions}")
push!(table_lines, "\\resizebox{\\textwidth}{!}{")
push!(table_lines, "\\begin{tabular}{l c ccc ccc}")
push!(table_lines, "\\toprule")
push!(table_lines, " & & \\multicolumn{3}{c}{\\textbf{Average}} & \\multicolumn{3}{c}{\\textbf{End Period}} \\\\")
push!(table_lines, "\\cmidrule(lr){3-5} \\cmidrule(lr){6-8}")
push!(table_lines, "Subsector (NAICS) & VA Share & \$\\Delta \\lambda\$ & Due to & Due to  & \$\\Delta \\lambda\$ & Due to & Due to \\\\")
push!(table_lines, " & & Data & \$\\Delta P_m\$ & \$\\Delta\$\\,Eff.\\ \$P_m\$ & Data & \$\\Delta P_m\$ & \$\\Delta\$\\,Eff.\\ \$P_m\$ \\\\")
push!(table_lines, " & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\\\")
push!(table_lines, "\\midrule")
for name in sorted_by_contrib
        short_name = replace(get(name_abbreviations, name, name), "&" => "\\&")
        naics = get(naics_codes, name, "")
        t = subsector_table[name]
        va_pct = round(va_by_subsector[name] / total_va * 100, digits=1)
        push!(table_lines, "$(short_name) ($(naics)) & $(va_pct) & $(round(t.avg_data, digits=1)) & $(round(t.avg_due_pm, digits=1)) & $(round(t.avg_due_epm, digits=1)) & $(round(t.end_data, digits=1)) & $(round(t.end_due_pm, digits=1)) & $(round(t.end_due_epm, digits=1)) \\\\")
end
push!(table_lines, "\\bottomrule")
push!(table_lines, "\\end{tabular}}")
push!(table_lines, "\\vspace{2mm}")
push!(table_lines, "\\parbox{\\textwidth}{\\small \\textit{Note:} All values are in percentage points. Columns~(2) and~(5) report the change in the labor share in the data. Columns~(3)--(4) and~(6)--(7) report the change in the labor share attributable to changes in materials prices and effective materials prices, respectively. ``Average'' averages across all sample years; ``End period'' compares the last sample year to the first. Subsectors are ranked by column~(3).}")
push!(table_lines, "\\end{table}")

open("results/subsector_contributions_table.tex", "w") do f
        write(f, join(table_lines, "\n"))
end
println("Saved results/subsector_contributions_table.tex")

println("\nAll figures and tables generated.")
