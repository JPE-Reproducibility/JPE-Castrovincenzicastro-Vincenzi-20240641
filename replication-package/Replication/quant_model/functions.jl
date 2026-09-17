
#==================================================#
# auxiliary functions
#==================================================#

diff1(x::Vector) = x .- x[1]
div1(x::Vector) = x ./ x[1]

# code for convergence (with optional Anderson acceleration)
function converge(updaterule::Function, initguess::Array;
        ctol=10^-6,
        maxiter=10^4,
        damp=0.8,
        displayX=false,
        displaygap=false,
        displaysummary=true,
        checkrange=[],
        power=false,
        anderson_m=0,
        clamp_lower=nothing)

        #=
                Generic function for convergence: iterate an array X until convergence with some update rule.
                updaterule: a function that gets some array X and updates its values.
                initguess: initial guess for the array X.
                anderson_m: depth of Anderson acceleration (0 = standard dampened iteration).
                clamp_lower: lower bound applied to Anderson-corrected iterates.
        =#

        gap = 1.0
        iter = 0

        X = initguess
        newX = similar(X)

        # Anderson acceleration history
        if anderson_m > 0
                X_hist = Vector{typeof(vec(initguess))}()
                R_hist = Vector{typeof(vec(initguess))}()  # residuals g(x)-x
                prev_gap = Inf
                stall_count = 0
        end

        while (gap > ctol && iter < maxiter)

                iter = iter + 1
                newX = updaterule(X)
                if checkrange != []
                        gap = norm((newX[checkrange...] .- X[checkrange...]) ./ X[checkrange...])
                else
                        gap = maximum(abs.(newX .- X))
                end

                if anderson_m > 0 && iter >= 2
                        # Detect stalling: if gap hasn't decreased by at least 10% in 5 steps, restart
                        if gap > 0.9 * prev_gap
                                stall_count += 1
                        else
                                stall_count = 0
                        end
                        prev_gap = gap

                        use_anderson = stall_count < 5 && length(R_hist) >= 1

                        if use_anderson
                                # Anderson acceleration
                                xvec = vec(X)
                                rvec = vec(newX) .- xvec

                                push!(X_hist, copy(xvec))
                                push!(R_hist, copy(rvec))

                                m_k = min(anderson_m, length(R_hist))
                                if m_k >= 2
                                        ΔR = hcat([R_hist[end-m_k+1+j] .- R_hist[end-m_k+j] for j in 1:m_k-1]...)
                                        Δr = R_hist[end]
                                        θ = ΔR \ Δr
                                        x_aa = xvec .+ rvec
                                        for j in 1:m_k-1
                                                x_aa .+= θ[j] .* ((X_hist[end-m_k+1+j] .+ R_hist[end-m_k+1+j]) .- (X_hist[end-m_k+j] .+ R_hist[end-m_k+j]))
                                        end
                                        X = reshape(damp .* xvec .+ (1 - damp) .* x_aa, size(initguess))
                                        if clamp_lower !== nothing
                                                X = max.(X, clamp_lower)
                                        end
                                else
                                        if power
                                                X = (X .^ damp) .* (newX .^ ((1 - damp)))
                                        else
                                                X = damp * X .+ (1 - damp) * newX
                                        end
                                end

                                if length(R_hist) > anderson_m + 1
                                        popfirst!(X_hist)
                                        popfirst!(R_hist)
                                end
                        else
                                # Stalled: restart Anderson by clearing history, use standard damping
                                empty!(X_hist)
                                empty!(R_hist)
                                stall_count = 0
                                if power
                                        X = (X .^ damp) .* (newX .^ ((1 - damp)))
                                else
                                        X = damp * X .+ (1 - damp) * newX
                                end
                        end
                else
                        if power
                                X = (X .^ damp) .* (newX .^ ((1 - damp)))
                        else
                                X = damp * X .+ (1 - damp) * newX
                        end

                        # Initialize Anderson history on first iteration
                        if anderson_m > 0 && iter == 1
                                push!(X_hist, copy(vec(X)))
                                push!(R_hist, vec(newX) .- vec(initguess))
                                prev_gap = gap
                        end
                end

                if displayX
                        display(X)
                end
                if displaygap
                        println("Convergence: gap = ", gap, " iter = ", iter)
                end
        end

        if displaysummary
                if iter < maxiter
                        println("Successful convergence in ", iter, " iterations.")
                else
                        println("Maximum number of iterations reached.")
                end
        end

        return newX
end

#function to pivot a column of df into a matrix
function pivot_to_matrix(df, colname, years, sectors)
        mat = zeros(Float64, length(years), length(sectors))
        for (i, y) in enumerate(years)
                for (j, s) in enumerate(sectors)
                        row = df[(df.year.==y).&(df.sector.==s), :]
                        if nrow(row) > 0
                                mat[i, j] = row[1, colname]
                        end
                end
        end
        return mat
end

function hpfilter(y, λ)
        n = length(y)
        I = Matrix(LinearAlgebra.I, n, n)
        D = zeros(n - 2, n)

        for i in 1:n-2
                D[i, i] = 1
                D[i, i+1] = -2
                D[i, i+2] = 1
        end

        trend = (I + λ * (D' * D)) \ y
        return trend
end


#==================================================#
# structs 
#==================================================#

@with_kw struct Para

        T = 100 # number of periods
        S = 1 # number of sectors
        σ  # elasticity of substitution between intermediates and primary inputs
        γ  # adjustment frictions in capital
        δ # depreciation rates by sector
        β  # discount factor
        βbar = ((β * δ * γ) ./ (1 .- β * (1 .- δ * γ)))
end

@with_kw struct Fundamentals
        μ :: Vector{Float64}
        α::Vector{Float64}
        χ::Vector{Float64}
        A::Vector{Float64}
        B::Vector{Float64}
        E::Vector{Float64}
end

@with_kw struct Prices
        w::Vector{Float64}
        Pm::Vector{Float64}
        Pi::Vector{Float64}
end

@with_kw struct TempEquilibrium
        l::Vector{Float64}
        m::Vector{Float64}
        k::Vector{Float64}
        i::Vector{Float64}
        sl::Vector{Float64}
        sm::Vector{Float64}
        θl::Vector{Float64}
        θm::Vector{Float64}
        si::Vector{Float64}
        sπ::Vector{Float64}
        λ::Vector{Float64}
        y::Vector{Float64}
end


#==================================================#
# model functions 
#==================================================#

F(A, B, α, σ, l, k, m) = ((A .* l .^ α .* k .^ (1 .- α)) .^ ((σ .- 1) ./ σ) .+ (B .* m) .^ ((σ .- 1) ./ σ)) .^ (σ ./ (σ .- 1))
fθm(A, B, α, σ, l, k, m) = (B .* m ./ F(A, B, α, σ, l, k, m)) .^ (1 .- 1 ./ σ)
fθl(A, B, α, σ, l, k, m) = α .* (A .* l .^ α .* k .^ (1 .- α) ./ F(A, B, α, σ, l, k, m)) .^ (1 .- 1 ./ σ)

getsi(β, γ, δ, Eg, θk2μ, k, k′, k′′, si′) = clamp.(β .* Eg .* (1 .- (1 .- δ) ./ (k′ ./ k)) .* (γ .* θk2μ .+ si′ .* ((1 .- δ) ./ (k′′ ./ k′ .- (1 .- δ)) .+ (1 .- γ))), 1e-6, 1 .- 1e-6)

getk′(δ, γ, k, χbar, si) = (1 .- δ) .* k .+ χbar .* (si) .^ γ .* k .^ (1 - γ)

### functions for inversion
getχbar(δ, γ, k, k′, si) = (k′ .- (1 .- δ) .* k) ./ (si .^ γ .* k .^ (1 .- γ))
getθk2μ(β, γ, δ, Eg, kdot′, kdot′′, si, si′) =
        ((si ./ (β .* Eg .* (1 .- (1 .- δ) ./ kdot′)))
         .-
         si′ .* ((1 .- δ) ./ (kdot′′ .- (1 .- δ)) .+ (1 .- γ))) ./ γ


# get θm as a function of k
# Uses bisection per sector for σ <= 0.2 and damped fixed-point iteration for σ > 0.2.
function getθm(parms::Para, funds::Fundamentals, prices::Prices, k::Vector{Float64}, guess_θm::Vector{Float64}; damp=0.5, ctol=10^-12, maxiter=500, displaysummary=false, anderson_m=0)

        S = length(k)

        if parms.σ > 0.2
                # σ > 0.2: damped fixed-point iteration for θm.
                function updaterule(θm)
                        m = (θm ./ funds.μ) .* funds.E ./ prices.Pm
                        l = (funds.α .* (1 .- θm) ./ funds.μ) .* funds.E ./ prices.w
                        q = F(funds.A, funds.B, funds.α, parms.σ, l, k, m)
                        return clamp.((funds.B .* m ./ q) .^ (1 .- 1 ./ parms.σ), 0.01, 0.99)
                end
                return converge(updaterule, guess_θm; damp=damp, ctol=ctol, maxiter=maxiter, displaysummary=displaysummary)
        end

        # σ <= 0.2: bisection for θm in each sector.
        result = similar(guess_θm)
        exp_val = (parms.σ - 1) / parms.σ
        exp_agg = parms.σ / (parms.σ - 1)
        exp_θ = 1 - 1 / parms.σ

        for s in 1:S
                function residual(θm_s)
                        m_s = (θm_s / funds.μ[s]) * funds.E[s] / prices.Pm[s]
                        l_s = (funds.α[s] * (1 - θm_s) / funds.μ[s]) * funds.E[s] / prices.w[s]
                        primary = (funds.A[s] * l_s^funds.α[s] * k[s]^(1 - funds.α[s]))^exp_val
                        materials = (funds.B[s] * m_s)^exp_val
                        q_s = (primary + materials)^exp_agg
                        return clamp((funds.B[s] * m_s / q_s)^exp_θ, 0.01, 0.99) - θm_s
                end

                lo, hi = 0.01, 0.99
                r_lo, r_hi = residual(lo), residual(hi)

                if r_lo * r_hi > 0
                        # Fallback: dampened iteration from guess
                        θm_s = clamp(guess_θm[s], 0.02, 0.98)
                        for iter in 1:maxiter
                                θm_new = clamp(θm_s + residual(θm_s), 0.01, 0.99)
                                if abs(θm_new - θm_s) < ctol; θm_s = θm_new; break; end
                                θm_s = damp * θm_s + (1 - damp) * θm_new
                        end
                        result[s] = θm_s
                else
                        # Bisection
                        for iter in 1:maxiter
                                mid = (lo + hi) / 2
                                r_mid = residual(mid)
                                if abs(r_mid) < ctol || (hi - lo) < ctol; lo = mid; break; end
                                if r_mid * r_lo < 0
                                        hi = mid; r_hi = r_mid
                                else
                                        lo = mid; r_lo = r_mid
                                end
                        end
                        result[s] = lo
                end
        end

        if displaysummary
                println("Bisection getθm completed.")
        end
        return result
end

function steadystate(parms::Para, funds::Fundamentals, prices::Prices; damp=0.7, ctol=10^-8, displaygap=false, displayX=false, initguess=[], maxiter=10^5, displaysummary=true, anderson_m=0)

        @unpack S, T, σ, γ, δ, β, βbar = parms
        @unpack μ, A, B, χ, α, E = funds
        @unpack w, Pm, Pi = prices


        if σ > 0.2
                # σ > 0.2: joint fixed-point iteration for (m, l, k).
                if initguess == []
                        X = [ones(S) ones(S) ones(S)]
                else
                        X = initguess
                end

                function updaterule(X)
                        m₀ = X[:, 1]; l₀ = X[:, 2]; k₀ = X[:, 3]
                        q = F(A, B, α, σ, l₀, k₀, m₀)
                        θm = (B .* m₀ ./ q) .^ (1 .- 1 ./ σ)
                        θl = α .* (A .* l₀ .^ α .* k₀ .^ (1 .- α) ./ q) .^ (1 .- 1 ./ σ)
                        m₁ = θm .* E ./ (Pm .* μ)
                        l₁ = θl .* E ./ (w .* μ)
                        i = βbar .* ((1 .- θm .- θl) ./ μ) .* E ./ Pi
                        k₁ = (χ ./ δ) .^ (1 / γ) .* i
                        return [m₁ l₁ k₁]
                end

                finalX = converge(updaterule, X, damp=damp, ctol=ctol, displaygap=displaygap, maxiter=maxiter, displayX=displayX, displaysummary=displaysummary)

                m = finalX[:, 1]; l = finalX[:, 2]; k = finalX[:, 3]
                i = (χ ./ δ) .^ (-1 / γ) .* k
                θm = fθm(A, B, α, σ, l, k, m)
                θl = fθl(A, B, α, σ, l, k, m)
        else
                # σ <= 0.2: iterate on k and solve θm by bisection.
                if initguess == []
                        k₀ = ones(S)
                else
                        k₀ = initguess[:, 3]
                end

                guess_θm = 0.5 * ones(S)

                function updaterule_k(kvec)
                        θm = getθm(parms, funds, prices, kvec, guess_θm, maxiter=500, ctol=1e-14)
                        guess_θm .= θm
                        θl = α .* (1 .- θm)
                        i = βbar .* ((1 .- θm .- θl) ./ μ) .* E ./ Pi
                        return (χ ./ δ) .^ (1 / γ) .* i
                end

                aa = anderson_m > 0 ? anderson_m : 3
                k = converge(updaterule_k, k₀, damp=0.5, ctol=ctol, displaygap=displaygap, maxiter=maxiter, displayX=displayX, displaysummary=displaysummary, anderson_m=aa, clamp_lower=1e-10)

                θm = getθm(parms, funds, prices, k, guess_θm, maxiter=500, ctol=1e-14)
                θl = α .* (1 .- θm)
                m = (θm ./ μ) .* E ./ Pm
                l = (θl ./ μ) .* E ./ w
                i = βbar .* ((1 .- θm .- θl) ./ μ) .* E ./ Pi
        end

        sm = θm ./ μ
        sl = θl ./ μ
        si = i .* Pi ./ E
        λ = sl ./ (1 .- sm)
        sπ = 1 .- si .- sl .- sm
        y = F(A, B, α, σ, l, k, m)

        return TempEquilibrium(m=m, l=l, k=k, i=i, sm=sm, sl=sl, si=si, λ=λ, sπ=sπ, θm=θm, θl=θl, y=y)
end

function solveTransition(parms::Para,
        fpath::Vector{Fundamentals},
        ppath::Vector{Prices},
        k0::Vector{Float64};
        damp=0.7,
        ctol=10.0^-8,
        displaygap=false,
        maxiter=10^5,
        initguess::Union{Nothing,Matrix{Float64}}=nothing,
        displayX=false)

        @unpack S, T, σ, γ, δ, β, βbar = parms
        netδ = 1 .- δ

        ss = steadystate(parms, fpath[end], ppath[end])

        # initial guess for capital
        if initguess === nothing
                Δt = 5
                k_list = [t < T - Δt ? (k0 ) .* (1 - (t - 1) / (T - Δt - 1)) .+ ((t - 1) / (T - Δt - 1)) : ss.k for t in 1:T]
                k = hcat(k_list...)  
        else
                k = initguess      
        end

        function updaterule(X)

                # split matrix into vectors by column
                k = [X[:, t] for t = 1:T]

                # compute output elasticities based on current capital path
                θm = [getθm(parms, fpath[t], ppath[t], k[t], ss.θm) for t = 1:T]
                θk2μ = [(1 .- θm[t] .- fpath[t].α .* (1 .- θm[t])) ./ fpath[t].μ for t = 1:T]

                # compute implied investment shares
                si = [copy(ss.si) for t = 1:T]
                for t = T-2:-1:1
                        si[t] = getsi(β, γ, δ, fpath[t+1].E ./ fpath[t].E, θk2μ[t+1], k[t], k[t+1], k[t+2], si[t+1])
                end
                # update capital
                for t = 1:T-5
                        k[t+1] = getk′(δ, γ, k[t], fpath[t].χ .* (fpath[t].E ./ ppath[t].Pi) .^ γ, si[t])
                end

                return hcat(k...)
        end

        # Transition path: damped fixed-point iteration without Anderson.
        # Damping is set by the caller.
        finalX = converge(updaterule, k,
                damp=damp,
                ctol=ctol,
                displaygap=displaygap,
                maxiter=maxiter,
                displayX=displayX)

        k = [finalX[:, t] for t = 1:T]

        # more outcomes
        θm = [getθm(parms, fpath[t], ppath[t], k[t], ss.θm) for t = 1:T]
        θl = [fpath[t].α .* (1 .- θm[t]) for t = 1:T]
        l = [(fpath[t].α .* (1 .- θm[t]) ./ fpath[t].μ) .* fpath[t].E ./ ppath[t].w for t = 1:T]
        m = [(θm[t] ./ fpath[t].μ) .* fpath[t].E ./ ppath[t].Pm for t = 1:T]
        si = [copy(ss.si) for t = 1:T]
        for t = T-2:-1:1
                si[t] = clamp.(β .* (fpath[t+1].E ./ fpath[t].E) .*
                               (1 .- netδ ./ (k[t+1] ./ k[t])) .*
                               (γ .* (1 .- θm[t+1] .- θl[t+1]) ./ fpath[t+1].μ .+
                                si[t+1] .* (netδ ./ (k[t+2] ./ k[t+1] .- netδ) .+ (1 .- γ))),
                        1e-6, 1 .- 1e-6)
        end
        i = [si[t] .* fpath[t].E ./ ppath[t].Pi for t = 1:T]
        sl = [θl[t] ./ fpath[t].μ for t = 1:T]
        sm = [θm[t] ./ fpath[t].μ for t = 1:T]
        sπ = [1 .- si[t] .- sl[t] .- sm[t] for t = 1:T]
        λ = [sl[t] ./ (1 .- sm[t]) for t = 1:T]
        y = [F(fpath[t].A, fpath[t].B, fpath[t].α, σ, l[t], k[t], m[t]) for t = 1:T]

        return [TempEquilibrium(
                l=l[t],
                m=m[t],
                k=k[t],
                i=i[t],
                sl=sl[t],
                sm=sm[t],
                θl=θl[t],
                θm=θm[t],
                si=si[t],       
                sπ=sπ[t],
                λ=λ[t],
                y=y[t]
        ) for t = 1:T]
end

function inversionTransition(parms::Para,
        ppath::Vector{Prices},
        kdata::Vector{Vector{Float64}},
        smdata::Vector{Vector{Float64}},
        sldata::Vector{Vector{Float64}},
        sidata::Vector{Vector{Float64}},
        Edata::Vector{Vector{Float64}},
        qdata::Vector{Vector{Float64}};
        damp=0.5,
        damp_si=0.9,
        ctol=10.0^-8,
        displaygap=false,
        maxiter=10^5,
        displayX=false,
        funds_avg_t=1)

        @unpack S, T, σ, γ, δ, β, βbar = parms
        Tdata = length(smdata)

        # initial guess for capital
        k_list = [kdata; [kdata[end] for t = Tdata+1:T]]
        k = hcat(k_list...)

        # sectoral expenditure (exogenous)
        E = [Edata; [Edata[end] for t = Tdata+1:T]]

        # initial guess for Fundamentals
        χ = [ones(S) for t=1:T]
        B = [ones(S) for t=1:T]
        A = [ones(S) for t = 1:T]
        α = [0.5 * ones(S) for t = 1:T]
        μ = [1.1 * ones(S) for t = 1:T]

        # placeholders for outcomes of interest
        θk2μ = [0.08*ones(S) for t = 1:T]
        si = [t < Tdata ? sidata[t] : sidata[end] for t = 1:T]

        # initial guess for value of k in the period after the data ends
        k_after_data = kdata[end] .* (kdata[end] ./ kdata[end-1])

        function updaterule(X)

                # split matrix into vectors by column
                k = [X[:, t] for t = 1:T]

                # compute steady-state 
                ss = steadystate(parms, Fundamentals(μ=μ[end], A=A[end], B=B[end], χ=χ[end], α=α[end], E=E[end]), ppath[end], ctol=10^-4, displaysummary=false)

                # decide on steady-state values of fundamentals (average of last funds_avg_t periods)
                μ_ss = mean(μ[Tdata-(funds_avg_t-1):Tdata])
                α_ss = mean(α[Tdata-(funds_avg_t-1):Tdata])
                B_ss = mean(B[Tdata-(funds_avg_t-1):Tdata])
                χ_ss = mean(χ[Tdata-(funds_avg_t-1):Tdata])

                # update θk2μ and si
                for t = T:-1:1
                        if t>T-2
                                si[t]=ss.si
                        elseif t > Tdata -1
                                θm′ = getθm(parms, Fundamentals(μ=μ[t+1], A=A[t+1], B=B[t+1], χ=χ[t+1], α=α[t+1], E=E[t+1]), ppath[t+1], k[t+1], ss.θm)
                                θk2μ[t+1] = (1 .- θm′ .- α[t+1] .* (1 .- θm′)) ./ μ[t+1]
                                si[t] = damp_si .* si[t] .+ (1 - damp_si) .* getsi(β, γ, δ, E[t+1] ./ E[t], θk2μ[t+1], k[t], k[t+1], k[t+2], si[t+1])
                        elseif t == Tdata - 1
                                si[Tdata-1] = sidata[Tdata-1]
                                θk2μ[Tdata] = clamp.(getθk2μ(β, γ, δ, E[Tdata] ./ E[Tdata-1], kdata[Tdata] ./ kdata[Tdata-1], k_after_data ./ kdata[Tdata], sidata[Tdata-1], si[Tdata]), 0.0001, 0.9999)
                                k_after_data = damp_si .* k_after_data .+ (1 - damp_si) .* k[Tdata+1]

                        else
                                si[t] = sidata[t]
                                θk2μ[t+1] = damp_si .* θk2μ[t+1] .+ (1 - damp_si) .* clamp.(getθk2μ(β, γ, δ, E[t+1] ./ E[t], k[t+1] ./ k[t], k[t+2] ./ k[t+1], si[t], si[t+1]), 0.0001, 0.9999)
                        end
                end

                # update capital and χ
                for t = 1:T 
                        if t < Tdata
                                χ[t] = (E[t] ./ ppath[t].Pi) .^ (-γ) .* getχbar(δ, γ, kdata[t], kdata[t+1], si[t])
                                k[t+1] = kdata[t+1]
                        elseif t == Tdata
                                χ[t] = (E[t] ./ ppath[t].Pi) .^ (-γ) .* getχbar(δ, γ, kdata[t], k_after_data, si[t])
                                k[t+1] = k_after_data
                        elseif t<T- 3
                                χ[t] = χ_ss
                                k[t+1] = getk′(δ, γ, k[t], χ[t] .* (E[t] ./ ppath[t].Pi) .^ γ, si[t])
                        else 
                                χ[t] = χ_ss
                                k[t] = ss.k
                        end
                end
                
                # inversion of μ, α, B
                for t = 2:T
                        if t <= Tdata
                                μ[t] = 1 ./ (θk2μ[t] + sldata[t] + smdata[t])
                                α[t] = (sldata[t] ./ (1 .- smdata[t])) .* μ[t] .* (1 .- smdata[t]) ./ (1 .- smdata[t] .* μ[t])
                                B[t] = A[t] .* (1 ./ α[t]) .^ (σ / (1 .- σ)) .* (sldata[t] ./ smdata[t]) .^ (1 / (1 .- σ)) .* ppath[t].Pm ./ (ppath[t].w .* ((sldata[t] .* E[t] ./ ppath[t].w) ./ k[t]) .^ (1 .- α[t]))
                        else
                                μ[t] = μ_ss
                                α[t] = α_ss
                                B[t] = B_ss
                        end
                end
                μ[1] = copy(μ[2])
                α[1] = copy(α[2])
                B[1] = copy(B[2])


                # inversion of a
                for t = 2:T
                        if t <= Tdata
                                θm = getθm(parms, Fundamentals(μ=μ[t], A=A[t], B=B[t], χ=χ[t], α=α[t], E=E[t]), ppath[t], k[t], ss.θm)
                                l = (α[t] .* (1 .- θm) ./ μ[t]) .* E[t] ./ ppath[t].w
                                m = (θm ./ μ[t]) .* E[t] ./ ppath[t].Pm
                                A[t] = qdata[t] ./ (((l .^ α[t] .* k[t] .^ (1 .- α[t])) .^ ((σ .- 1) ./ σ) .+ (B[t] ./ A[t] .* m) .^ ((σ .- 1) ./ σ)) .^ (σ ./ (σ .- 1)))

                        else
                                A[t] = A[t-1]
                        end
                end
                A[1] = copy(A[2])

                return hcat(k...)
        end

        # Inversion outer loop: damped fixed-point iteration without Anderson; damping is set by the caller.
        finalX = converge(updaterule, k,
                damp=damp,
                ctol=ctol,
                displaygap=displaygap,
                maxiter=maxiter,
                displayX=displayX)

        k = [finalX[:, t] for t = 1:T]

        fpath = [Fundamentals(μ=μ[t], A=A[t], B=B[t], χ=χ[t], α=α[t], E=E[t]) for t=1:T]

        ss = steadystate(parms, fpath[end], ppath[end])

        # more outcomes
        θm = [getθm(parms, fpath[t], ppath[t], k[t], ss.θm) for t = 1:T]
        θl = [fpath[t].α .* (1 .- θm[t]) for t = 1:T]
        l = [(fpath[t].α .* (1 .- θm[t]) ./ fpath[t].μ) .* fpath[t].E ./ ppath[t].w for t = 1:T]
        m = [(θm[t] ./ fpath[t].μ) .* fpath[t].E ./ ppath[t].Pm for t = 1:T]
        i = [si[t] .* fpath[t].E ./ ppath[t].Pi for t = 1:T]
        sl = [θl[t] ./ fpath[t].μ for t = 1:T]
        sm = [θm[t] ./ fpath[t].μ for t = 1:T]
        sπ = [1 .- si[t] .- sl[t] .- sm[t] for t = 1:T]
        λ = [sl[t] ./ (1 .- sm[t]) for t = 1:T]
        y = [F(fpath[t].A, fpath[t].B, fpath[t].α, σ, l[t], k[t], m[t]) for t = 1:T]

        return [TempEquilibrium(
                l=l[t],
                m=m[t],
                k=k[t],
                i=i[t],
                sl=sl[t],
                sm=sm[t],
                θl=θl[t],
                θm=θm[t],
                si=si[t],
                sπ=sπ[t],
                λ=λ[t],
                y=y[t]
        ) for t = 1:T], [Fundamentals(μ=μ[t], A=A[t], B=B[t], χ=χ[t], α=α[t], E=E[t]) for t = 1:T]
end


#==================================================#
# load data 
#==================================================#


function load_data(path; smoothing=5, max_year=2019)

        # load data into a dataframe
        df = CSV.read(path, DataFrame)
        df = filter(row -> row.year <= max_year, df)

        # get dimensions
        years = sort(unique(df.year))
        sectors = sort(unique(df.sector))
        if length(sectors) > 1
                sector_names = sort(unique(df.sector_name))
        else
                sector_names = ["Manufacturing"]
        end

        # create dictionary to store matrices
        matrices = Dict{Symbol,Matrix{Float64}}()

        # transform each column of the dataframe to a matrix
        columns = [:Comp, :Cap_ind, :Capitalmil, :Mat, :Investmentmil, :VA, :GOmil, :Wage, :Pm, :GO_ind, :Inv_ind]
        for col in columns
                mat = pivot_to_matrix(df, col, years, sectors)
                # apply HP filter column by column
                for j in 1:size(mat, 2)
                        mat[:, j] = hpfilter(mat[:, j], smoothing)
                end
                matrices[col] = mat
        end

        # compute equilibrium objects and prices
        Pi = matrices[:Investmentmil] ./ matrices[:Inv_ind]
        k = matrices[:Cap_ind] 
        si = matrices[:Investmentmil] ./ matrices[:GOmil]
        sm = matrices[:Mat] ./ matrices[:GOmil]
        sl = matrices[:Comp] ./ matrices[:GOmil]
        λ = matrices[:Comp] ./ matrices[:VA]
        Wage = matrices[:Wage]
        Pm = matrices[:Pm]
        R = matrices[:GOmil]
        q = matrices[:GO_ind]

        n_years, n_sectors = size(R)

        # store equilibrium objects and prices in vectors
        k = [Float64.(vec(k[t, :])) for t = 1:n_years]
        sl = [Float64.(vec(sl[t, :])) for t = 1:n_years]
        sm = [Float64.(vec(sm[t, :])) for t = 1:n_years]
        si = [Float64.(vec(si[t, :])) for t = 1:n_years]
        λ = [Float64.(vec(λ[t, :])) for t = 1:n_years]
        w = [Float64.(vec(Wage[t, :])) for t = 1:n_years]
        Pm = [Float64.(vec(Pm[t, :])) for t = 1:n_years]
        Pi = [Float64.(vec(Pi[t, :])) for t = 1:n_years]
        R = [Float64.(vec(R[t, :])) for t = 1:n_years]
        q = [Float64.(vec(q[t, :])) for t = 1:n_years]

        return years, sector_names, sl, sm, si, λ, k, w, Pm, Pi, R, q
end

