struct AllValuations
    n::Int
    ub::Int
    buyingtrades::Set{Int}
    sellingtrades::Set{Int}
    alltrades::Set{Int}
    trade2good::Dict{Int, Int}
    idx::Dict{Set{Int}, Int}  # stores index of each set of *goods* in value vector collect(powerset(1:n))
end

Base.length(iter::AllValuations) = (1+iter.ub)^(2^iter.n-1)
Base.eltype(iter::AllValuations) = Function

"""
    AllValuations(buyingtrades::Set{Int}, sellingtrades::Set{Int}, ub::Int)

An iterator for all valuations with values <= ub.

Example: Suppose we want to iterate over all valuations with values <= 5 for an agent
with buying trade 2 and selling trades 1 and 3.
```
    buyingtrades = Set([2])
    sellingtrades = Set([1,3])
    ub = 5
    iter = AllValuations(buyingtrades, sellingtrades, ub)
    for valuation ∈ iter:
        # Do something with the valuation
    end
```

"""
function AllValuations(buyingtrades::Set{Int}, sellingtrades::Set{Int}, ub::Int)
    @assert length(buyingtrades ∩ sellingtrades) == 0 "Buying and selling trades must be disjoint."
    n = length(buyingtrades) + length(sellingtrades)
    alltrades = buyingtrades ∪ sellingtrades
    trade2good = Dict(ω => i for (i, ω) ∈ enumerate(alltrades))
    allgoodbundles = Set.(powerset(1:n))
    idx = Dict(Ψ => i for (i, Ψ) ∈ enumerate(allgoodbundles))
    return AllValuations(n, ub, buyingtrades, sellingtrades, alltrades, trade2good, idx)
end

function Base.iterate(iter::AllValuations, state=0)
    # Deal with terminating state
    state ≥ length(iter) && return nothing
    values = [0; digits(state, base=iter.ub+1, pad=2^iter.n-1)]
    # Create and return valuation function
    # First we need to determine the value of the empty trade bundle.
    # The empty trade bundle maps to the object bundle containing the selling trades
    # We map the selling trades to goods
    Θ = Set(iter.trade2good[ω] for ω ∈ iter.sellingtrades)
    # And then we compute the value of the empty trade bundle
    emptybundlevalue = values[iter.idx[Θ]]
    function valuation(Φ::Set{Int})
        @assert Φ ⊆ iter.alltrades "Φ must be a valid subset of trades."
        # Convert trade set to object set
        Ψ = (Φ ∩ iter.buyingtrades) ∪ setdiff(iter.sellingtrades, Φ)
        # Map trades to goods
        Θ = Set(iter.trade2good[ω] for ω ∈ Ψ)
        # Get the index of Θ in the valuation vector and return value
        return values[iter.idx[Θ]] - emptybundlevalue
    end
    return valuation, state+1
end