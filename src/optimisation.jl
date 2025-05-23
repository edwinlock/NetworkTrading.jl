using Revise
using JuMP, Gurobi
using Combinatorics

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
Create model that represents the core. The core is defined by constraints:
<no objective>
    sum(x_i for i ∈ 1:n) == w(1:n)
    sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ 1:n.

Note: assumes that w(C) is defined for each C ⊆ 1:n! The model lacks an objective,
because it only defines the feasible region!
"""
function core_model(n::Int, w)
    GC = collect(1:n)
    proper_subsets = collect.(powerset(1:n, 1, n-1))
    model = Model(() -> Gurobi.Optimizer(env))
    @variable(model, x[1:n])
    @constraint(model, eq, sum(x[GC]) == w(GC))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    return model, x
end


"""
Create model to find a minimum variance core imputation
of the cooperative market game defined by agents 1 to `n` and
welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:
min     sum(x_i^2 for i ∈ 1:n)
s.t.    x ∈ core.

Note: assumes that w(C) is defined for each C ⊆ 1:n!
The parameter M is not used. It's only there to provide a consistent
interface for optimisation models.
"""
function minvar_model(n::Int, w; M=1)
    model, x = core_model(n, w)    
    @objective(model, Min, sum(x[i]^2 for i ∈ 1:n))
    return model, x
end


function sorted_core_model(n::Int, w)
    model, x = core_model(n, w)

    # Define additional variables
    @variable(model, y[1:n] ≥ 0)
    @variable(model, P[1:n, 1:n], Bin)

    ## Define constraints
    # Ensure that P is a permutation matrix
    @constraint(model, col[i ∈ 1:n], sum(P[:,i]) == 1)
    @constraint(model, row[i ∈ 1:n], sum(P[i,:]) == 1)
    # Define relation y == P x
    @constraint(model, P * x .== y)
    # Ensure that y is sorted in ascending order
    @constraint(model, sorting[i ∈ 1:n-1], y[i] ≤ y[i+1])
    return model, x, y, P
end


"""
Create model to find a leximin core imputation of the cooperative
market game defined by agents 1 to `n` and welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:

lexicographically largest y
s.t.    x, y ∈ sorted_core, where y is x sorted in ascending order

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function leximin_model(n::Int, w; M=2)
    # Construct model
    model, x, y, P = sorted_core_model(n, w)
    
    ## Define objective
    @objective(model, Max, sum(M^(n-i) * y[i] for i ∈ 1:n))
    
    return model, x, y, P
end


"""
Create model to find a leximax core imputation of the cooperative
market game defined by agents 1 to `n` and welfare function `w`.

The constant M should probably depend on n and the magnitude of the values in w.
For now, we set it to M=5 by default.

Returns model and core imputation variables x.

The convex optimisation program is:

reverse lexicographically smallest y
s.t.    x, y ∈ sorted_core, where y is x sorted in ascending order

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function leximax_model(n::Int, w; M=2)
    # Construct model
    model, x, y, P = sorted_core_model(n, w)

    # Change the objective to leximax
    @objective(model, Min, sum(M^i * y[i] for i ∈ 1:n))
    return model, x, y, P
end


function find_optimal_core_imputation(n::Int, w, objective::Symbol; M=2)
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
    model, x = model_fn(n, w; M=M)
    set_silent(model)
    set_optimizer_attribute(model, "OutputFlag", 0)
    # Solve model and return result
    optimize!(model)
    # @info "$(objective) core imputation: $(value.(x))"
    is_solved_and_feasible(model) && return value.(x)
    return nothing
end