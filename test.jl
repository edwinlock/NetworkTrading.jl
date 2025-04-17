using JuMP
using Gurobi
using Random
using Statistics
using Test

function example_rosenbrock()
    model = Model(Gurobi.Optimizer)
    set_silent(model)
    @variable(model, x)
    @variable(model, y)
    @objective(model, Min, (1 - x)^2 + 100 * (y - x^2)^2)
    optimize!(model)
    assert_is_solved_and_feasible(model)
    Test.@test objective_value(model) ≈ 0.0 atol = 1e-10
    Test.@test value(x) ≈ 1.0
    Test.@test value(y) ≈ 1.0
    return "hallo"
end

example_rosenbrock()