#==================================================#
# load required packages
#==================================================#

using Pkg

# Activate the environment supplied with this package. Manifest.toml records
# its package versions, and instantiate() installs any missing dependencies.
# No manual Pkg.add is required.
Pkg.activate(@__DIR__)
Pkg.instantiate()

# PyPlot is a required dependency: plots.jl selects the PyPlot backend
# with pyplot(). It is not loaded with `using` below, because PyPlot and
# Plots both export `plot`; Plots loads it as a backend.
# PyPlot requires Python with matplotlib; PyCall can install a private
# Conda environment automatically when needed.

using LinearAlgebra,
    Plots,
    CSV,
    DataFrames,
    StatsBase,
    LaTeXStrings,
    Parameters,
    Printf,
    Serialization

