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


"""
Compute active trades and prices. Returns prices and set of trades (p, Ψ).
"""
function active(offers, market::Market)
    # Compute trades for which both offers agree, and their prices.
    Ψ = Set{Int}()
    p = Dict{Int,Int}()
    for ω ∈ 1:market.m
        buyer, seller = market.Ω[ω]
        if offers[buyer][ω] == offers[seller][ω]
            push!(Ψ, ω)
            p[ω] = offers[buyer][ω]
        end
    end
    return p, Ψ
end


"""
Compute welfare (aggregate utility) of market with specified offers.
"""
function welfare(offers, market::Market)
    p, Ψ = active(offers, market::Market)    
    return sum(market.utility[i](p,Ψ) for i ∈ 1:market.n;init=0)
end
welfare(market::Market) = welfare(market.offers, market)


### Convenience constructors

const MINVAL = 0
const MAXVAL = 100

"""
Construct a bipartite market with unit buyers and sellers.
Buyer and seller values should be provided, and initial offers are set randomly.
"""
function BipartiteUnitMarket(sellervals, buyervals, r)
    @assert 0 ≤ r ≤ 1 "Connectivity rate r must be between 0 and 1"
    vals = vcat(sellervals, buyervals)
    ns, nb = length(sellervals), length(buyervals)
    sellers, buyers = 1:ns, ns+1:ns+nb
    agents = 1:ns+nb
    Ω = [(s, b) for s ∈ sellers for b ∈ buyers if rand() ≤ r]
    valuation = [generate_unit_valuation(i, Ω, vals[i]) for i ∈ agents]
    demand = [generate_unit_demand(i, Ω, valuation[i]) for i ∈ agents]
    offers = [
        Dict(ω => rand(MINVAL:MAXVAL) for ω ∈ associated_trades(i, Ω))
        for i ∈ agents
    ]
    return Market(Ω; offers=offers, valuation=valuation, demand=demand)
end


"""
Construct a random bipartite market with unit buyers and sellers.
"""
function RandomBipartiteUnitMarket(numsellers, numbuyers, r)
    sellervals = rand(MINVAL:MAXVAL, numsellers)
    buyervals = rand(MINVAL:MAXVAL, numbuyers)
    return BipartiteUnitMarket(sellervals, buyervals, r)
end



"""
Construct a market with unit buyers and sellers, and intermediaries.
Buyer and seller values should be provided, and initial offers are set randomly.
"""
function IntermediaryUnitMarket(sellervals, buyervals, numintermediaries::Int, r)
    @assert 0 ≤ r ≤ 1 "Connectivity rate r must be between 0 and 1"
    vals = vcat(sellervals, buyervals)
    ns, nb, ni = length(sellervals), length(buyervals), numintermediaries
    sellers, buyers, intermediaries = 1:ns, ns+1:ns+nb, ns+nb+1:ns+nb+ni
    agents = 1:ns+nb+ni
    # Trades from sellers to intermediaries
    Ω = vcat(
        [(s, i) for s ∈ sellers for i ∈ intermediaries if rand() ≤ r],
        [(i, b) for i ∈ intermediaries for b ∈ buyers if rand() ≤ r]
    )
    valuation = vcat(
        [generate_unit_valuation(i, Ω, vals[i]) for i ∈ sellers],
        [generate_unit_valuation(i, Ω, vals[i]) for i ∈ buyers],
        [generate_intermediary_valuation(i, Ω) for i ∈ intermediaries],
    )
    demand = vcat(
        [generate_unit_demand(i, Ω, valuation[i]) for i ∈ sellers],
        [generate_unit_demand(i, Ω, valuation[i]) for i ∈ buyers],
        [generate_intermediary_demand(i, Ω) for i ∈ intermediaries],
    )
    offers = [
        Dict(ω => rand(MINVAL:MAXVAL) for ω ∈ associated_trades(i, Ω))
        for i ∈ agents
    ]
    return Market(Ω; offers=offers, valuation=valuation, demand=demand)
end

function RandomIntermediaryUnitMarket(numsellers, numbuyers, numintermediaries, r)
    sellervals = rand(MINVAL:MAXVAL, numsellers)
    buyervals = rand(MINVAL:MAXVAL, numbuyers)
    return IntermediaryUnitMarket(sellervals, buyervals, numintermediaries, r)
end