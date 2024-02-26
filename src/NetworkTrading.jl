module NetworkTrading

struct Market
    n::Int  # number of agents
    m::Int  # number of trades
    Ω::Vector{Tuple{Int,Int}}  # list of trades given as ordered pairs (seller, buyer)
    trades::Vector{Set{Int}}  # trades of agent i for each agent
    offers::Vector{Dict{Int,Int}}  # for each agent, dict mapping trades to offer
    unsatisfied::Set{Int}  # set of unsatisfied agents in the market
    valuation::Vector{Function}
    utility::Vector{Function}
    demand::Vector{Function}

    # Inner constructor
    function Market(Ω; offers, valuation, demand)
        m = length(Ω)  # number of trades
        n = length(valuation)  # number of agents
        # Check that input is consistent
        length(demand) ≠ length(valuation) && error("Valuation and demand must have same length.")
        ([t[1] for t in Ω] ∪ [t[2] for t in Ω]) ⊆ 1:n || error("Agents specified in trade must be subset of 1:length(types).")
        any(t[1]==t[2] for t in Ω) && error("Network cannot contain loops (trades from an agent to itself).")
        # Construct data structures
        trades_per_agent = [associated_trades(i, Ω) for i ∈ 1:n]
        # offers = [Dict(ω => rand(MINVAL:MAXVAL) for ω ∈ trades_per_agent[i]) for i ∈ 1:n]
        unsatisfied = Set(1:n)
        utility = [generate_utility(i, Ω, valuation[i]) for i ∈ 1:n]
        new(n, m, Ω, trades_per_agent, offers, unsatisfied, valuation, utility, demand)
    end
end

### Utilities

"""
Determine whether agent i is seller/buyer of trade ω in list of trades Ω.
"""
isseller(i, ω, Ω) = i == Ω[ω][1]
isbuyer(i, ω, Ω) = i == Ω[ω][2]


"""
Define characteristic function that returns 1 if agent i is buyer in ω, -1
if i is seller in ω, and 0 otherwise.
"""
function χ(i, ω, Ω)
    isbuyer(i, ω, Ω) && return 1
    isseller(i, ω, Ω) && return -1
    return 0
end


"""
Compute all trades in Ω that are associated with agent i.
"""
associated_trades(i, Ω) = Set(ω for ω ∈ 1:length(Ω) if i ∈ Ω[ω])

"""
Compute incoming trades in Ω that are associated with agent i.
"""
incoming_trades(i, Ω) = Set(ω for ω ∈ 1:length(Ω) if isbuyer(i, ω, Ω))

"""
Compute outgoing trades in Ω that are associated with agent i.
"""
outgoing_trades(i, Ω) = Set(ω for ω ∈ 1:length(Ω) if isseller(i, ω, Ω))

"""
Compute counterpart of agent i for trade ω in list of trades Ω.
"""
function counterpart(i, ω, Ω)
    trade = Ω[ω]
    if trade[1] == i
        return trade[2]
    elseif trade[2] == i
        return trade[1]
    else
        error("Agent i must be involved in trade ω.")
    end
end

include("dynamic.jl")
include("preferences.jl")
include("plotting.jl")
include("markets.jl")

export Market, isseller, isbuyer, associated_trades, incoming_trades, outgoing_trades, χ, counterpart
export neighbouring_offers, active, welfare, compute_offers, best_response!, dynamic
export generate_intermediary_demand, generate_intermediary_valuation, generate_utility, generate_unit_valuation, generate_unit_demand
export plot_offers, plot_satisfied, plot_welfare
export BipartiteUnitMarket, RandomBipartiteUnitMarket, IntermediaryUnitMarket, RandomIntermediaryUnitMarket

end
