struct Market{V<:Function, U<:Function, D<:Function}
    n::Int  # number of agents
    m::Int  # number of trades
    Ω::Vector{Tuple{Int,Int}}  # list of trades given as ordered pairs (seller, buyer)
    trades::Vector{Set{Int}}  # set of trades for each agent
    valuation::Vector{V}  # for each agent, a valuation function
    utility::Vector{U}  # for each agent, a utility function
    demand::Vector{D}  # for each agent a demand function
end

struct DynamicState
    offers::Vector{Dict{Int,Int}}  # offers of each agent
    unsatisfied::Set{Int}  # unsatisfied agents
end

# Outer constructors
function Market(Ω::Vector{Tuple{Int,Int}}, valuation, demand)
    m = length(Ω)  # number of trades
    n = length(valuation)  # number of agents

    # Check that input is consistent
    length(demand) ≠ length(valuation) && error("Valuation and demand must have same length.")
    ([t[1] for t in Ω] ∪ [t[2] for t in Ω]) ⊆ 1:n || error("Agents specified in trade must be subset of 1:length(types).")
    any(t[1]==t[2] for t in Ω) && error("Network cannot contain self-loops (trades from an agent to itself).")
    
    # Construct data structures
    trades_per_agent = [associated_trades(i, Ω) for i ∈ 1:n]
    utility = [generate_utility(i, Ω, valuation[i]) for i ∈ 1:n]
    return Market(n, m, Ω, trades_per_agent, valuation, utility, demand)
end

function Market(Ω::Vector{Tuple{Int,Int}}, valuation)
    n = length(valuation)
    demand = [generate_demand(i, Ω, valuation[i]) for i ∈ 1:n]
    return Market(Ω, valuation, demand)
end

function DynamicState(market::Market, offers::Vector{Dict{Int,Int}})
    unsatisfied = Set(1:market.n)
    return DynamicState(offers, unsatisfied)
end


### Utilities

"""
Determine seller or buyer of trade ω in list of trades Ω.
"""
seller(ω, Ω) = Ω[ω][1]
buyer(ω, Ω) = Ω[ω][2]


"""
Determine whether agent i is seller/buyer of trade ω in list of trades Ω.
"""
isseller(i, ω, Ω) = i == seller(ω, Ω)
isbuyer(i, ω, Ω) = i == buyer(ω, Ω)


"""
Define characteristic function that returns 1 if agent i is buyer in ω,
-1 if i is seller in ω, and 0 otherwise.
"""
function χ(i, ω, Ω)
    isbuyer(i, ω, Ω) && return 1
    isseller(i, ω, Ω) && return -1
    return 0
end


"""
    associated_trades(i, Φ, Ω)

Compute all trades in Φ (defaults to all trades, 1:length(Ω)) of Ω associated with agent i.
"""
associated_trades(i, Φ, Ω) = Set(ω for ω ∈ Φ if i ∈ Ω[ω])
associated_trades(i, Ω) = associated_trades(i, 1:length(Ω), Ω)

"""
Compute incoming trades in Ω that are associated with agent i.
"""
incoming_trades(i, Ω) = Set(ω for ω ∈ 1:length(Ω) if isbuyer(i, ω, Ω))

"""
Compute outgoing trades in Ω that are associated with agent i.
"""
outgoing_trades(i, Ω) = Set(ω for ω ∈ 1:length(Ω) if isseller(i, ω, Ω))

"""
Compute all agents involved in trades Φ of Ω.
"""
function associated_agents(Φ::Set{Int}, Ω)
    agents = Set{Int}()
    for ω ∈ Φ
        push!(agents, seller(ω, Ω))
        push!(agents, buyer(ω, Ω))
    end
    return agents
end

"""
Compute counterpart of agent i for trade ω in list of trades Ω.
"""
function counterpart(i, ω, Ω)
    trade = Ω[ω]
    trade[1] == i && return trade[2]
    trade[2] == i && return trade[1]
    error("Agent i must be involved in trade ω.")
end


"""
Retrieve the offers of agent i's neighbours.
"""
function neighbouring_offers(i::Int, market::Market, offers)::Dict{Int,Int}
    prices = Dict{Int,Int}()
    for ω ∈ market.trades[i]  # Set prices[ω] to the offer of counterpart of trade    
        j = counterpart(i, ω, market.Ω)
        prices[ω] = offers[j][ω]
    end
    return prices
end
neighbouring_offers(i::Int, market::Market) = neighbouring_offers(i, offers, market)


"""
Compute welfare (aggregate utility) of market with specified offers.
"""
function welfare(market::Market, offers)
    welfare_sum = 0
    for i in 1:market.n
        p = neighbouring_offers(i, market, offers)
        welfare_sum += indirect_utility(p, market.demand[i], market.utility[i])
    end
    return welfare_sum
end
welfare(market::Market) = welfare(market, offers)


function generate_welfare_fn(market)
    n, m, Ω = market.n, market.m, market.Ω
    all_coalitions = Set.(powerset(1:n))
    nontrivial_coalitions = Set.(powerset(1:n, 3))
    all_bundles = Set.(powerset(1:m))
    d = Dict(C => 0 for C ∈ all_coalitions)
    # Compute the aggregate valuation for each subset of trades.
    for Φ ∈ all_bundles
        C = associated_agents(Φ, Ω)
        welfare = 0
        for i ∈ C
            Φ_i = associated_trades(i, Φ, Ω)
            welfare += market.valuation[i](Φ_i)
        end
        d[C] = max(d[C], welfare)
    end
    # Percolate the maximum values upwards in the lattice of coalitions.
    for C ∈ nontrivial_coalitions
        d[C] = max(d[C], maximum(d[setdiff(C, ω)] for ω ∈ C; init=0))
    end
    # Create function taking a coalition of agents and returning its welfare
    function welfare(C::Vector{Int})
        @assert C ⊆ 1:n "C must be a subset of agents 1 to n."
        return d[Set(C)]
    end
    return welfare
end


"""
Compute active trades and their prices, (p, Ψ).
"""
function active_trades(offers, market::Market)
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


function isessential(market, i, welfare_fn; atol=0.0001)
    grand_coalition = collect(1:market.n)
    welfare = welfare_fn(grand_coalition)
    welfare_without_i = welfare_fn(setdiff(grand_coalition, i))
    return welfare - welfare_without_i ≥ atol
end

isessential(market, i) = isessential(market, i, generate_welfare_fn(market))


function essentialagents(market, welfare_fn; atol=0.00001)
    grand_coalition = collect(1:market.n)
    welfare = welfare_fn(grand_coalition)
    welfares_without = [welfare_fn(setdiff(grand_coalition, i)) for i ∈ grand_coalition]
    essential_agents = [i for i ∈ 1:market.n if welfare - welfares_without[i] ≥ atol]
    return essential_agents
end

essentialagents(market; atol=0.00001) = essentialagents(market, generate_welfare_fn(market); atol=atol)


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
    return Market(Ω, valuation, demand)
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
    return Market(Ω, valuation, demand)
end

function RandomIntermediaryUnitMarket(numsellers, numbuyers, numintermediaries, r)
    sellervals = rand(MINVAL:MAXVAL, numsellers)
    buyervals = rand(MINVAL:MAXVAL, numbuyers)
    return IntermediaryUnitMarket(sellervals, buyervals, numintermediaries, r)
end