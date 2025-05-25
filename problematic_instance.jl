using Revise
using NetworkTrading
using Combinatorics
using ProgressMeter
using JuMP
import MultiObjectiveAlgorithms as MOA
using Gurobi


function create_three_agent_welfare_fn(w::NTuple{8,Int})
    function welfare(C::Vector{Int})
        @assert C ⊆ 1:3 "C must be a subset of agents 1 to 3."
        length(C) <= 1 && return 0
        w12, w13, w23, w123 = w[5:8]
        C == [1, 2] && return w12
        C == [1, 3] && return w13
        C == [2, 3] && return w23
        return w123
    end
    return welfare
end

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
n = 4
w = (0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 1, 2, 2, 2, 3)

w_fn = create_four_agent_welfare_fn(w)

minvar_sol = find_optimal_core_imputation(n, w_fn, :min_variance)
leximin_sol = find_optimal_core_imputation(n, w_fn, :leximin)
leximax_sol = find_optimal_core_imputation(n, w_fn, :leximax)

model, x, y, P = sorted_core_model(n, w_fn)
# Set the multi-objective optimizer
set_optimizer(model, () -> MOA.Optimizer(Gurobi.Optimizer))
set_attribute(model, MOA.Algorithm(), MOA.Lexicographic())
set_attribute(model, MOA.LexicographicAllPermutations(), false)
for i ∈ eachindex(y)
    set_attribute(model, MOA.ObjectiveRelativeTolerance(i), 10e-6)
end
# Set the objective to leximax
@objective(model, Min, reverse(y))
optimize!(model)
is_solved_and_feasible(model)
value.(x)
termination_status(model)