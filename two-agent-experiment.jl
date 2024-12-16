using Revise
using NetworkTrading
using Plots
using LazySets

"""
Function used to perturb LIPs."""
function δ(i, Ω; ε = 1/2)
    m = length(Ω)
    return [χ(i, ω, Ω) * ω * ε / m for ω ∈ 1:m]
end


Ω = [(1,2), (1,2)]
m, n = 20, 15
# Vertices of LIP for agent 1
a, b = generate_params(m, n)
# Vertices of LIP for agent 2
c, d = generate_params(m, n)

valuation = [
    generate_two_trade_valuation(a, b, 1, Ω)
    generate_two_trade_valuation(c, d, 2, Ω)
]
offers = [
    Dict(1 => rand(0:m), 2=>rand(0:n)),
    Dict(1 => rand(0:m), 2=>rand(0:n)),
]

market = Market(Ω, offers, valuation)

plot()
plotLIP(a, b, m, n; color=:blue)
plotLIP!(c, d, m, n; color=:red)

function equilibrium_region!(m, n)
    points = Vector{Float64}[]
    for i ∈ -2:1:m+2
        for j ∈ -2:1:n+2
            p = [i,j]
            q = twoBRs(p)
            p == q && push!(points, float.(p))
        end
    end
    hull = convex_hull(points)
    return hull
end

function twoBRs(p)
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


function add_arrows!(m, n)
    for i ∈ -2:1:m+2
        for j ∈ -2:1:n+2
            p = [i, j]
            q = twoBRs(p)
            # Step 5: draw arrow from p to q
            draw_arrow!(p, q-p)
        end
    end
end

add_arrows!(m, n)
plot!()  # necessary to make plot visible
hull = equilibrium_region!(m, n)
plot!(VPolygon(hull), alpha=0.2)