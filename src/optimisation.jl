using JuMP, Gurobi
using Combinatorics
using NetworkTrading
using NetworkTrading


function simple_test()
    model = Model(Gurobi.Optimizer)
    @variable(model, x)
    @constraint(model, x ≤ 1)
    @objective(model, Max, x)
    optimize!(model)
    return value(x)
end


"""
Create and solve model to find a minimum variance core imputation
of the cooperative market game defined by agents 1 to `n` and
welfare function `w`.

The convex optimisation program is:

min     sum(x_i^2 for i ∈ 1:n)
s.t.    sum(x_i for i ∈ 1:n) == w(1:n)
        sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ 1:n.

Note: assumes that w(C) is defined for each C ⊆ I!
"""
function min_variance(n, w)
    proper_subsets = collect(powerset(1:n, 1, n-1))
    model = Model(Gurobi.Optimizer)
    @variable(model, x[1:n])
    @constraint(model, eq, sum(x) == w(1:n))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    @objective(model, Min, sum(x[i]^2 for i ∈ 1:n))
    optimize!(model)
    return value.(x)
end

# ad-hoc test of min-variance function:
n = 3
function w(C::Vector{Int})
    length(C) ≤ 1 && return 0
    C == [1,2] && return 0
    C == [1,3] && return 6
    C == [2,3] && return 3
    C == [1,2,3] && return 8
    return nothing
end

# Create model instance
I = [1, 2, 3]  # Set of indices i
Ω = [(1,2), (2,3), (1,3)] # Set of elements ω
v1 = [(1,2) => 2, (1,3) => 4]
v2 = [{(1,2),(2,3)} => 10]
v3 = [(1,3) => 8]
valuation[1] = generate_valuation(1, Ω, v1)



function leximin(n, w)
    ε = 0.01  # TODO: compute correct value

    proper_subsets = collect(powerset(1:n, 1, n-1))
    model = Model(Gurobi.Optimizer)
    
    ## Define variables
    @variable(model, x[1:n] ≥ 0)
    @variable(model, y[1:n] ≥ 0)
    @variable(model, P[1:n, 1:n], Bin)

    ## Define constraints
    @constraint(model, eq, sum(x) == w(1:n))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    # Ensure that P is a permutation matrix
    @constraint(model, col[i ∈ 1:n], sum(P[:,i]) == 1)
    @constraint(model, row[i ∈ 1:n], sum(P[i,:]) == 1)
    # Define relation y == P x
    @constraint(model, P * x == y)  # change to .== if Gurobi can't handle ==
    # Ensure that y is sorted in ascending order
    @constraint(model, sorting[i ∈ 1:n-1], y[i] ≤ y[i+1])

    ## Define objective
    @objective(model, Min, sum(x[i]^2 for i ∈ 1:n)) # TODO!
    optimize!(model)
end