struct AdditiveValuations
    n::Int
    ub::Int
    buyingtrades::Set{Int}
    sellingtrades::Set{Int}
    alltrades::Set{Int}
    trade2good::Dict{Int, Int}
    numvals::Int
end

Base.length(iter::AdditiveValuations) = iter.numvals
Base.eltype(iter::AdditiveValuations) = Function

"""
    AdditiveValuations(buyingtrades::Set{Int}, sellingtrades::Set{Int}, ub::Int)

An iterator for additive valuations.

Example: Suppose we want to iterate over all additive valuations with values <= 5
for an agent with buying trade 2 and selling trades 1 and 3. The valuation should be
upper bounded by ub=5.
```
    buyingtrades = Set([2])
    sellingtrades = Set([1,3])
    ub = 5
    iter = AdditiveValuations(buyingtrades, sellingtrades, ub)
    for valuation ∈ iter:
        # Do something with the valuation
    end
```

"""
function AdditiveValuations(buyingtrades::Set{Int}, sellingtrades::Set{Int}, ub::Int)
    @assert length(buyingtrades ∩ sellingtrades) == 0 "Buying and selling trades must be disjoint."
    n = length(buyingtrades) + length(sellingtrades)
    alltrades = buyingtrades ∪ sellingtrades
    trade2good = Dict(ω => i for (i, ω) ∈ enumerate(alltrades))
    numvals = (1+ub)^n
    return AdditiveValuations(n, ub, buyingtrades, sellingtrades, alltrades, trade2good, numvals)
end

function Base.iterate(iter::AdditiveValuations, state=0)
    # Deal with terminating state
    state ≥ length(iter) && return nothing
    valuation = construct_valuation(iter, state)
    return valuation, state+1
end

function construct_valuation(iter::AdditiveValuations, state::Int)
    # Compute additive values
    additive_values = digits(state, base=iter.ub+1, pad=iter.n)
    # First we need to determine the value of the empty trade bundle.
    # The empty trade bundle maps to the object bundle containing the selling trades
    # We map the selling trades to goods
    Θ = Set(iter.trade2good[ω] for ω ∈ iter.sellingtrades)
    # And then we compute the value of the empty trade bundle
    emptybundlevalue = sum(additive_values[ω] for ω ∈ Θ; init=0)
    # Create and return valuation function
    function valuation(Φ::Set{Int})
        @assert Φ ⊆ iter.alltrades "Φ must be a valid subset of trades."
        # Convert trade set to object set
        Ψ = (Φ ∩ iter.buyingtrades) ∪ setdiff(iter.sellingtrades, Φ)
        # Map trades to goods
        Θ = Set(iter.trade2good[ω] for ω ∈ Ψ)
        # Compute and return the value of Θ
        return sum(additive_values[ω] for ω ∈ Θ; init=0) - emptybundlevalue
    end
    return valuation
end

function Base.getindex(iter::AdditiveValuations, i::Int) 
    0 <= i <= iter.numvals-1 || throw(BoundsError(iter, i))
    return construct_valuation(iter, i)
end

function Base.getindex(iter::AdditiveValuations, idx::Vector{Int})
    idx ⊆ 0:iter.numvals-1 || throw(BoundsError(iter, idx))
    return [ construct_valuation(iter, i) for i ∈ idx ]
end

Base.firstindex(iter::AdditiveValuations) = 0
Base.lastindex(iter::AdditiveValuations) = length(iter)-1

function Random.rand(rng::Random.AbstractRNG, iter::AdditiveValuations)
    idx = rand(rng, 1:length(iter))
    return iter[idx]
end

# Convenience method that uses the default RNG
Random.rand(iter::AdditiveValuations) = rand(Random.default_rng(), iter)

# Function for returning multiple
function Random.rand(rng::Random.AbstractRNG, iter::AdditiveValuations, n::Int)
    idx = rand(rng, 1:length(iter), n)
    return iter[idx]
end

# Convenience method that uses the default RNG
Random.rand(iter::AdditiveValuations, n::Int) = rand(Random.default_rng(), iter, n)
