using Revise
using NetworkTrading

valmax = 100
Ω = [(1,2), (1,2)]
valuation = [
    generate_random_two_trade_seller_valuation(valmax),
    generate_random_two_trade_buyer_valuation(valmax)
]
demand = [
    generate_two_trade_demand(1, Ω, valuation[1]),
    generate_two_trade_demand(3, Ω, valuation[2]),
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