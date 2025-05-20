using Revise
using NetworkTrading
using Combinatorics
using Graphs
using NautyGraphs

nodes = 1:3
all_edges = [(i, j) for i in nodes, j in nodes if i != j]

unique_canon_graphs = Set{}()
unique_graphs = Set{Vector{Tuple{Int64, Int64}}}()

for edge_subset in powerset(all_edges,1)
    println(typeof(edge_subset))
    g = NautyDiGraph(length(nodes))
    for (i, j) in edge_subset
        add_edge!(g, i, j)
    end
    println("Edges: ", edge_subset)
    println("Graph: ", g)
    # Canonical form of the graph
    canonize!(g)
    println("Canonized Graph: ", g)
    if !(g in unique_canon_graphs)
        push!(unique_canon_graphs, g)
        push!(unique_graphs, edge_subset)
    end
end

println("Number of non-isomorphic graphs: ", length(unique_graphs))
println("Unique graphs: ", unique_graphs)