using Revise
using NetworkTrading

valmax = 30
Ω = [(1,2), (1,2)]
valuation = [
    generate_random_two_trade_valuation(valmax, valmax, 1, Ω),
    generate_random_two_trade_valuation(valmax, valmax, 2, Ω),
]
offers = [
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax)),
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax))
]
market = Market(Ω, offers, valuation)
steps, data = @time dynamic(market)
plot_offers(market, data)
plot_satisfied(market, data)
plot_welfare(market, data)
