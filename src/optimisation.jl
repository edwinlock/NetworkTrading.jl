using JuMP, Gurobi
using Combinatorics


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
of the cooperative market game defined by agents `I` and welfare
function `w`.

The convex optimisation program is:

min     sum(x_i^2 for i ∈ I)
s.t.    sum(x_i for i ∈ I) == w(I)
        sum(x_i for i ∈ C) ≥ w(C), for every C ⊆ I.

Note: assumes that w(C) is defined for each C ⊆ I!
"""
function min_variance(I, w)
    proper_subsets = collect(powerset(I, 1, length(I)-1))
    model = Model(Gurobi.Optimizer)
    @variable(model, x[I])
    @constraint(model, eq, sum(x) == w(I))
    @constraint(model, ineq[C ∈ proper_subsets], sum(x[C]) ≥ w(C))
    @objective(model, Min, sum(x[i]^2 for i ∈ I))
    optimize!(model)
    return value.(x)
end


# ad-hoc test of min-variance function:
I = [1,2,3]
function w(C::Vector{Int})
    length(C) ≤ 1 && return 0
    C == [1,2] && return 0
    C == [1,3] && return 6
    C == [2,3] && return 3
    C == [1,2,3] && return 8
    return nothing
end

min_variance(I, w)