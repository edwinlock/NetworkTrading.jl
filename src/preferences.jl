const M = 10^8

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
Return utility function for arbitrary agents.
"""
function generate_utility(i, Ω, valuation)
    i, Ω = i, Ω
    return function utility(p, Ψ)
        return valuation(Ψ) - sum(χ(i, ω, Ω)*p[ω] for ω ∈ Ψ; init=0)
    end
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
Compute a random valuation for a buyer interested in two goods, 1 and 2.
K governs the magnitude of the valuations.
"""
function generate_random_two_trade_buyer_valuation(K)
    # Draw random values for the values of each bundle
    v = zeros(Int,3)
    v[1] = rand(0:K)
    v[2] = rand(0:K)
    v[3] = v[1] + v[2] - rand(0:K)
    return function buyer_valuation(Ψ::Set{Int})::Int
        @assert Ψ ⊆ Set([1,2]) "Ψ can only be a subset of trades 1 and 2"
        Ψ == Set([]) && return 0
        Ψ == Set([1]) && return v[1]
        Ψ == Set([2]) && return v[2]
        Ψ == Set([1,2]) && return v[3]
    end
end


function generate_random_two_trade_seller_valuation(K)
    val_fn = generate_random_two_trade_buyer_valuation(K)
    return (Ψ) -> -val_fn(Ψ)
end


function generate_two_trade_demand(i, Ω, valuation)
    i, Ω = i, Ω
    util = generate_utility(i, Ω, valuation)
    return function twogood_demand(p::Dict{Int, Int})
        max_util = -1
        max_Ψ = Set{Int}()
        for Ψ in [Set(Int[]), Set([1]), Set([2]), Set([1,2])]
            u = util(p, Ψ)
            if u > max_util
                max_util = u
                max_Ψ = Ψ
            end
        end
        return max_Ψ
    end
end