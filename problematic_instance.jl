using Revise
using NetworkTrading
using Combinatorics
using ProgressMeter
using JuMP


function create_four_agent_welfare_fn(w)
    w12, w13, w14, w23, w24, w34, w123, w124, w134, w234, w1234 = w[5:end]
    function welfare(C::Vector{Int})
        @assert C ⊆ 1:4 "C must be a subset of agents 1 to 4."
        length(C) <= 1 && return 0
        C == [1, 2] && return w12
        C == [1, 3] && return w13
        C == [1, 4] && return w14
        C == [2, 3] && return w23
        C == [2, 4] && return w24
        C == [3, 4] && return w34
        C == [1, 2, 3] && return w123
        C == [1, 2, 4] && return w124
        C == [1, 3, 4] && return w134
        C == [2, 3, 4] && return w234
        C == [1, 2, 3, 4] && return w1234
    end
    return welfare
end


### For testing a single instance of w vector

w = (0, 0, 0, 0, 1, 2, 2, 0, 0, 0, 2, 1, 2, 1, 3)
# Leximin is [1.5, 0.5, 0.5, 0.5] and leximax is [1.0, 0.0, 1.0, 1.0].

w = (0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 2, 4, 4, 5)
w_fn = create_four_agent_welfare_fn(w)

leximin_sol = find_optimal_core_imputation(4, w_fn, :leximin)
leximax_sol = find_optimal_core_imputation(4, w_fn, :leximax)

# Check feasibility of the leximax solution for the sorted core model
sortedmodel, x, y, P  = sorted_core_model(4, w_fn)
maxpoint = Dict(
    x[1] => 1.,
    x[2] => 1.,
    x[3] => 1.5,
    x[4] => 1.5,
    y[1] => 1.0,
    y[2] => 1.0,
    y[3] => 1.5,
    y[4] => 1.5,
    P[1,1] => 1.,
    P[1,2] => 0.,
    P[1,3] => 0.,
    P[1,4] => 0.,
    P[2,1] => 0.,
    P[2,2] => 1.,
    P[2,3] => 0.,
    P[2,4] => 0.,
    P[3,1] => 0.,
    P[3,2] => 0.,
    P[3,3] => 1.,
    P[3,4] => 0.,
    P[4,1] => 0.,
    P[4,2] => 0.,
    P[4,3] => 0.,
    P[4,4] => 1.,
)
primal_feasibility_report(sortedmodel, maxpoint)

# Check feasibility and optimality in leximin model:
minmodel, x, y, P = leximin_model(4, w_fn)
minpoint = Dict(
    x[1] => 1.,
    x[2] => 1.,
    x[3] => 2.,
    x[4] => 1.,
    y[1] => 1.0,
    y[2] => 1.0,
    y[3] => 1.0,
    y[4] => 2.0,
    P[1,1] => 1.,
    P[1,2] => 0.,
    P[1,3] => 0.,
    P[1,4] => 0.,
    P[2,1] => 0.,
    P[2,2] => 1.,
    P[2,3] => 0.,
    P[2,4] => 0.,
    P[3,1] => 0.,
    P[3,2] => 0.,
    P[3,3] => 0.,
    P[3,4] => 1.,
    P[4,1] => 0.,
    P[4,2] => 0.,
    P[4,3] => 1.,
    P[4,4] => 0.,
)
maxpoint = Dict(
    x[1] => 1.,
    x[2] => 1.,
    x[3] => 1.5,
    x[4] => 1.5,
    y[1] => 1.0,
    y[2] => 1.0,
    y[3] => 1.5,
    y[4] => 1.5,
    P[1,1] => 1.,
    P[1,2] => 0.,
    P[1,3] => 0.,
    P[1,4] => 0.,
    P[2,1] => 0.,
    P[2,2] => 1.,
    P[2,3] => 0.,
    P[2,4] => 0.,
    P[3,1] => 0.,
    P[3,2] => 0.,
    P[3,3] => 1.,
    P[3,4] => 0.,
    P[4,1] => 0.,
    P[4,2] => 0.,
    P[4,3] => 0.,
    P[4,4] => 1.,
)
primal_feasibility_report(minmodel, minpoint)
primal_feasibility_report(minmodel, maxpoint)
f = objective_function(minmodel)
a = value(z -> minpoint[z], f)
b = value(z -> maxpoint[z], f)

