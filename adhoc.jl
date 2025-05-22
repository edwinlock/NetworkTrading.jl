using Revise
using NetworkTrading

#ENV["JULIA_DEBUG"] = "all"

### Test with 3-agent network
# Agent 1 is seller
# Agent 2 is buyer
# Agent 3 is buyer and seller

Ω = [(1,2), (1,3), (3,2)]
v = Dict{Int, Dict{Set{Int}, Int}}()
# v[1] = Dict(Set([1]) => 4, Set([2]) => 2, Set([1,2]) => 7)
# v[2] = Dict(Set([1]) => 6, Set([3]) => 4, Set([1,3]) => 9)
# v[3] = Dict(Set([2]) => 5, Set([3]) => 2, Set([2,3]) => 10)

v = [Dict(Set([1]) => 2, Set([2]) => 2, Set([2, 1]) => 1),
     Dict(Set([3]) => 1, Set([1]) => 2, Set([3, 1]) => 1),
     Dict(Set([3]) => 1, Set([2]) => 1, Set([2, 3]) => 1)]

valuation = [generate_valuation(i, Ω, v[i]) for i in 1:3]
demand = [generate_demand(i, Ω, valuation[i]) for i in 1:3]
market = Market(Ω, valuation, demand)
w = generate_welfare_fn(market)
println("welfare grand coalition: ", w([1,2,3])) # 
# valuation[1](Set(Int[])) ## test empty bundle

minvar_sol = find_optimal_core_imputation(market.n, w, :min_variance)
leximin_sol = find_optimal_core_imputation(market.n, w, :leximin)
leximax_sol = find_optimal_core_imputation(market.n, w, :leximax)


#### Welfare function with 3 agents
# n = 3
# function w(C::Vector{Int})
#     length(C) ≤ 1 && return 0
#     C == [1,2] && return 0
#     C == [1,3] && return 6
#     C == [2,3] && return 3
#     C == [1,2,3] && return 8
#     return nothing
# end





#ds = DynamicState(market, offers)
#@time steps, data = dynamic(market, ds)

### Test with 3-agent path network
# Agent 1 is seller
# Agent 2 is intermediary
# Agent 3 is buyer

# Ω = [(1,2), (2,3)]
# valuation = [
#     generate_unit_valuation(1, Ω, -10),
#     generate_intermediary_valuation(2, Ω),
#     generate_unit_valuation(3, Ω, 20)
# ]
# demand = [
#     generate_unit_demand(1, Ω, valuation[1]),
#     generate_intermediary_demand(1, Ω),
#     generate_unit_demand(3, Ω, valuation[3]),
# ]
# offers = [
#     Dict(1 => 9),
#     Dict(1 => 21, 2=>16),
#     Dict(2 => 1)
# ]
# market = Market(Ω, valuation, demand)
# ds = DynamicState(market, offers)
# # offers[1] = Dict(1 => 6); offers[2] = Dict(1 => 5, 2 => 6); offers[3] = Dict(2 => 6)
# steps, data = @time dynamic(market, ds)
# plot_offers(market, data)
# plot_satisfied(market, data)
# plot_welfare(market, data)

# ### Test with one seller (1) and three buyers (2,3,4)
# Ω = [(1,2), (1,3), (1,4)]
# valuation = [
#     generate_unit_valuation(1, Ω, 0),
#     generate_unit_valuation(2, Ω, 2),
#     generate_unit_valuation(3, Ω, 2),
#     generate_unit_valuation(4, Ω, 2),
# ]
# demand = [
#     generate_unit_demand(1, Ω, valuation[1]),
#     generate_unit_demand(2, Ω, valuation[2]),
#     generate_unit_demand(3, Ω, valuation[3]),
#     generate_unit_demand(4, Ω, valuation[4]),
# ]
# offers = [
#     Dict(1 => 1, 2 => 1, 3 => 1),
#     Dict(1 => 1),
#     Dict(2 => 1),
#     Dict(3 => 1),
# ]
# market = Market(Ω, valuation, demand)
# steps, data = @time dynamic(market)
# plot_offers(market, data)
# plot_satisfied(market, data)
# plot_welfare(market, data)


# ### Test with bipartite network
# market = RandomBipartiteUnitMarket(10,10,0.25);
# steps, data = @time dynamic(market);
# # plot_offers(market, data)
# plot_satisfied(market, data)
# plot_welfare(market, data)