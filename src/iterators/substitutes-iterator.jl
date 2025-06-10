using CSV
using DataFrames

struct SubstitutesValuations
    n::Int
    ub::Int
    buyingtrades::Set{Int}
    sellingtrades::Set{Int}
    alltrades::Set{Int}
    trade2good::Dict{Int, Int}
    idx::Dict{Set{Int}, Int}  # stores index of each set of *goods* in value vector collect(powerset(1:n))
    df::DataFrame
    numvals::Int
end

Base.length(iter::SubstitutesValuations) = iter.numvals
Base.eltype(iter::SubstitutesValuations) = Function

"""
    SubstitutesValuations(buyingtrades::Set{Int}, sellingtrades::Set{Int}, ub::Int)

An iterator for substitutes valuations.

Example: Suppose we want to iterate over all substitutes valuations with values <= 5
for an agent with buying trade 2 and selling trades 1 and 3. The valuation should be
upper bounded by ub=5.
```
    buyingtrades = Set([2])
    sellingtrades = Set([1,3])
    ub = 5
    iter = SubstitutesValuations(buyingtrades, sellingtrades, ub)
    for valuation ∈ iter:
        # Do something with the valuation
    end
```

"""
function SubstitutesValuations(buyingtrades::Set{Int}, sellingtrades::Set{Int}, ub::Int)
    @assert length(buyingtrades ∩ sellingtrades) == 0 "Buying and selling trades must be disjoint."
    n = length(buyingtrades) + length(sellingtrades)
    alltrades = buyingtrades ∪ sellingtrades
    if n == 2 && ub ≤ 100
        raw_df = CSV.read("src/iterators/substitutes-2-100.csv", DataFrame)
    elseif n == 3 && ub ≤ 15
        raw_df = CSV.read("src/iterators/substitutes-3-15.csv", DataFrame)
    else
        throw(error("Iterator not implemented for more than three trades or ub > 15 / 100."))
    end
    @assert ncol(raw_df) == 2^n "Loaded the wrong file."
    trade2good = Dict(ω => i for (i, ω) ∈ enumerate(alltrades))
    allgoods = Set.(powerset(1:n))
    idx = Dict(Ψ => i for (i, Ψ) ∈ enumerate(allgoods))
    df = subset(raw_df, AsTable(All()) => ByRow(row -> all(<=(ub), row)))
    return SubstitutesValuations(n, ub, buyingtrades, sellingtrades, alltrades, trade2good, idx, df, nrow(df))
end

function Base.iterate(iter::SubstitutesValuations, state=1)
    # Deal with terminating state
    state > nrow(iter.df) && return nothing
    valuation = construct_valuation(iter, state)
    return valuation, state+1
end

function construct_valuation(iter::SubstitutesValuations, state)
    # Retrieve current row from df
    value_vector = collect(iter.df[state, :])
    # Create and return valuation function
    # First we need to determine the value of the empty trade bundle.
    # The empty trade bundle maps to the object bundle containing the selling trades
    # We map the selling trades to goods
    Θ = Set(iter.trade2good[ω] for ω ∈ iter.sellingtrades)
    # And then we compute the value of the empty trade bundle
    emptybundlevalue = value_vector[iter.idx[Θ]]
    function valuation(Φ::Set{Int})
        @assert Φ ⊆ iter.alltrades "Φ must be a valid subset of trades."
        # Convert trade set to object set
        Ψ = (Φ ∩ iter.buyingtrades) ∪ setdiff(iter.sellingtrades, Φ)
        # Map trades to goods
        Θ = Set(iter.trade2good[ω] for ω ∈ Ψ)
        # Get the index of Θ in the valuation vector and return value,
        # taking care to normalise by subtracting emptybundlevalue
        return value_vector[iter.idx[Θ]] - emptybundlevalue
    end
end

function Base.getindex(iter::SubstitutesValuations, i) 
    1 <= i <= iter.numvals || throw(BoundsError(iter, i))
    return construct_valuation(iter, i)
end

Base.firstindex(iter::SubstitutesValuations) = 1
Base.lastindex(iter::SubstitutesValuations) = length(iter)
