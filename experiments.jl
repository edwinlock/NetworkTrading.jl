using Revise
using NetworkTrading
using Combinatorics
using Graphs
using NautyGraphs
using IterTools
using ProgressMeter

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
    # For each agent, find the set of trade indices they are involved in
    Ω = [Set([idx for (idx, trade) in enumerate(trades) if i in trade]) for i in 1:n]
    # For each agent, generate all possible valuations
    agent_valuations = []
    for i in 1:n
        trade_indices = collect(Ω[i])
        subsets = collect(powerset(trade_indices, 1))  # all non-empty subsets
        # For each subset, assign a value in vL:vU
        value_ranges = [vL:vU for _ in subsets]
        # Each element of prod is a tuple of values, one for each subset
        prod = IterTools.product(value_ranges...)
        # For each assignment, build a Dict mapping Set(subset) => value
        agent_vals = [Dict(Set(subsets[j]) => vals[j] for j in eachindex(subsets)) for vals in prod]
        agent_val_fns = [(val, generate_valuation(i, trades, val)) for val in agent_vals]
        push!(agent_valuations, agent_val_fns)
    end
    # Take the Cartesian product of all agents' valuations
    all_valuations = IterTools.product(agent_valuations...)
    return all_valuations
end


"""
Given a fixed network specified by Ω, agents 1 to n, and a dictionary
mapping each agent to a ValuationIterator, iterate over all possible valuations
for all agents and create the corresponding market.
"""
function explore_network(Ω, AgentIterators, ub, action_function)
    n = length(AgentIterators)
    buyingtrades = [incoming_trades(i, Ω) for i ∈ 1:n] 
    sellingtrades = [outgoing_trades(i, Ω) for i ∈ 1:n]
    agentiters = [AgentIterators[i](buyingtrades[i], sellingtrades[i], ub) for i ∈ 1:n]
    @info "Finished constructing iterators, starting the search."
    @showprogress for valuations ∈ Iterators.product(agentiters...)
        # Create demand functions for each agent
        demand = [generate_demand(i, Ω, valuations[i]) for i in 1:n]
        # Create the market
        market = Market(Ω, collect(valuations), demand)
        # Generate welfare function
        welfare = generate_welfare_fn(market)
        action_function(market, welfare) || return market
    end
    return nothing
end


"""
Print a valuation function for given trades.
"""
function print_valuation(v, trades)
    trades = collect(trades)
    sort!(trades)
    Ωi = powerset(trades)
    for Φvec ∈ Ωi
        Φ = Set(Φvec)
        println("$(Φvec) => $(v(Φ))")
    end
    return nothing
end


"""
Print the welfare function with given trades.
"""
function print_welfare_fn(w, trades)
    trades = collect(trades)
    Ωi = powerset(trades)
    for Φvec ∈ Ωi
        println("$(Φvec) => $(w(Φvec))")
    end
    return nothing
end


"""
This function checks if the minimum variance, leximin, and leximax solutions
differ for a given market configuration.
"""
function minvar_leximin_leximax_equal(market, welfare)
    # Find the optimal core imputations for min variance, leximin, and leximax
    local minvar_sol = find_optimal_core_imputation(market.n, welfare, :min_variance)
    local leximin_sol = find_optimal_core_imputation(market.n, welfare, :leximin)
    local leximax_sol = find_optimal_core_imputation(market.n, welfare, :leximax)
    epsilon = 0.1
    sols = [minvar_sol, leximin_sol, leximax_sol]
    # Check if any pair of solutions differs by more than epsilon
    if any(sol === nothing for sol in sols)
        println("Empty solution found")
        return true
    end
    for i in 1:length(sols)-1
        for j in i+1:length(sols)
            if !isapprox(sols[i], sols[j]; atol=epsilon)
                println("Valuation config $idx:")
                println("  minvar_sol: $minvar_sol")
                println("  leximin_sol: $leximin_sol")
                println("  leximax_sol: $leximax_sol")
                return false
            end
        end
    end
    return true
end


"""
This function returns true iff the core of the market is nonempty.
"""
function nonemptycore(market, welfare)
    leximin_sol = find_optimal_core_imputation(market.n, welfare, :leximin)
    isnothing(leximin_sol) && return false
    return true
end


function diagnose(market)
    welfare_fn = generate_welfare_fn(found)
    println("Market with $(market.n) agents and $(market.m) trades.")
    println("Market network is given by Ω = $(Ω).")
    println("Now printing valuations.")
    for (i, v) in enumerate(found.valuation)
        println("For agent $i:")
        print_valuation(v, associated_trades(i, found.Ω))
        println()
    end
    println("Welfare function:")
    print_welfare_fn(welfare_fn, 1:found.m)
end

"""
Return true iff leximin == leximax (up to atol).
"""
function leximin_vs_max(market, welfare_fn; atol=0.0001)
    leximin_sol = find_optimal_core_imputation(market.n, welfare_fn, :leximin)
    leximax_sol = find_optimal_core_imputation(market.n, welfare_fn, :leximax)
    return all( abs.(leximin_sol .- leximax_sol) .≤ atol )
end


function positiveleximin(market, welfare_fn; atol=0.001)
    leximin_sol = find_optimal_core_imputation(market.n, welfare_fn, :leximin)
    return minimum(leximin_sol[essentialagents(market, welfare_fn; atol=atol)]; init=1) ≥ atol
end

positiveleximin(market; atol=0.001) = positiveleximin(market, generate_welfare_fn(market); atol=atol)

function zeroleximin(market, welfare_fn; atol=0.001)
    leximin_sol = find_optimal_core_imputation(market.n, welfare_fn, :leximin)
    return minimum(leximin_sol[essentialagents(market, welfare_fn; atol=atol)]; init=1) ≤ atol
end

zeroleximin(market; atol=0.001) = zeroleximin(market, generate_welfare_fn(market); atol=atol)



# TODO: add some action functions according to section 7
# TODO: create loop over all graphs
# TODO: write functions "isdemanded" and "isCE"

# Example 0:
# Generate all non-isomorphic directed graphs with 3 nodes
# graphs = generate_digraphs(n)
# println("Number of non-isomorphic graphs for n=$n: ", length(graphs))
# println("Unique graphs: ", graphs)


# Example 1:
n=3
ub = 2
AgentIterators = [SubstitutesValuations for _ in 1:n]
Ω = [(1,2), (1,3), (3,2)]
found = nothing
found = explore_network(Ω, AgentIterators, ub, nonemptycore)
isnothing(found) || diagnose(found)

# Example 2:
n=3
ub=1
AgentIterators = [AllValuations for _ in 1:n]
Ω = [(1,2), (1,3), (3,2)]
found = nothing
found = explore_network(Ω, AgentIterators, ub, nonemptycore);
isnothing(found) || diagnose(found)

# Example 3:
n=3
ub = 5
AgentIterators = [SubstitutesValuations, AllValuations]
Ω = [(1,2), (2,1)]
found = nothing
found = explore_network(Ω, AgentIterators, ub, nonemptycore);
isnothing(found) || diagnose(found)

# Example 4:
n=3
ub = 2
AgentIterators = [SubstitutesValuations, SubstitutesValuations, SubstitutesValuations]
Ω = [(1,2), (1,3), (3,2)]
found = nothing
found = explore_network(Ω, AgentIterators, ub, positiveleximin);
isnothing(found) || diagnose(found)

# Example 5:
n=3
ub = 2
AgentIterators = [SubstitutesValuations, SubstitutesValuations, SubstitutesValuations]
Ω = [(1,2), (1,3), (3,2)]
found = nothing
found = explore_network(Ω, AgentIterators, ub, leximin_vs_max);
isnothing(found) || diagnose(found)
