"""
Implementations of functions that generate valuation functions, utility functions, and demand functions.

Each valuation, for agent `i`, satisfies the following:
- the empty bundle is mapped to 0.
- bundles containing trades not associated with agent i are mapped to -M.

Utility functions are quasilinear.

Demand functions return a bundle that maximises utility.
"""

using StatsBase
using Combinatorics

const M = 10^8


"""
Return general valuation from dictionary of values of trades.
"""
function generate_valuation(i, Ω, v::Dict{Set{Int}, Int})
    trades = associated_trades(i, Ω)
    @assert all(t in (collect(powerset(collect(trades))) .|> Set) for t in keys(v)) "Keys must be valid bundles of agent $i"
    return function valuation(Ψ::Set{Int})::Int
        Ψ ∈ keys(v) && return v[Ψ]
        Ψ == Set(Int[]) && return 0
        return -M
    end
end


"""
Return utility function for general agents.
"""
function generate_utility(i, Ω, valuation)
    utility(p, Ψ) = valuation(Ψ) - sum(χ(i, ω, Ω)*p[ω] for ω ∈ Ψ; init=0)
    return utility
end


"""
Generate all subsets of trades in Ω associated with agent i in appropriate order.
"""
function all_sets(i, Ω)
    all_trades = associated_trades(i, Ω) |> collect |> sort |> reverse
    all_bundles = all_trades |> powerset |> collect |> reverse .|> Set
    return all_bundles
end


"""
Return demand function for general agents. Breaks ties using leximin rule.

Restrict the domain for improved efficiency.

NB: Demand function returns the inclusion-wise minimal bundle demanded!

"""
function generate_demand(i, Ω, valuation; domain=all_sets(i, Ω))
    utility = generate_utility(i, Ω, valuation)
    return function demand(p)
        return argmax(Ψ->utility(p, Ψ), domain)
    end
end


function indirect_utility(p, demand, utility)
    Ψ = demand(p)
    return utility(p, Ψ)
end


### Specialised implementations for unit demand/supply and intermediaries

"""
Return valuation function for unit demand bidder.
"""
function generate_unit_valuation(i, Ω, values::Dict{Int, Int})
    trades = associated_trades(i, Ω)
    @assert trades == keys(values) "Must provide value for each trade of agent i."
    return function unit_valuation(Φ::Set{Int})::Int
        # First deal with the bundles of size ≠ 1
        length(Φ) == 0 && return 0
        length(Φ) ≥ 2 && return -M
        # Now deal with singleton bundles {ω}
        ω = first(Φ)
        ω ∈ trades && return values[ω]  # if ω is contained in 
        return -M  # 
    end
end
function generate_unit_valuation(i, Ω, val::Int)
    trades = associated_trades(i, Ω)
    values = Dict(ω => val for ω ∈ trades)
    return generate_unit_valuation(i, Ω, values)
end


"""
Return demand function for unit demand agent (can be buyer, seller, or both)
at prices p.
"""
function generate_unit_demand(i, Ω, valuation)
    domain = [Set(ω) for ω ∈ associated_trades(i, Ω)] ∪ [Set(Int[])]
    return generate_demand(i, Ω, valuation, domain=domain)
end


"""
Return valuation function for intermediary.
"""
function generate_intermediary_valuation(i, Ω)
    return function intermediary_valuation(Ψ)
        # If Ψ isn't a subset of agent's associated trades, return -M
        !(Ψ ⊆ associated_trades(i, Ω)) && return -M
        # Now we can assume that Ψ only contains associated trades of i
        # Count number of incoming and outgoing trades.
        # If number is the same, return 0, otherwise -M.
        sum(χ(i, ω, Ω) for ω ∈ Ψ; init=0) == 0 && return 0
        return -M
    end
end


"""
Compute bundle Ψ demanded by intermediary i at prices p in market.
"""
function generate_intermediary_demand(i, Ω)
    incoming_unsorted = collect(incoming_trades(i, Ω))
    outgoing_unsorted = collect(outgoing_trades(i, Ω))
    return function intermediary_demand(p::Dict{Int, Int})
        # Sort incoming (buying) trades of agent i in ascending order wrt price
        # and outgoing (selling) trades of agent i in descending order wrt price
        incoming = sort(incoming_unsorted, by=ω->p[ω])
        outgoing = sort(outgoing_unsorted, by=ω->p[ω], rev=true)
        max_trades = min(length(incoming), length(outgoing))
        # Initialise output bundle. Jointly iterate over incoming and outgoing
        # trades and add pair as long as its profit is > 0.
        Ψ = Set{Int}()
        j = 1
        while j ≤ max_trades && p[outgoing[j]] - p[incoming[j]] > 0
            push!(Ψ, incoming[j], outgoing[j])
            j += 1
        end
        return Ψ
    end
end


"""
Return two valuations points a and b chosen uniformly at random
in box of width m and height n.

"""
function generate_params(m, n)
    coordinates = vcat(
        [[i,n] for i ∈ 0:m],
        [[m,i] for i ∈ n-1:-1:0]
    )
    lengths = vcat(  # determine length of diagonal line for each coordinate
        [1+min(n,i) for i ∈ 0:m],
        [1+min(m,i) for i ∈ n-1:-1:0]
    )
    weights = Weights(map(x->binomial(x+1,2), lengths))  # for sampling
    i = sample(1:length(coordinates), weights)  # sample a coordinate
    c = coordinates[i]  # recover coordinate in question
    k, l = sample(0:lengths[i]-1, 2; ordered=true)  # sample scaling factors
    b = c .- k
    a = c .- l
    return a, b
end


"""
Generate valuation function for Ω = {1,2} from valuation points, a and b using χ vector.
"""
function generate_two_trade_valuation(a::Vector{Int}, b::Vector{Int}, i, Ω)
    χi(ω) = χ(i, ω, Ω)
    @assert all(χi(ω) != 0 for ω ∈ 1:length(Ω))
    # Compute entries of the valuation function
    x = (χi(2) == -1) ? χi(1)*a[1] : χi(1)*b[1]
    y = (χi(1) == -1) ? χi(2)*a[2] : χi(2)*b[2]
    z = (χi(2) == 1) ? χi(1)*a[1] : χi(1)*b[1]
    return function valuation(Ψ::Set{Int})::Int
        @assert Ψ ⊆ Set([1,2]) "Ψ can only be a subset of trades 1 and 2."
        Ψ == Set([1]) && return x
        Ψ == Set([2]) && return y
        Ψ == Set([1,2]) && return y + z
        return 0
    end
end



"""
Generate random valuation function for two trades Ω for agent i.
The LIP of the valuation will have vertices that lie in the box of
width m and height n (with the lower left corner being the origin).
"""
function generate_random_two_trade_valuation(m::Int, n::Int, i, Ω)
    a, b = generate_params(m, n)
    return generate_two_trade_valuation(a, b, i, Ω)
end


"""
Generate Lyapunov function of the object-based market equivalent.
"""
function generate_lyapunov_function(market)
    n, m, Ω = market.n, market.m, market.Ω
    utils = [
        (p, Φ) -> market.valuation[i](τ(Φ, i, Ω)) - sum(p[ω] for ω ∈ Φ; init=0) 
            for i ∈ 1:n
    ]
    all_bundles = [all_sets(i, Ω) for i ∈ 1:n]
    function L(p)
        buyer_contribution = sum(
            maximum(Φ -> utils[i](p, Φ), all_bundles[i])
                for i ∈ 1:n
        )
        seller_contribution = sum(p[ω] for ω ∈ 1:m)
        return buyer_contribution + seller_contribution
    end
    return L
end



"""Convert trades to objects, and vice versa."""
function τ(Φ, i, Ω)
    # Define function that checks membership of ω in (Ωout \ Φ) ∪ (Ωin ∩ Φ)
    function λ(ω)
        isbuyer(i, ω, Ω) && ω ∈ Φ && return true
        isseller(i, ω, Ω) && ω ∉ Φ && return true
        return false
    end

    return Set(ω for ω in eachindex(Ω) if λ(ω) == true)
end



"""
Check whether valuation v with domain A is substitutes. Works by
checking the M♮-concavity property:

For every two subsets S, T of A, and element x ∈ T ∖ S, we have
f(S) + f(T) ≤ max_y f(S + x - y) + f(T + y - x), with the maximum
taken over y ∈ (S ∖ T) ∪ {0}.

Here 0 is the null element.

Equivalently, v is *not* substitutes if there exist two subsets S, T of A
and element x ∈ T ∖ S such that f(S) + f(T) > max_y f(S + x - y) + f(T + y - x),
where the minimum is taken over all y ∈ (S ∖ T) ∪ {0}. This is what the code
checks.

Note: the domain A is a collection of subsets, e.g., powerset(1:n) for n goods.
"""
function issubstitutes(v, A)
    @assert !isempty(A) "Domain must contain at least one bundle."
    for (Φvec, Ψvec) ∈ Iterators.product(A, A)
        Φ, Ψ = Set(Φvec), Set(Ψvec)
        for ψ ∈ setdiff(Ψ, Φ)
            Ψless = setdiff(Ψ, ψ)
            Φmore = Φ ∪ ψ
            f(ϕ) = v(Ψless ∪ Φ) + v(setdiff(Φmore, ϕ))
            if v(Ψ) + v(Φ) > max( v(Ψless) + v(Φmore), maximum(f, setdiff(Φ, Ψ), init=0) )
                @debug "Valuation function failed the M♮-concavity property for Φ=$Φ, Ψ=$Ψ, and ψ=$ψ."
                return false
            end
        end
    end
    return true
end

"""
    issubmodular(v, A)

Checks whether function v with domain A is submodular. 

Uses definition 3 of submodularity in https://en.wikipedia.org/wiki/Submodular_set_function.

"""
function issubmodular(v, A)
    for Φvec ∈ A
        Φ = Set(Φvec)
        for (ω, χ) ∈ Iterators.combination(Φ, 2)
            if v(Φ) > f(setdiff(Φ, ω)) + f(setdiff(Φ, χ)) - f(setdiff(Φ, ω, χ))
                @debug "Valuation function failed the submodularity property for Φ=$Φ, ω=$ω, and χ=$χ."
                return false
            end
        end
    end
    return true
end


function create_valuation_fn(values::Vector{Int})
    n = round(Int, log(2, length(values)))  # number of goods
    d = Dict(Set(Φ) => i for (i, Φ) ∈ enumerate(powerset(1:n)))
    function valuation(Φ::Set{Int})
        @assert Φ ⊆ 1:n "Φ must be a subset of agents 1 to n."
        return values[d[Φ]]
    end
    return valuation
end
