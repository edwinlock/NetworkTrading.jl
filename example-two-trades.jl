using Revise
using NetworkTrading
using Plots

valmax = 30
Ω = [(1,2), (1,2)]

# Generate random valuations
valuation = [
    generate_random_two_trade_valuation(valmax, valmax, 1, Ω),
    generate_random_two_trade_valuation(valmax, valmax, 2, Ω),
]

# Create the market
market = Market(Ω, valuation)

# Generate random offers
offers = [
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax)),
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax))
]

# Create dynamic state with initial offers
ds = DynamicState(market, offers)

# Run the dynamics
steps, data = dynamic(market, ds)

plot_offers(market, data)
plot_satisfied(market, data)
plot_welfare(market, data)
