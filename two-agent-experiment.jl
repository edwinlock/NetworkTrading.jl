using Revise
using NetworkTrading
using LazySets
using Plots

# gr(size = (1000, 600))
# pythonplot(size = (800, 600))

# """Function used to perturb LIPs."""
# function δ(i, Ω; ε = 1/2)
#     m = length(Ω)
#     return [χ(i, ω, Ω) * ω * ε / m for ω ∈ 1:m]
# end

function twoBRs(market, p)
    # Step 1: offers of agent 2 are set to p
    market.offers[2] = Dict(1 => p[1], 2 => p[2])
    # Step 2: agent 1 best responds
    best_response!(1, market)
    # Step 3: agent 2 best responds
    best_response!(2, market)
    # Step 4: extract offers of agent 2 as prices q
    q = [market.offers[2][1], market.offers[2][2]]
    return q
end

function coordinates(m, n)
    coords = Matrix{Vector{Int}}(undef, m, n)
    for p ∈ keys(coords)
        coords[p] = [p[1], p[2]]
    end
    return coords
end

destinations(prices, market) = map(p->twoBRs(market, p), prices)

differences(prices, market) = destinations(prices, market) .- prices


function annotate!(plt, coords, dirs)
    for (i, p) ∈ enumerate(coords)
        d = dirs[i]
        draw_arrow!(plt, p, d)
    end
    eq_points = [float.(p) for (i,p) ∈ pairs(coords) if dirs[i] == [0,0]]
    hull = convex_hull(eq_points)
    plot!(plt, VPolygon(hull), alpha=0.3)
    return nothing
end

function create_market(a, b, c, d, m, n)
    Ω = [(1,2), (1,2)]
    valuation = [
        generate_two_trade_valuation(a, b, 1, Ω)
        generate_two_trade_valuation(c, d, 2, Ω)
    ]
    offers = [
        Dict(1 => rand(0:m), 2=>rand(0:n)),
        Dict(1 => rand(0:m), 2=>rand(0:n)),
    ]
    market = Market(Ω, offers, valuation)
    plt = plotLIP(a, b, m, n; color=:blue)
    plotLIP!(plt, c, d, m, n; color=:red)
    coords = coordinates(m, n)
    dirs = differences(coords, market)
    annotate!(plt, coords, dirs)
    return plt, market
end

function create_random_market(m, n)
    a, b = generate_params(m, n)  # Vertices of LIP for agent 1
    c, d = generate_params(m, n)  # Vertices of LIP for agent 2
    return create_market(a, b, c, d, m, n)
end

transform(M) = transpose(M)[end:-1:1,:]

m, n = 8, 8
plt, market = create_random_market(m, n)
coords = coordinates(m, n)
dest = destinations(coords, market)


# Compute how the Lyapunov function changes after two best responses:
# For each price p, the difference L(p) - L(p + d), where d is the price change
# after two best responses.
L = generate_lyapunov_function(market)
Lvals = map(L, coords)
Base.CartesianIndex(coord::Vector{Int}) = Base.CartesianIndex(coord[1], coord[2])
λ(c) = Lvals[CartesianIndex(c)] - Lvals[CartesianIndex(dest[CartesianIndex(c)])]
Ldiff = map(λ, coords)
transform(Ldiff)
plt



m, n = 20, 20
a, b = generate_params(m, n)  # Vertices of LIP for agent 1
c, d = generate_params(m, n)  # Vertices of LIP for agent 2
Ω = [(1,2), (1,2)]
valuation = [
    generate_two_trade_valuation(a, b, 1, Ω)
    generate_two_trade_valuation(c, d, 2, Ω)
]
offers = [
    Dict(1 => rand(0:m), 2=>rand(0:n)),
    Dict(1 => rand(0:m), 2=>rand(0:n)),
]
market = Market(Ω, offers, valuation)
plt = plotLIP(a, b, m, n; color=:blue)
plotLIP!(plt, c, d, m, n; color=:red)
coords = coordinates(m, n)
dirs = differences(coords, market)
annotate!(plt, coords, dirs)
plt


steps, data = dynamic(market)

plot_lyapunov(market, data)
