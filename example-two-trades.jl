using Revise
using NetworkTrading

valmax = 20
Ω = [(1,2), (1,2)]
valuation = [
    generate_random_two_trade_valuation(valmax, valmax, 1, Ω),
    generate_random_two_trade_valuation(valmax, valmax, 2, Ω),
]
offers = [
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax)),
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax))
]
market = Market(Ω; valuation=valuation, demand=demand, offers=offers)
# market.offers[1] = Dict(1 => 6); market.offers[2] = Dict(1 => 5, 2 => 6); market.offers[3] = Dict(2 => 6)
steps, data = @time dynamic(market)
plot_offers(market, data)
plot_satisfied(market, data)
plot_welfare(market, data)