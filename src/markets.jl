
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