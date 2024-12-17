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

function annotate!(plt, market, m, n)
    eq_points = Vector{Float64}[]
    for i ∈ -2:1:m+2
        for j ∈ -2:1:n+2
            p = [i,j]
            q = twoBRs(market, p)
            p == q && push!(eq_points, float.(p))
            draw_arrow!(plt, p, q-p)
        end
    end
    hull = convex_hull(eq_points)
    plot!(plt, VPolygon(hull), alpha=0.2)
    return nothing
end

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


function run_market(a, b, c, d, m, n)
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
    annotate!(plt, market, m, n)
    return plt, market
end

function run_random_market(m, n)
    a, b = generate_params(m, n)  # Vertices of LIP for agent 1
    c, d = generate_params(m, n)  # Vertices of LIP for agent 2
    return run_market(a, b, c, d, m, n)
end

m, n = 20, 15
plt, market = run_random_market(m, n)
plt
# k = 4
# plot([run_random_market(m, n) for _ in 1:k]..., layout=k)


# function directions(market, m, n)
#     x = Int[]
#     y = Int[]
#     u = Float64[]
#     v = Float64[]
#     for i ∈ -2:1:m+2
#         for j ∈ -2:1:n+2
#             p = [i,j]
#             q = twoBRs(market, p)
#             d = 0.5 .* (q .- p)
#             push!(x, i)
#             push!(y, j)
#             push!(u, d[1])
#             push!(v, d[2])
#         end
#     end
#     return x, y, u, v
# end
