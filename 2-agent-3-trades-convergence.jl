"""
Code to explore the convergence of the best response dynamics with two agents.

The main aim of this code is to help us figure out a potential function.
"""

using Revise  # so we don't keep having to reload the package
using NetworkTrading
using Plots
# plotlyjs()  # optional backend
using ProgressMeter
using PrettyTables


# Create the market network
Ω = [(1,2), (1,2), (1,2)]

# Generate random valuations for the two agents
valmax = 15
subsiters = [SubstitutesValuations(buying_trades(i, Ω), selling_trades(i, Ω), valmax)
                for i ∈ 1:2
            ]
valuation = [ rand(subsiters[i]) for i ∈ 1:2 ]

# Create the market
market = Market(Ω, valuation)

# Generate random offers between 1 and valmax
offers = [
    Dict(key => rand(0:valmax) for key ∈ market.trades[i])
        for i ∈ 1:2
]

# Create dynamic state with initial offers and unsatisfied agents
ds = DynamicState(offers, Set{Int}([1]))

# Run the dynamics
steps, data = dynamic(market, ds)

# # Construct the (partial) Lyapunov functions L^2 and L^2
# L1 = generate_lyapunov_function(market, 1)
# L2 = generate_lyapunov_function(market, 2)

# # For agent 1, we want to plot L1 at prices set to her offers in odd-numbered rounds.
# rounds1 = 1:2:steps
# offers1 = [data.offers[round][1] for round ∈ rounds1]
# L1vals = [L1(offers) for offers in offers1]
# plot(rounds1, L1vals, marker=:circle, label="L¹", legend=:bottomleft)

# # For agent 2, we want to plot L2 at prices set to his offers in even-numbered rounds.
# rounds2 = 2:2:steps
# offers2 = [data.offers[round][2] for round ∈ rounds2]
# L2vals = [L2(offers) for offers in offers2]
# plot!(rounds2, L2vals, marker=:square, label="L²")

# rounds_alt = 2:2:steps
# vals_alt = [(L1(data.offers[round][1]) + L2(data.offers[round][2])) / 2 for round in rounds_alt]
# plot!(rounds_alt, vals_alt, marker=:dtriangle)

# rounds_alt2 = 1:2:steps
# vals_alt2 = [(L1(data.offers[round][1]) + L2(data.offers[round][2])) / 2 for round in rounds_alt2]
# plot!(rounds_alt2, vals_alt2, marker=:utriangle)

# println(vals_alt)

# # Display the plot
# display(current())


function Φ(market, offers; λ = 1.0)
    Ω, n, m = market.Ω, market.n, market.m
    # Compute best responses for all agents
    BRs = [best_response(i, market, offers) for i ∈ 1:n]
    # Compute contribution to Φ(σ) from each trade, and sum them up
    diffs = 0.0
    for ω ∈ 1:m
        b = buyer(ω, Ω)
        s = seller(ω, Ω)
        diff = abs(offers[b][ω] - BRs[b][ω]) + abs(offers[s][ω] - BRs[s][ω])
        diffs += λ^(m - ω) * diff
    end
    return diffs
end

xs = eachindex(data.offers)
zs = [Φ(market, data.offers[i]) for i ∈ xs]
plot!(xs, zs, xticks=xs, yticks=0:maximum(zs))

display(current())

function print_all_offers(market, offers)
    num_rounds = length(offers)
    row_labels = ["Trade $(i)" for i ∈ 1:market.m]
    header = string.(repeat([2, 1], 1 + num_rounds ÷ 2)[1:num_rounds+1])
    header = (
        string.(0:num_rounds),
        string.(repeat([2, 1], 1 + num_rounds ÷ 2)[1:num_rounds+1])
    )

    table_data = zeros(Int, market.m, num_rounds+1)

    # The 0th row:
    for ω ∈ 1:market.m
        table_data[ω, 1] = offers[1][2][ω]
    end
    # The remaining rows
    for round ∈ 1:num_rounds
        agent = 2 - round % 2
        for ω ∈ 1:market.m
            table_data[ω, round+1] = offers[round][agent][ω]
        end
    end

    function field_unchanged(data, i, j)
        j ≤ 2 && return false
        data[i,j] == data[i,j-1] && return true
        return false
    end

    return pretty_table(
        table_data;
        header=header,
        row_labels=row_labels,
        highlighters = Highlighter(field_unchanged, crayon"bg:(100,100,100)")
    )
end

print_all_offers(market, data.offers)


function norm(offers, others)
    n = length(offers)
    @assert length(offers) == length(offers) "The two offer inputs must agree."
    @assert all(keys(offers[i]) == keys(others[i]) for i ∈ 1:n)  "The two offer inputs must agree."

    # Compute and return || offers - others ||^+_∞ + || offers - others ||^-_∞
    positive = maximum(
        max(0, offers[i][ω] - others[i][ω])
        for i ∈ 1:n for ω ∈ keys(offers[i])
    )
    negative = maximum(
        max(0, others[i][ω] - offers[i][ω])
        for i ∈ 1:n for ω ∈ keys(offers[i])
    )

    return positive + negative
end


function is_NE(market::Market, offers)
    # The current implementation works if tie breaking is implemented properly.
    # TODO: A more robust implementation would be to check whether
    # the active trades of each agent i lie in their demanded set at
    # the counterparts' prices
    return all(offers[i] == best_response(i, market, offers) for i ∈ 1:market.n)
end


function all_offers_iterator(market::Market, maxval::Int)
    n, trades = market.n, market.trades
    
    # Get all trade indices for each agent
    agent_trades = [collect(trades[i]) for i in 1:n]
    
    # Calculate total number of price decisions needed
    total_trades = sum(length(agent_trades[i]) for i in 1:n)
    
    # Generate all combinations of prices from 0 to maxval
    return Iterators.product((0:maxval for _ in 1:total_trades)...)
end


function price_tuple_to_offers(market::Market, price_tuple)
    n, trades = market.n, market.trades
    agent_trades = [collect(trades[i]) for i in 1:n]
    
    offers = Vector{Dict{Int,Int}}(undef, n)
    idx = 1
    
    for i in 1:n
        offers[i] = Dict{Int,Int}()
        for ω in agent_trades[i]
            offers[i][ω] = price_tuple[idx]
            idx += 1
        end
    end
    
    return offers
end


function compute_all_NE(market, maxval)
    E = Offers[]
    @showprogress for price_tuple ∈ all_offers_iterator(market, maxval)
        offers = price_tuple_to_offers(market, price_tuple)
        is_NE(market, offers) && push!(E, offers)
    end
    return E
end


function generate_μ(market, maxval)
    E = compute_all_NE(market, maxval)
    function μ(offers)
        return minimum(x -> norm(offers, x), E)
    end
    return μ
end

# E = compute_all_NE(market, valmax)
μ = generate_μ(market, valmax)

xs = eachindex(data.offers)
zs = [μ(data.offers[i]) for i ∈ xs]
plot!(xs, zs, xticks=xs, yticks=0:maximum(zs))

display(current())
