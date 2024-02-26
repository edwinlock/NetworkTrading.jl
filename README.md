# NetworkTrading

For more examples of how to use the package, see `adhoc.jl`.

```julia
using NetworkTrading

### Example: 3-agent path network
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
```