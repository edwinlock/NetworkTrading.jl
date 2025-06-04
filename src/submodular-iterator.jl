using DataFrames
using Combinatorics

struct SubmodularFunctions
    n::Int
    lb::Vector{Int}
    ub::Vector{Int}
    lowerbounds::Matrix{Set{NTuple{3, Int}}}
    upperbounds::Matrix{Set{NTuple{3, Int}}}
end


function SubmodularFunctions(n, ub)
    lowerbounds, upperbounds = construct_submodularity_bounds(n)
    lb = fill(0, 2^n)
    ub = fill(ub, 2^n)
    ub[1] = 0
    return SubmodularFunctions(n, lb, ub, lowerbounds, upperbounds)
end


"""
Note: No lower bounds are constructed due to the way that powerset() orders sets,
but we may want to change it so the function is written generally.
"""
function construct_submodularity_bounds(n)
    allsets = powerset(1:n)
    idx = Dict(Set(Φ) => i for (i, Φ) ∈ enumerate(allsets))
    upperbounds = reshape([ Set{NTuple{3, Int}}() for _ ∈ 1:2^(2n) ], 2^n, 2^n)
    lowerbounds = reshape([ Set{NTuple{3, Int}}() for _ ∈ 1:2^(2n) ], 2^n, 2^n)
    for Φvec ∈ allsets
        Ψvec = setdiff(1:n, Φvec)
        for (ω, χ) ∈ Iterators.product(Ψvec, Ψvec)
            ω == χ && continue
            Φ = Set(Φvec)
            # Extract all lower/upper bounds from submodularity inequality
            # f(Φ + ω) + f(Φ + χ) ≥ f(Φ + ω + χ) + f(Φ).
            i = idx[union(Φ, ω)]
            j = idx[union(Φ, χ)]
            k = idx[union(Φ, ω, χ)]
            l = idx[Φ]
            # The inequality can now be written as v[i] + v[j] ≥ v[k] + v[l]
            # Upper bounds:
            # 1. v[l] ≤ v[i] + v[j] - v[k]
            # 2. v[k] ≤ v[i] + v[j] - v[l]
            # Lower bounds:
            # 3. v[j] ≥ v[k] + v[l] - v[i]
            # 4. v[i] ≥ v[k] + v[l] - v[j]
            # Add these to upperbounds and lowerbounds
            for x ∈ max(i,j,k):l-1; push!(upperbounds[x,l], (i, j, k)); end
            for x ∈ max(i,j,l):k-1; push!(upperbounds[x,k], (i, j, l)); end
            for x ∈ max(k,l,i):j-1; push!(lowerbounds[x,j], (k, l, i)); end
            for x ∈ max(k,l,j):i-1; push!(lowerbounds[x,i], (k, l, j)); end
        end
    end
    return lowerbounds, upperbounds
end


function _listall(iter::SubmodularFunctions, k::Int, v::Vector{Int}, lb::Vector{Int}, ub::Vector{Int}, solutions)
    # Deal with base case
    if k > 2^iter.n
        push!(solutions, copy(v))
        return
    end
    # Now deal with main case (k <= n)
    for x ∈ lb[k]:ub[k]
        v[k] = x
        # Update lb[i] and ub[i] for all i > k to satisfy submodularity constraints
        # involving sets corresp. to v[1], ..., v[k] and v[i].
        # During this process, if lb[i] > ub[i] for some i, return.
        # Update lb and ub
        infeasible = false
        for i ∈ k+1:2^iter.n
            ub[i] = min(iter.ub[i], minimum(c -> v[c[1]] + v[c[2]] - v[c[3]], iter.upperbounds[k,i]; init=iter.ub[i]))
            lb[i] = max(iter.lb[i], maximum(c -> v[c[1]] + v[c[2]] - v[c[3]], iter.lowerbounds[k,i]; init=iter.lb[i]))
            if lb[i] > ub[i]
                infeasible = true
                break
            end
        end
        infeasible || _listall(iter, k+1, v, lb, ub, solutions)
    end
end


function listall(iter::SubmodularFunctions)
    allsets = powerset(1:iter.n)
    solutions = DataFrame([string(Φ) => Int[] for Φ ∈ allsets]...)
    # solutions = Vector{Vector{Int}}()
    v = fill(0, 2^iter.n)
    lb = copy(iter.lb)
    ub = copy(iter.ub)
    _listall(iter, 1, v, lb, ub, solutions)
    # df = DataFrame([string(Φ) => [sol[i] for sol in solutions] 
                #    for (i, Φ) ∈ enumerate(allsets)]...)
    return solutions
end
