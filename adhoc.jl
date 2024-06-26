using Revise
using NetworkTrading

### Test with 3-agent path network
# Agent 1 is seller
# Agent 2 is intermediary
# Agent 3 is buyer

Ω = [(1,2), (2,3)]
valuation = [
    generate_unit_valuation(1, Ω, -10),
    generate_intermediary_valuation(2, Ω),
    generate_unit_valuation(3, Ω, 20)
]
demand = [
    generate_unit_demand(1, Ω, valuation[1]),
    generate_intermediary_demand(1, Ω),
    generate_unit_demand(3, Ω, valuation[3]),
]
offers = [
    Dict(1 => 9),
    Dict(1 => 21, 2=>16),
    Dict(2 => 1)
]
market = Market(Ω; valuation=valuation, demand=demand, offers=offers)
# market.offers[1] = Dict(1 => 6); market.offers[2] = Dict(1 => 5, 2 => 6); market.offers[3] = Dict(2 => 6)
steps, data = @time dynamic(market)
plot_offers(market, data)
plot_satisfied(market, data)
plot_welfare(market, data)

### Test with one seller (1) and three buyers (2,3,4)
Ω = [(1,2), (1,3), (1,4)]
valuation = [
    generate_unit_valuation(1, Ω, 0),
    generate_unit_valuation(2, Ω, 2),
    generate_unit_valuation(3, Ω, 2),
    generate_unit_valuation(4, Ω, 2),
]
demand = [
    generate_unit_demand(1, Ω, valuation[1]),
    generate_unit_demand(2, Ω, valuation[2]),
    generate_unit_demand(3, Ω, valuation[3]),
    generate_unit_demand(4, Ω, valuation[4]),
]
offers = [
    Dict(1 => 1, 2 => 1, 3 => 1),
    Dict(1 => 1),
    Dict(2 => 1),
    Dict(3 => 1),
]
market = Market(Ω; valuation=valuation, demand=demand, offers=offers)
steps, data = @time dynamic(market)
plot_offers(market, data)
plot_satisfied(market, data)
plot_welfare(market, data)


### Test with bipartite network
market = RandomBipartiteUnitMarket(10,10,0.25);
steps, data = @time dynamic(market);
# plot_offers(market, data)
plot_satisfied(market, data)
plot_welfare(market, data)


