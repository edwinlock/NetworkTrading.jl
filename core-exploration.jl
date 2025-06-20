using Revise
using NetworkTrading
using Combinatorics
using ProgressMeter
using JuMP
using DataFrames
using BenchmarkTools

"""
Lots of code to explore leximin and leximax core outcome for arbitrary super-additive characteristic functions.
"""

function generate_all_three_agent_values(; ub=100)
    values = NTuple{8, Int}[]
    for (w12, w13, w23) ∈ Iterators.product(0:ub, 0:ub, 0:ub)
        for w123 ∈ max(w12, w13, w23) : ub
            # println("$w12, $w13, $w23, $w123")
            push!(values, (0, 0, 0, 0, w12, w13, w23, w123))
        end
    end
    return values
end


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



function generate_all_four_agent_values(; ub=5)
    values = NTuple{15, Int}[]
    for (w12, w13, w14, w23, w24, w34) ∈ Iterators.product(0:ub, 0:ub, 0:ub, 0:ub, 0:ub, 0:ub)
        w123_min = max(w12, w13, w23)
        w124_min = max(w12, w14, w24)
        w134_min = max(w13, w14, w34)
        w234_min = max(w23, w24, w34)
        for (w123, w124, w134, w234) ∈ Iterators.product(w123_min:ub, w124_min:ub, w134_min:ub, w234_min:ub)
            w1234_min = max(w123, w124, w134, w234, w12+w34, w13+w24, w14+w23)
            for w1234 ∈ w1234_min:ub
                push!(values, (0, 0, 0, 0, w12, w13, w13, w23, w24, w34, w123, w124, w134, w234, w1234))
            end
        end
    end
    return values
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


# Try all possible welfare functions for n ∈ {3, 4} agents with values w(S) \leq ub.
function sweep_agent_functions(n, ub; atol=10e-4)
    if n == 3
        all_values = generate_all_three_agent_values(ub=ub)
        create_agent_welfare_fn = create_three_agent_welfare_fn
    elseif n == 4
        all_values = generate_all_four_agent_values(ub=ub)
        create_agent_welfare_fn = create_four_agent_welfare_fn
    else
        error("This function is only implemented for n ∈ {3, 4}.")
    end
    @info "Starting exploration of all possible welfare functions for $n agents with values w(S) ≤ $ub."
    infeasible_instances = 0
    feasible_instances = 0
    @showprogress for w ∈ all_values
        @debug "Considering the welfare function values $w."
        w_fn = create_agent_welfare_fn(w)
        minvar_sol = find_optimal_core_imputation(n, w_fn, :min_variance)
        # Skip loop iteration if core is empty
        if isnothing(minvar_sol)
            infeasible_instances += 1
            continue
        end
        feasible_instances += 1
        leximin_sol = find_optimal_core_imputation(n, w_fn, :leximin)
        leximax_sol = find_optimal_core_imputation(n, w_fn, :leximax)
        mean_sol = (leximin_sol + leximax_sol) / 2
        @debug "minvar: $(minvar_sol)"
        @debug "leximin: $(leximin_sol)"
        @debug "leximax: $(leximax_sol)"
        # if any(abs.(leximin_sol - leximax_sol) .≥ atol)
        #     println("\nThe welfare function with values $w has different leximin and leximax values.")
        #     println("Leximin: $(leximin_sol)")
        #     println("Leximax: $(leximax_sol)")
        #     println("   Mean: $(mean_sol)")
        #     println(" Minvar: $(round.(minvar_sol, digits=3))")
        # end
        if any(abs.(mean_sol - minvar_sol) .≥ atol)
            println("\nThe mean and minvar solutions are not the same.")
            println("Leximin: $(leximin_sol)")
            println("Leximax: $(leximax_sol)")
            println("   Mean: $(mean_sol)")
            println(" Minvar: $(round.(minvar_sol, digits=3))")
        end
        # if any(abs.(minvar_sol - leximin_sol) .≥ atol)
        #     println("The welfare function with values $w has different minvar and leximin values:")
        #     println("Minvar is $(minvar_sol) and leximax is $(leximin_sol).")
        # end
        # if any(abs.(minvar_sol - leximax_sol) .≥ atol)
        #     println("The welfare function with values $w has different minvar and leximax values:")
        #     println("Minvar is $(minvar_sol) and leximax is $(leximax_sol).")
        # end
    end
    @info "Finished exploring. Encountered $feasible_instances feasible instances and $infeasible_instances infeasible instances."
end

sweep_agent_functions(3,10)
sweep_agent_functions(4,4)


# function create_valuation_fn(values::Vector{Int})
#     n = round(Int, log(2, length(values)))  # number of goods
#     d = Dict(Set(Φ) => i for (i, Φ) ∈ enumerate(powerset(1:n)))
#     function valuation(Φ::Set{Int})
#         @assert Φ ⊆ 1:n "Φ must be a subset of agents 1 to n."
#         return values[d[Φ]]
#     end
#     return valuation
# end
