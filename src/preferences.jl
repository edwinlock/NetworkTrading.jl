using StatsBase
using Combinatorics

const M = 10^8


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
    # Initially, work in buyer market, so assume that agent is buyer of all trades
    all_trades = associated_trades(i, Ω) |> collect |> sort |> reverse
    all_bundles = all_trades |> powerset |> collect |> reverse .|> Set
    return all_bundles
    # OLD: when I wanted to implement a version of free disposal
    # now apply the τ function to translate to original market
    # return [τ(Φ, i, Ω) for Φ ∈ all_bundles]
end


"""
Return demand function for general agents. Breaks ties using leximin rule.
"""
function generate_demand(i, Ω, valuation)
    utility = generate_utility(i, Ω, valuation)
    allsets = all_sets(i, Ω)
    return function demand(p)
        return argmax(Ψ->utility(p, Ψ), allsets)
    end
end


function indirect_utility(p, demand, utility)
    Ψ = demand(p)
    return utility(p, Ψ)
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
Return valuation function for unit demand bidder.
"""
function generate_unit_valuation(i, Ω, values::Dict{Int, Int})
    trades = associated_trades(i, Ω)
    @assert trades == keys(values) "Must provide value for each trade of agent i."
    return function unit_valuation(Ψ::Set{Int})::Int
        Φ = Ψ ∩ trades
        length(Φ) == 0 && return 0
        length(Φ) == 1 && return values[first(Φ)]
        return -M
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

NB: Demand function returns the inclusion-wise minimal bundle demanded!
"""
function generate_unit_demand(i, Ω, valuation)
    i, Ω = i, Ω
    trades = associated_trades(i, Ω)
    util = generate_utility(i, Ω, valuation)
    return function unit_demand(p::Dict{Int, Int})
        max_utility = 0
        Ψ = Set{Int}()
        for ω ∈ intersect(keys(p), trades)
            u = util(p, Set(ω))
            if u > max_utility
                max_utility = u
                Ψ = Set(ω)
            end
        end
        return Ψ
    end
end


"""
Return valuation function for intermediary.
"""
function generate_intermediary_valuation(i, Ω)
    i, Ω = i, Ω
    return function intermediary_valuation(Ψ)
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
    i, Ω = i, Ω
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