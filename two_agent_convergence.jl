"""
Code to explore the convergence of the best response dynamics with two agents.

The main aim of this code is to help us figure out a potential function.
"""

using Revise  # so we don't keep having to reload the package
using NetworkTrading
using Plots
plotlyjs()

# Create the market network
Ω = [(1,2), (1,2)]

# Generate random vaulations for the two agents
valmax = 30
valuation = [
    generate_random_two_trade_valuation(valmax, valmax, 1, Ω),
    generate_random_two_trade_valuation(valmax, valmax, 2, Ω),
]

# Generate random offers
offers = [
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax)),
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax))
]

# Create the market
market = Market(Ω, valuation)

# Create dynamic state with initial offers
ds = DynamicState(market, offers)

# Run the dynamics
steps, data = dynamic(market, ds)

# Construct the (partial) Lyapunov functions
L1 = generate_lyapunov_function(market, 1)
L2 = generate_lyapunov_function(market, 2)
L = generate_lyapunov_function(market)

# For agent 1, we want to plot L1 at prices set to her offers in odd-numbered rounds.
rounds1 = 1:2:steps
offers1 = [data.offers[round][1] for round ∈ rounds1]
L1vals = [L1(offers) for offers in offers1]
plot(rounds1, L1vals, marker=:circle, label="L¹(p)", legend=:bottomleft)

# For agent 2, we want to plot L2 at prices set to his offers in even-numbered rounds.
rounds2 = 2:2:steps
offers2 = [data.offers[round][2] for round ∈ rounds2]
L2vals = [L2(offers) for offers in offers2]
plot!(rounds2, L2vals, marker=:square, label="L²(p)")

