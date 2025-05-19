using Revise
using JuMP, Gurobi
using Combinatorics
using ProgressMeter

const env = Gurobi.Env()

function generate_welfare_fn(market)
    n, m, Ω = market.n, market.m, market.Ω
    all_coalitions = Set.(powerset(1:n))
    nontrivial_coalitions = Set.(powerset(1:n, 3))
    all_bundles = Set.(powerset(1:m))
    d = Dict(C => 0 for C ∈ all_coalitions)
    # Compute the aggregate valuation for each subset of trades.
    for Φ ∈ all_bundles
        C = associated_agents(Φ, Ω)
        welfare = 0
        for i ∈ C
            Φ_i = associated_trades(i, Φ, Ω)
            welfare += market.valuation[i](Φ_i)
        end
        d[C] = max(d[C], welfare)
        # println("Φ: $Φ, C: $C, welfare: $welfare")
    end
    # Percolate the maximum values upwards in the lattice of coalitions.
    for C ∈ nontrivial_coalitions
        d[C] = max(d[C], maximum(d[setdiff(C, ω)] for ω ∈ C; init=0))
    end
    # Create a function that takes a vector of agents and returns the welfare
    # for that coalition.
    function welfare(C::Vector{Int})
        @assert C ⊆ 1:n "C must be a subset of agents 1 to n."
        return d[Set(C)]
    end
    return welfare
end


"""
Create model to find a minimum variance core imputation
of the cooperative market game defined by agents 1 to `n` and
welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:

min     sum(x_i^2 for i ∈ 1:n)
s.t.    sum(x_i for i ∈ 1:n) == w(1:n)
        sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ 1:n.

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function minvar_model(n::Int, w)
    grand_coalition = collect(1:n)
    proper_subsets = collect.(powerset(1:n, 1, n-1))
    model = Model(() -> Gurobi.Optimizer(env))
    @variable(model, x[1:n])
    @constraint(model, eq, sum(x) == w(grand_coalition))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    @objective(model, Min, sum(x[i]^2 for i ∈ 1:n))
    return model, x
end



"""
Create model to find a leximin core imputation of the cooperative
market game defined by agents 1 to `n` and welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:

leximax y
s.t.    sum(x_i for i ∈ 1:n) == w(1:n)
        sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ 1:n.
        x_i ≥ 0, for all i ∈ 1:n
        P is a permutation matrix
        y = P x
        y is sorted in ascending order

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function leximin_model(n::Int, w)
    # First we define a constant for the objective function, i.e., M = 1 / ε.
    # This constant should probably depend on n and the magnitude of the values in w.
    # For now, we set it to a fairly large number. TODO: improve.
    M = 500

    grand_coalition = collect(1:n)
    proper_subsets = collect.(powerset(1:n, 1, n-1))
    model = Model(() -> Gurobi.Optimizer(env))
    
    ## Define variables
    @variable(model, x[1:n] ≥ 0)
    @variable(model, y[1:n] ≥ 0)
    @variable(model, P[1:n, 1:n], Bin)

    ## Define constraints
    # Ensure that x is in the core
    @constraint(model, eq, sum(x) == w(grand_coalition))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    # Ensure that P is a permutation matrix
    @constraint(model, col[i ∈ 1:n], sum(P[:,i]) == 1)
    @constraint(model, row[i ∈ 1:n], sum(P[i,:]) == 1)
    # Define relation y == P x
    @constraint(model, P * x == y)  # change to .== if Gurobi can't handle ==
    # Ensure that y is sorted in ascending order
    @constraint(model, sorting[i ∈ 1:n-1], y[i] ≤ y[i+1])

    ## Define objective
    @objective(model, Max, sum(M^(n-i) * y[i] for i ∈ 1:n))
    
    return model, x, y
end


"""
Create model to find a leximax core imputation of the cooperative
market game defined by agents 1 to `n` and welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:

leximin y
s.t.    sum(x_i for i ∈ 1:n) == w(1:n)
        sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ 1:n.
        x_i ≥ 0, for all i ∈ 1:n
        P is a permutation matrix
        y = P x
        y is sorted in descending order

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function leximax_model(n::Int, w)
    # First we define a constant for the objective function, i.e., M = 1 / ε.
    # This constant should probably depend on n and the magnitude of the values in w.
    # For now, we set it to a fairly large number. TODO: improve.
    M = 500
    model, x, y = leximin_model(n, w)
    # Change the objective to leximax
    @objective(model, Min, sum(M^(i) * y[i] for i ∈ 1:n))
    return model, x
end


function find_optimal_core_imputation(n::Int, w, objective::Symbol)
    # Define the model based on the objective specified
    if objective == :leximin
        model_fn = leximin_model
    elseif objective == :leximax
        model_fn = leximax_model
    elseif objective == :min_variance
        model_fn = minvar_model
    else
        error("Unknown objective function: $(objective)")
    end
    # Create model and core imputation variables
    model, x = model_fn(n, w)
    set_silent(model)
    set_optimizer_attribute(model, "OutputFlag", 0)
    # Solve model and return result
    optimize!(model)
    # @info "$(objective) core imputation: $(value.(x))"
    return value.(x)
end



########### ad-hoc test of min-variance function:
# n = 3
# function w(C::Vector{Int})
#     length(C) ≤ 1 && return 0
#     C == [1,2] && return 0
#     C == [1,3] && return 6
#     C == [2,3] && return 3
#     C == [1,2,3] && return 8
#     return nothing
# end

# minvar_sol = find_optimal_core_imputation(n, w, :min_variance)
# leximin_sol = find_optimal_core_imputation(n, w, :leximin)
# leximax_sol = find_optimal_core_imputation(n, w, :leximax)


# Below, there's lots of code to explore leximin and leximax core outcome for arbitrary super-additive characteristic functions.

function generate_all_three_agent_values(; ub=100)
    values = Tuple{Int, Int, Int, Int}[]
    for (a, b, c) ∈ Iterators.product(0:ub, 0:ub, 0:ub)
        for d ∈ max(a+b, a+c, b+c) : ub
            # println("$a, $b, $c, $d")
            push!(values, (a, b, c, d))
        end
    end
    return values
end


function create_three_agent_welfare_fn(a, b, c, d)
    function welfare(C::Vector{Int})
        @assert C ⊆ 1:3 "C must be a subset of agents 1 to 3."
        length(C) <= 1 && return 0
        C == [1, 2] && return a
        C == [1, 3] && return b
        C == [2, 3] && return c
        return d
    end
    return welfare
end



function generate_all_four_agent_values(; ub=5)
    values = Tuple{Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int}[]
    for (a, b, c, d, e, f) ∈ Iterators.product(0:ub, 0:ub, 0:ub, 0:ub, 0:ub, 0:ub)
        g_min = max(a+b, a+d, b+d)
        h_min = max(a+c, a+e, c+e)
        i_min = max(b+c, b+f, c+f)
        j_min = max(d+e, d+f, e+f)
        for (g, h, i, j) ∈ Iterators.product(g_min:ub, h_min:ub, i_min:ub, j_min:ub)
            k_min = max(a+f, b+e, c+d, a+i, a+j, b+h, b+j, c+g, c+j, d+h, d+i, e+h, e+i, f+g, f+h, g+h, g+i, g+j, h+i, h+j, i+j)
            for k ∈ k_min:ub
                push!(values, (a, b, c, d, e, f, g, h, i, j, k))
            end
        end
    end
    return values
end


function create_four_agent_welfare_fn(a, b, c, d, e, f, g, h, i, j, k)
    function welfare(C::Vector{Int})
        @assert C ⊆ 1:4 "C must be a subset of agents 1 to 3."
        length(C) <= 1 && return 0
        C == [1, 2] && return a
        C == [1, 3] && return b
        C == [2, 3] && return c
        return d
    end
    return welfare
end




# # Try all possible welfare functions with values w(S) \leq ub.
# begin
#     n = 3
#     ub = 10
#     dgts = 3
#     @info "Starting exploration of all possible welfare functions for 3 agents with values w(S) ≤ $ub."
#     all_values = generate_all_three_agent_values(ub=ub)
#     @showprogress for (a, b, c, d) ∈ all_values
#         @debug "Considering the welfare function values ($a, $b, $c, $d)."
#         w = create_three_agent_welfare_fn(a, b, c, d)
#         minvar_sol = round.(find_optimal_core_imputation(n, w, :min_variance), digits=dgts)
#         leximin_sol = round.(find_optimal_core_imputation(n, w, :leximin), digits=dgts)
#         leximax_sol = round.(find_optimal_core_imputation(n, w, :leximax), digits=dgts)
#         @debug "minvar: $(minvar_sol)"
#         @debug "leximin: $(leximin_sol)"
#         @debug "leximax: $(leximax_sol)"
#         if !(leximin_sol ≈ leximax_sol)
#             println("The welfare function with values ($a, $b, $c, $d) has different leximin and leximax values:")
#             println("Leximin is $(leximin_sol) and leximax is $(leximax_sol).")
#         end
#         if !(minvar_sol ≈ leximin_sol)
#             println("The welfare function with values ($a, $b, $c, $d) has different minvar and leximin values:")
#             println("Leximin is $(minvar_sol) and leximax is $(leximin_sol).")
#         end
#         if !(minvar_sol ≈ leximax_sol)
#             println("The welfare function with values ($a, $b, $c, $d) has different minvar and leximax values:")
#             println("Leximin is $(minvar_sol) and leximax is $(leximax_sol).")
#         end
#     end
#     @info "Finished exploring."
# end


# Try all possible welfare functions with values w(S) \leq ub.
begin
    ub = 10
    dgts = 3
    @info "Starting exploration of all possible welfare functions for 4 agents with values w(S) ≤ $ub."
    all_values = generate_all_four_agent_values(ub=ub)
    @showprogress for (a, b, c, d, e, f, g, h, i, j, k) ∈ all_values
        w = create_four_agent_welfare_fn(a, b, c, d, e, f, g, h, i, j, k)
        minvar_sol = round.(find_optimal_core_imputation(n, w, :min_variance), digits=dgts)
        leximin_sol = round.(find_optimal_core_imputation(n, w, :leximin), digits=dgts)
        leximax_sol = round.(find_optimal_core_imputation(n, w, :leximax), digits=dgts)
        @debug "minvar: $(minvar_sol)"
        @debug "leximin: $(leximin_sol)"
        @debug "leximax: $(leximax_sol)"
        if !(leximin_sol ≈ leximax_sol)
            println("The welfare function with values ($a, $b, $c, $d) has different leximin and leximax values:")
            println("Leximin is $(leximin_sol) and leximax is $(leximax_sol).")
        end
        if !(minvar_sol ≈ leximin_sol)
            println("The welfare function with values ($a, $b, $c, $d) has different minvar and leximin values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximin_sol).")
        end
        if !(minvar_sol ≈ leximax_sol)
            println("The welfare function with values ($a, $b, $c, $d) has different minvar and leximax values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximax_sol).")
        end
    end
    @info "Finished exploring."
end

### An iterator to generate all welfare functions w for sets S ⊆ 1:n with integer entries w(S) \in [0, ub].
struct WelfareFunctions
    n::Int  # ground set 1 to n
    all_sets::Vector{Vector{Int}}
    index::Dict{Vector{Int}, Int}  # maps each set to index in all_sets
    ub::Int
end


function WelfareFunctions(n, ub)
    allsets = collect(powerset(1:n))
    numsets = 2^n
    index = Dict(allsets[i] => i for i ∈ 1:numsets)
    return WelfareFunctions(n, allsets, index, ub)
end


function Base.iterate(iter::WelfareFunctions, w::Vector{Int})
    numsets = 2^iter.n
    # Update the state w
    w = copy(w)
    # Starting from last entry, increment entries and and carry over if entry exceeds iter.ub or any subsequent entry exceeds iter.ub
    i = numsets
    while i ≥ 1+iter.n+1  # we don't want to increment the first 1+n entries, because they correspond to sets of size <= 1
        w[i] += 1
        # Set entries w[k+1], ..., w[n] to lowest possible value given entries w[1], ..., w[k]
        for k ∈ i+1:numsets
            S = iter.all_sets[k]
            w[k] = maximum_partition_value(iter, w, S)
        end
        maximum(w[i:numsets]) <= iter.ub && break  # stop without decrementing i if no carry-over needed
        i -= 1
    end
    i == 1+iter.n && return nothing
    # Construct the welfare function from state w
    w_fn = welfare_fn(iter, w)
    return w_fn, w
end


function Base.iterate(iter::WelfareFunctions)
    w = zeros(Int, 2^iter.n)
    w[end] = -1
    return iterate(iter::WelfareFunctions, w)
end


Base.IteratorSize(iter::WelfareFunctions) = Base.SizeUnknown()

function welfare_fn(iter, w)
    function w_fn(S::Vector{Int})
        @assert S ⊆ 1:iter.n  "Set must be contained in 1:$(iter.n)."
        length(S) ≤ 1 && return 0
        return w[iter.index[S]]
    end
    return w_fn
end



"""
Compute the maximum value w(U) + w(V) over all non-trivial partitions U, V of S.
"""
function maximum_partition_value(iter, w, S)
    result = 0
    for U ∈ powerset(S, 1, length(S)-1)
        for V ∈ powerset(S, 1, length(S)-1)
            if U ≠ V
                result = max(result, partition_value(iter, w, U, V))
            end
        end
    end
    return result
end

"""Compute the value w(U) + w(V) of sets U and V"""
partition_value(iter, w, U, V) = w[iter.index[U]] + w[iter.index[V]]



# Try all possible welfare functions with values w(S) ∈ [0, ub].
begin
    n = 4
    ub = 9
    dgts = 3
    @info "Starting exploration of all possible welfare functions for $(n) agents with values w(S) ≤ $(ub)."
    prog = ProgressUnknown(desc="Titles read:")
    for w ∈ WelfareFunctions(n, ub)
        vals = [ w(S) for S ∈ powerset(1:n) ]
        @debug "Considering the welfare function with values $(vals)."
        minvar_sol = round.(find_optimal_core_imputation(n, w, :min_variance), digits=dgts)
        leximin_sol = round.(find_optimal_core_imputation(n, w, :leximin), digits=dgts)
        leximax_sol = round.(find_optimal_core_imputation(n, w, :leximax), digits=dgts)
        @debug "minvar: $(minvar_sol)"
        @debug "leximin: $(leximin_sol)"
        @debug "leximax: $(leximax_sol)"
        if !(leximin_sol ≈ leximax_sol)
            println("The welfare function with values ($a, $b, $c, $d) has different leximin and leximax values:")
            println("Leximin is $(leximin_sol) and leximax is $(leximax_sol).")
        end
        if !(minvar_sol ≈ leximin_sol)
            println("The welfare function with values ($a, $b, $c, $d) has different minvar and leximin values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximin_sol).")
        end
        if !(minvar_sol ≈ leximax_sol)
            println("The welfare function with values ($a, $b, $c, $d) has different minvar and leximax values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximax_sol).")
        end
        next!(prog)
    end
    finish!(prog)
end