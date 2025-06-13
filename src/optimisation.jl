using Revise
using JuMP, Gurobi
using Combinatorics
import MultiObjectiveAlgorithms as MOA

const GRB_ENV = Ref{Gurobi.Env}()
function __init__()
    GRB_ENV[] = Gurobi.Env()
    return
end
Optimizer = () -> Gurobi.Optimizer(GRB_ENV[])


"""
    core_model(n::Int, w::Function)

Create model that represents the core. The core is defined by constraints:

<no objective>
    sum(x_i for i ∈ 1:n) == w(1:n)
    sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ 1:n.

Note: assumes that w(C) is defined for each C ⊆ 1:n! The model lacks an objective,
because it only defines the feasible region!
"""
function core_model(n::Int, w::Function)
    GC = collect(1:n)
    proper_subsets = collect.(powerset(1:n, 1, n-1))
    model = Model(Optimizer)
    @variable(model, x[1:n])
    @constraint(model, eq, sum(x[GC]) == w(GC))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    return model, x
end


"""
    minvar_model(n::Int, w::Function)

Create model to find a minimum variance core imputation
of the cooperative market game defined by agents 1 to `n` and
welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:
min     sum(x_i^2 for i ∈ 1:n)
s.t.    x ∈ core.

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function minvar_model(n::Int, w)
    model, x = core_model(n, w)    
    @objective(model, Min, sum(x[i]^2 for i ∈ 1:n))
    set_optimizer(model, Optimizer)
    return model, x
end


"""
    sorted_core_model(n::Int, w)

TBW
"""
function sorted_core_model(n::Int, w)
    model, x = core_model(n, w)

    # Define additional variables
    @variable(model, y[1:n])
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
    leximin_model(n::Int, w::Function)

Create model to find a leximin core imputation of the cooperative
market game defined by agents 1 to `n` and welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:

lexicographically largest y
s.t.    x, y ∈ sorted_core, where y is x sorted in ascending order

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function leximin_model(n::Int, w)
    # Construct model
    model, x, y, P = sorted_core_model(n, w)
    
    # Set the multi-objective optimizer
    set_optimizer(model, () -> MOA.Optimizer(Optimizer))
    set_attribute(model, MOA.Algorithm(), MOA.Lexicographic())
    set_attribute(model, MOA.LexicographicAllPermutations(), false)
    for i ∈ eachindex(y)
        set_attribute(model, MOA.ObjectiveRelativeTolerance(i), 10e-6)
    end
    # Define objective
    @objective(model, Max, y)
    
    return model, x, y, P
end


"""
    leximax_model(n::Int, w::Function)

Create model to find a leximax core imputation of the cooperative
market game defined by agents 1 to `n` and welfare function `w`.

Returns model and core imputation variables x.

The convex optimisation program is:

reverse lexicographically smallest y
s.t.    x, y ∈ sorted_core, where y is x sorted in ascending order

Note: assumes that w(C) is defined for each C ⊆ 1:n!
"""
function leximax_model(n::Int, w)
    # Construct model
    model, x, y, P = sorted_core_model(n, w)

    # Set the multi-objective optimizer
    set_optimizer(model, () -> MOA.Optimizer(Optimizer))
    set_attribute(model, MOA.Algorithm(), MOA.Lexicographic())
    set_attribute(model, MOA.LexicographicAllPermutations(), false)
    for i ∈ eachindex(y)
        set_attribute(model, MOA.ObjectiveRelativeTolerance(i), 10e-6)
    end
    # Set the objective to leximax
    @objective(model, Min, reverse(y))

    return model, x, y, P
end


"""
    find_optimal_core_imputation(n::Int, w::Function, objective::Symbol)

TBW
"""
function find_optimal_core_imputation(n::Int, w::Function, objective::Symbol)
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
    is_solved_and_feasible(model) && return value.(x)
    return nothing
end