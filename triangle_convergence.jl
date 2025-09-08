"""
Code to explore the convergence of the best response dynamics with two agents.

The main aim of this code is to help us figure out a potential function.
"""

using Revise  # so we don't keep having to reload the package
using NetworkTrading
using Plots
# plotlyjs()  # optional backend

# Create the market network
# Ω = [(1,2), (2,3), (3,1)]
Ω = [(1,2), (2,3), (3,2)]
# Ω = [(1,2), (2,3), (3,1)]

# Generate random valuations for the two agents
valmax = 15
subsiters = [SubstitutesValuations(buying_trades(i, Ω), selling_trades(i, Ω), valmax)
                for i ∈ 1:3
            ]
valuation = [ rand(subsiters[i]) for i ∈ 1:3 ]


# Create the market
market = Market(Ω, valuation)

# Generate random offers between 1 and valmax
offers = [
    Dict(key => rand(0:valmax) for key ∈ market.trades[i])
        for i ∈ 1:3
]

# Create dynamic state with initial offers and unsatisfied agents
ds = DynamicState(offers, Set{Int}([1]))

# Run the dynamics
steps, data = dynamic(market, ds)

# Construct the (partial) Lyapunov functions L^2 and L^2
L1 = generate_lyapunov_function(market, 1)
L2 = generate_lyapunov_function(market, 2)

# For agent 1, we want to plot L1 at prices set to her offers in odd-numbered rounds.
rounds1 = 1:2:steps
offers1 = [data.offers[round][1] for round ∈ rounds1]
L1vals = [L1(offers) for offers in offers1]
plot(rounds1, L1vals, marker=:circle, label="L¹", legend=:bottomleft)

# For agent 2, we want to plot L2 at prices set to his offers in even-numbered rounds.
rounds2 = 2:2:steps
offers2 = [data.offers[round][2] for round ∈ rounds2]
L2vals = [L2(offers) for offers in offers2]
plot!(rounds2, L2vals, marker=:square, label="L²")

rounds_alt = 2:2:steps
vals_alt = [(L1(data.offers[round][1]) + L2(data.offers[round][2])) / 2 for round in rounds_alt]
plot!(rounds_alt, vals_alt, marker=:dtriangle)

rounds_alt2 = 1:2:steps
vals_alt2 = [(L1(data.offers[round][1]) + L2(data.offers[round][2])) / 2 for round in rounds_alt2]
plot!(rounds_alt2, vals_alt2, marker=:utriangle)

println(vals_alt)

# Display the plot
display(current())


function V(market, offers)
    # Compute best responses for all agents
    BRs = [best_response(i, market, offers) for i ∈ 1:market.n]
    # Compute contribution to V from each agent, and sum them up
    Vcontributions = [
        sum(abs(offers[i][ω] - BRs[i][ω]) for ω ∈ market.trades[i])
            for i ∈ 1:market.n
    ]
    return sum(Vcontributions)
end

xs = eachindex(data.offers)
ys = [V(market, data.offers[i]) for i ∈ xs]
plot(xs, ys)

display(current())