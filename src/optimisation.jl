using JuMP, Gurobi
using Combinatorics
using Revise

function simple_test()
    model = Model(Gurobi.Optimizer)
    @variable(model, x)
    @constraint(model, x ≤ 1)
    @objective(model, Max, x)
    optimize!(model)
    return value(x)
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
    proper_subsets = collect(powerset(1:n, 1, n-1))
    model = Model(Gurobi.Optimizer)
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
function leximin_model(n, w)
    # First we define a constant for the objective function, i.e., M = 1 / ε.
    # This constant should probably depend on n and the magnitude of the values in w.
    # For now, we set it to a fairly number. TODO: improve.
    M = 500

    grand_coalition = collect(1:n)
    proper_subsets = collect(powerset(1:n, 1, n-1))
    model = Model(Gurobi.Optimizer)
    
    ## Define variables
    @variable(model, x[1:n] ≥ 0)
    @variable(model, y[1:n] ≥ 0)
    @variable(model, P[1:n, 1:n], Bin)

    ## Define constraints
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
    # For now, we set it to a fairly number. TODO: improve.
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
    # Solve model and return result
    optimize!(model)
    @info "Optimal core imputation: $(value.(x))"
    return value.(x)
end



########### ad-hoc test of min-variance function:
n = 3
function w(C::Vector{Int})
    length(C) ≤ 1 && return 0
    C == [1,2] && return 0
    C == [1,3] && return 6
    C == [2,3] && return 3
    C == [1,2,3] && return 8
    return nothing
end

minvar_sol = find_optimal_core_imputation(n, w, :min_variance)
leximin_sol = find_optimal_core_imputation(n, w, :leximin)
leximax_sol = find_optimal_core_imputation(n, w, :leximax)