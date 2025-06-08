using Revise
using NetworkTrading
using Combinatorics
using Graphs
using NautyGraphs
using IterTools

# Generate all possible directed graphs with n nodes
function generate_digraphs(n::Int)
    nodes = 1:n
    all_edges = [(i, j) for i in nodes, j in nodes if i != j]
    unique_canon_graphs = Set{}()
    unique_graphs = Set{Vector{Tuple{Int64, Int64}}}()
    for edge_subset in powerset(all_edges,1) # omit the empty set
        # Create a directed graph from the edge subset
        g = NautyDiGraph(length(nodes))
        for (i, j) in edge_subset
            add_edge!(g, i, j)
        end
        # get the canonical form of the digraph
        canonize!(g)
        if !(g in unique_canon_graphs)
            push!(unique_canon_graphs, g)
            push!(unique_graphs, edge_subset)
        end
    end
    return unique_graphs
end

function generate_all_valuations(trades::Vector{Tuple{Int, Int}}, n::Int, vL::Int, vU::Int)
    # Step 1: For each agent, find the set of trade indices they are involved in
    Ω = [Set([idx for (idx, trade) in enumerate(trades) if i in trade]) for i in 1:n]
    # Step 2: For each agent, generate all possible valuations
    agent_valuations = []
    for i in 1:n
        trade_indices = collect(Ω[i])
        subsets = collect(powerset(trade_indices, 1))  # all non-empty subsets
        #println("Agent $i subsets: ", subsets)
        # For each subset, assign a value in vL:vU
        value_ranges = [vL:vU for _ in subsets]
        # Each element of prod is a tuple of values, one for each subset
        prod = IterTools.product(value_ranges...)
        #println("Agent $i product: ", prod)
        # For each assignment, build a Dict mapping Set(subset) => value
        agent_vals = [Dict(Set(subsets[j]) => vals[j] for j in eachindex(subsets)) for vals in prod]
        agent_val_fns = [(val, generate_valuation(i, trades, val)) for val in agent_vals]
        #println("length of agent_vals: ", length(agent_vals))   
        push!(agent_valuations, agent_val_fns)
    end
    # Step 3: Take the Cartesian product of all agents' valuations
    all_valuations = IterTools.product(agent_valuations...)
    # for (i, v) in enumerate(all_valuations)
    #     println("Valuation $i: ", v)
    # end
    # Each element is a tuple of Dicts, one per agent
    return all_valuations
end

# Example usage:
n=3
graphs = generate_digraphs(n)
println("Number of non-isomorphic graphs for n=$n: ", length(graphs))
println("Unique graphs: ", graphs)
Ω = [(1,2), (1,3), (3,2)]
all_valuations = generate_all_valuations(Ω, 3, 1, 2)
println("Number of valuations: ", length(all_valuations))

for (idx, val_tuple) in enumerate(all_valuations)
    # Each val_tuple is a tuple of valuation functions, one per agent
    local valuation = collect(getindex.(val_tuple, 2))
    # Generate demand vector for each agent
    local demand = [generate_demand(i, Ω, valuation[i]) for i in 1:n]
    # Create the market
    local market = Market(Ω, valuation, demand)
    # Generate welfare function
    local welfare = generate_welfare_fn(market)
    # Compute solutions
    #println("Valuation config $idx:", collect(getindex.(val_tuple, 1)))
    local minvar_sol = find_optimal_core_imputation(market.n, welfare, :min_variance)
    local leximin_sol = find_optimal_core_imputation(market.n, welfare, :leximin)
    local leximax_sol = find_optimal_core_imputation(market.n, welfare, :leximax)
    epsilon = 0.1
    sols = [minvar_sol, leximin_sol, leximax_sol]

    # Check if any pair of solutions differs by more than epsilon
    function any_pair_differs(sols, epsilon)
        if any(sol === nothing for sol in sols)
            return false  # Can't compare Nothing values
        end
        for i in 1:length(sols)-1
            for j in i+1:length(sols)
                if !isapprox(sols[i], sols[j]; atol=epsilon)
                    return true
                end
            end
        end
        return false
    end
    if any_pair_differs(sols, epsilon)
        println("Valuation config $idx:")
        println("  minvar_sol: $minvar_sol")
        println("  leximin_sol: $leximin_sol")
        println("  leximax_sol: $leximax_sol")
    end
end