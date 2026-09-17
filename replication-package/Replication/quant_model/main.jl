#==================================================#
# Intermediate Input Prices and the Labor Share
#==================================================#

#==================================================#
# paths
#==================================================#

# Run from the directory this script lives in, on any platform.
cd(@__DIR__)

#==================================================#
# load packages and functions
#==================================================#

include("loadpackages.jl")
include("functions.jl")

#==================================================#
# Parameters
#==================================================#

### parameters and hyperparameters
smoothing = 5
# The inversion needs one-period-ahead information: data through 2019
# support reported fundamentals and counterfactual results through 2018.
# The HP filter uses the full 1998-2019 input window.
max_year = 2019  # Input cutoff; 2019 is not a results year.
ctol = 10^-8
damp = 0.9
damp_si = 0.7
maxiter = 20000
T = 50
σ = 0.20
γ = 0.75
β = 1 / 1.03

#==================================================#
# Load data and invert model
#==================================================#

baseline_δ = mean(CSV.read("data/data_manufacturing.csv", DataFrame)[!, :Dep])
years, sector_names, sl, sm, si, λ, k, w, Pm, Pi, R, q = load_data("data/data_manufacturing.csv", smoothing=smoothing, max_year=max_year);
years, sector_names, sl_nosmooth, sm_nosmooth, si_nosmooth, λ_nosmooth, k_nosmooth, w_nosmooth, Pm_nosmooth, Pi_nosmooth, R_nosmooth, q_nosmooth = load_data("data/data_manufacturing.csv", smoothing=0, max_year=max_year);
parms = Para(S=length(sector_names), T=T, σ=σ, γ=γ, β=β, δ=baseline_δ)
Tdata = length(years)
prices_data = [Prices(w=w[t], Pm=Pm[t], Pi=Pi[t]) for t = 1:Tdata]
ppath = [prices_data; fill(prices_data[end], parms.T - Tdata)]
eq_rec, funds_rec = inversionTransition(parms, ppath, k, sm, sl, si, R, q, maxiter=maxiter, damp=damp, damp_si=damp_si, ctol=ctol);
eq0 = solveTransition(parms, funds_rec, ppath, eq_rec[1].k, maxiter=maxiter, damp=damp, ctol=ctol);
rw_path = [funds_rec[t].A[1] .* (eq0[t].θm[1] ./ (1 .- eq0[t].θm[1])) .^ (-1 / (1 - parms.σ)) .* ppath[t].Pm[1] ./ funds_rec[t].B[1] for t = 1:parms.T]

#==================================================#
# Counterfactuals
#==================================================#

### Counterfactual 1: constant materials prices
fpath_cf1 = [Fundamentals(μ=funds_rec[t].μ, α=funds_rec[t].α, χ=funds_rec[t].χ, A=funds_rec[t].A, B=funds_rec[t].B, E=funds_rec[t].E) for t = 1:parms.T]
ppath_cf1 = [Prices(w=ppath[t].w, Pm=ppath[1].Pm, Pi=ppath[t].Pi) for t = 1:parms.T]
eq_cf1 = solveTransition(parms, fpath_cf1, ppath_cf1, eq0[1].k, maxiter=maxiter, damp=damp, ctol=ctol);
### Counterfactual 2: constant effective materials prices
fpath_cf2 = [Fundamentals(μ=funds_rec[t].μ, α=funds_rec[t].α, χ=funds_rec[t].χ, A=funds_rec[t].A, B=funds_rec[1].B .* funds_rec[t].A ./ funds_rec[1].A, E=funds_rec[t].E) for t = 1:parms.T]
ppath_cf2 = [Prices(w=ppath[t].w, Pm=ppath[1].Pm .* (rw_path[t] ./ rw_path[1]), Pi=ppath[t].Pi) for t = 1:parms.T]
eq_cf2 = solveTransition(parms, fpath_cf2, ppath_cf2, eq0[1].k, maxiter=maxiter, damp=damp, ctol=ctol);

### counterfactual labor shares
λ_data_sm = [eq0[t].λ[1] for t = 1:Tdata-1]
λ_cf1 = [eq_cf1[t].λ[1] for t = 1:Tdata-1]
λ_cf2 = [eq_cf2[t].λ[1] for t = 1:Tdata-1]

# compute contribution of materials prices to labor share decline
contribution_cf1 = 1 .- sum(abs.(diff1(λ_cf1))) ./ sum(abs.(diff1(λ_data_sm)))
contribution_cf2 = 1 .- sum(abs.(diff1(λ_cf2))) ./ sum(abs.(diff1(λ_data_sm)))
println("Contribution of materials prices (CF1): ", round(contribution_cf1 * 100, digits=1), "%")
println("Contribution of effective materials prices (CF2): ", round(contribution_cf2 * 100, digits=1), "%")

#==================================================#
# Subsector Analysis
#==================================================#

### Load subsector data and get unique subsector names
subsector_df = CSV.read("data/subsector_data.csv", DataFrame)
all_subsector_names = sort(unique(subsector_df.sector_name))

# Exclude aggregate sectors
aggregate_sectors = ["Manufacturing", "Durable goods", "Nondurable goods"]
subsector_names_to_run = filter(x -> !(x in aggregate_sectors), all_subsector_names)

println("\n=== Running subsector analysis for $(length(subsector_names_to_run)) subsectors ===\n")

### Create temporary directory for subsector data files
subsector_data_dir = "data/temp_subsector"
mkpath(subsector_data_dir)

### Store results for each subsector
subsector_results = Dict{String, NamedTuple}()

for (idx, subsector_name) in enumerate(subsector_names_to_run)
        println("Processing subsector $idx/$(length(subsector_names_to_run)): $subsector_name")

        # Filter data for this subsector
        subsector_data = filter(row -> row.sector_name == subsector_name, subsector_df)

        # Reset sector column to 1 (single sector)
        subsector_data.sector .= 1

        # Save to temporary CSV
        temp_path = joinpath(subsector_data_dir, "temp_subsector.csv")
        CSV.write(temp_path, subsector_data)

        try
                # Load data for this subsector
                sub_δ = mean(subsector_data.Dep)
                sub_years, _, sub_sl, sub_sm, sub_si, sub_λ, sub_k, sub_w, sub_Pm, sub_Pi, sub_R, sub_q = load_data(temp_path, smoothing=smoothing, max_year=max_year)
                _, _, sub_sl_ns, sub_sm_ns, sub_si_ns, sub_λ_ns, sub_k_ns, sub_w_ns, sub_Pm_ns, sub_Pi_ns, sub_R_ns, sub_q_ns = load_data(temp_path, smoothing=0, max_year=max_year)

                # Set up parameters for this subsector
                sub_parms = Para(S=1, T=T, σ=σ, γ=γ, β=β, δ=sub_δ)
                sub_Tdata = length(sub_years)
                sub_prices_data = [Prices(w=sub_w[t], Pm=sub_Pm[t], Pi=sub_Pi[t]) for t = 1:sub_Tdata]
                sub_ppath = [sub_prices_data; fill(sub_prices_data[end], sub_parms.T - sub_Tdata)]

                # Run inversion
                sub_eq_rec, sub_funds_rec = inversionTransition(sub_parms, sub_ppath, sub_k, sub_sm, sub_sl, sub_si, sub_R, sub_q, maxiter=maxiter, damp=damp, damp_si=damp_si, ctol=ctol)
                sub_eq0 = solveTransition(sub_parms, sub_funds_rec, sub_ppath, sub_eq_rec[1].k, maxiter=maxiter, damp=damp, ctol=ctol)

                # Run counterfactuals
                # CF1: constant materials prices
                sub_fpath_cf1 = [Fundamentals(μ=sub_funds_rec[t].μ, α=sub_funds_rec[t].α, χ=sub_funds_rec[t].χ, A=sub_funds_rec[t].A, B=sub_funds_rec[t].B, E=sub_funds_rec[t].E) for t = 1:sub_parms.T]
                sub_ppath_cf1 = [Prices(w=sub_ppath[t].w, Pm=sub_ppath[1].Pm, Pi=sub_ppath[t].Pi) for t = 1:sub_parms.T]
                sub_eq_cf1 = solveTransition(sub_parms, sub_fpath_cf1, sub_ppath_cf1, sub_eq0[1].k, maxiter=maxiter, damp=damp, ctol=ctol)

                # CF2: constant effective materials prices
                sub_rw_path = [sub_funds_rec[t].A[1] .* (sub_eq0[t].θm[1] ./ (1 .- sub_eq0[t].θm[1])) .^ (-1 / (1 - sub_parms.σ)) .* sub_ppath[t].Pm[1] ./ sub_funds_rec[t].B[1] for t = 1:sub_parms.T]
                sub_fpath_cf2 = [Fundamentals(μ=sub_funds_rec[t].μ, α=sub_funds_rec[t].α, χ=sub_funds_rec[t].χ, A=sub_funds_rec[t].A, B=sub_funds_rec[1].B .* sub_funds_rec[t].A ./ sub_funds_rec[1].A, E=sub_funds_rec[t].E) for t = 1:sub_parms.T]
                sub_ppath_cf2 = [Prices(w=sub_ppath[t].w, Pm=sub_ppath[1].Pm .* (sub_rw_path[t] ./ sub_rw_path[1]), Pi=sub_ppath[t].Pi) for t = 1:sub_parms.T]
                sub_eq_cf2 = solveTransition(sub_parms, sub_fpath_cf2, sub_ppath_cf2, sub_eq0[1].k, maxiter=maxiter, damp=damp, ctol=ctol)

                # Store results
                subsector_results[subsector_name] = (
                        years = sub_years,
                        Tdata = sub_Tdata,
                        λ_data_ns = vcat(sub_λ_ns...)[1:end-1],
                        λ_baseline = [sub_eq0[t].λ[1] for t = 1:(sub_Tdata-1)],
                        λ_cf1 = [sub_eq_cf1[t].λ[1] for t = 1:(sub_Tdata-1)],
                        λ_cf2 = [sub_eq_cf2[t].λ[1] for t = 1:(sub_Tdata-1)],
                        μ = [sub_funds_rec[t].μ[1] for t = 1:(sub_Tdata-1)],
                        Pm = div1([sub_ppath[t].Pm[1] for t = 1:(sub_Tdata-1)]),
                        rw = div1([sub_rw_path[t] for t = 1:(sub_Tdata-1)])
                )
                println("  Successfully processed $subsector_name")
        catch e
                println("  Warning: Failed to process $subsector_name: $e")
        end
end

# Clean up temporary files
rm(subsector_data_dir, recursive=true)

#==================================================#
# Save results
#==================================================#

results = Dict(
        "years" => years,
        "Tdata" => Tdata,
        "parms" => parms,
        "sm" => sm,
        "sl" => sl,
        "si" => si,
        "λ_nosmooth" => λ_nosmooth,
        "sm_nosmooth" => sm_nosmooth,
        "si_nosmooth" => si_nosmooth,
        "sl_nosmooth" => sl_nosmooth,
        "k_nosmooth" => k_nosmooth,
        "eq0" => eq0,
        "eq_cf1" => eq_cf1,
        "eq_cf2" => eq_cf2,
        "funds_rec" => funds_rec,
        "ppath" => ppath,
        "rw_path" => rw_path,
        "contribution_cf1" => contribution_cf1,
        "contribution_cf2" => contribution_cf2,
        "subsector_results" => subsector_results,
        "subsector_df" => subsector_df,
        "max_year" => max_year,
)

serialize("results/results.jls", results)
println("\nResults saved to results/results.jls")

#==================================================#
# Generate figures and tables
#==================================================#

include("plots.jl")
