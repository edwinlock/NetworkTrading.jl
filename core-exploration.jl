using Revise
using NetworkTrading
using Combinatorics
using ProgressMeter
using JuMP

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


# Try all possible welfare functions for 3 agents with values w(S) \leq ub.
function sweep_three_agent_functions(ub; atol=10e-4)
    n=3
    @info "Starting exploration of all possible welfare functions for 3 agents with values w(S) ≤ $ub."
    all_values = generate_all_three_agent_values(ub=ub)
    infeasible_instances = 0
    feasible_instances = 0 
    @showprogress for w ∈ all_values
        @debug "Considering the welfare function values $w."
        w_fn = create_three_agent_welfare_fn(w)
        minvar_sol = find_optimal_core_imputation(n, w_fn, :min_variance)
        # Skip loop iteration if core is empty
        if isnothing(minvar_sol)
            infeasible_instances += 1
            continue
        end
        feasible_instances += 1
        leximin_sol = find_optimal_core_imputation(n, w_fn, :leximin)
        leximax_sol = find_optimal_core_imputation(n, w_fn, :leximax)
        @debug "minvar: $(minvar_sol)"
        @debug "leximin: $(leximin_sol)"
        @debug "leximax: $(leximax_sol)"
        if any(abs.(leximin_sol - leximax_sol) .≥ atol)
            println("The welfare function with values $w has different leximin and leximax values:")
            println("Leximin is $(leximin_sol) and leximax is $(leximax_sol).")
        end
        if any(abs.(minvar_sol - leximin_sol) .≥ atol)
            println("The welfare function with values $w has different minvar and leximin values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximin_sol).")
        end
        if any(abs.(minvar_sol - leximax_sol) .≥ atol)
            println("The welfare function with values $w has different minvar and leximax values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximax_sol).")
        end
    end
    @info "Finished exploring. Encountered $feasible_instances feasible instances and $infeasible_instances infeasible instances."
end


# # Try all possible welfare functions for 4 agents with values w(S) \leq ub.
function sweep_four_agent_functions(ub; atol=10e-4)
    n=4
    @info "Starting exploration of all possible welfare functions for 4 agents with values w(S) ≤ $ub."
    all_values = generate_all_four_agent_values(ub=ub)
    infeasible_instances = 0
    feasible_instances = 0 
    @showprogress for w ∈ all_values
        @debug "Considering the welfare function values $w."
        w_fn = create_four_agent_welfare_fn(w)
        minvar_sol = find_optimal_core_imputation(n, w_fn, :min_variance)
        # Skip loop iteration if core is empty
        if isnothing(minvar_sol)
            infeasible_instances += 1
            continue
        end
        feasible_instances += 1
        leximin_sol = find_optimal_core_imputation(n, w_fn, :leximin)
        leximax_sol = find_optimal_core_imputation(n, w_fn, :leximax)
        @debug "minvar: $(minvar_sol)"
        @debug "leximin: $(leximin_sol)"
        @debug "leximax: $(leximax_sol)"
        if any(abs.(leximin_sol - leximax_sol) .≥ atol)
            println("The welfare function with values $w has different leximin and leximax values:")
            println("Leximin is $(leximin_sol) and leximax is $(leximax_sol).")
        end
        if any(abs.(minvar_sol - leximin_sol) .≥ atol)
            println("The welfare function with values $w has different minvar and leximin values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximin_sol).")
        end
        if any(abs.(minvar_sol - leximax_sol) .≥ atol)
            println("The welfare function with values $w has different minvar and leximax values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximax_sol).")
        end
    end
    @info "Finished exploring. Encountered $feasible_instances feasible instances and $infeasible_instances infeasible instances."
end




### For testing a single instance of w vector
# begin
#     w = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 5)
#     w_fn = create_four_agent_welfare_fn(w)
#     # So w_fn([1,2,4]) = 5, w_fn([1,3,4]) = 5, w_fn([1,2,3,4]) = 5
#     leximin_sol = find_optimal_core_imputation(4, w_fn, :leximin)
#     leximax_sol = find_optimal_core_imputation(4, w_fn, :leximax)
#     minmodel, minx, miny = leximin_model(4, w_fn)
#     optimize!(minmodel)
#     value.(miny)
#     value.(minx)
#     maxmodel, maxx, maxy = leximax_model(4, w_fn)
#     optimize!(maxmodel)
#     value.(maxy)
#     value.(maxx)
# end

sweep_three_agent_functions(5)
sweep_four_agent_functions(5)

# ------------------------------ #
# DON'T USE THE CODE BELOW YET   #

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
    i = numsets
    while i ≥ 1+iter.n+1
        # Find largest index j ∈ 1:i-1 for which w[j] is strictly less than ub
        while w[i] ≥ iter.ub
            i -= 1
        end
        i == 1+iter.n && return nothing  # iterator has reached the end
        exceeded_ub = false
        for k ∈ i+1:numsets
            S = iter.all_sets[k]
            lb = maximum_partition_value(iter, w, S)
            if lb > iter.ub
                exceeded_ub = true
                break
            else
                w[k] = lb
            end
        end
        if exceeded_ub
            i -= 1
        else
            w[i] += 1
            continue
        end
    end
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

function sweep_agent_functions(n, ub; atol=10e-4)
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
            println("The welfare function with values $(vals) has different leximin and leximax values:")
            println("Leximin is $(leximin_sol) and leximax is $(leximax_sol).")
        end
        if !(minvar_sol ≈ leximin_sol)
            println("The welfare function with values $(vals) has different minvar and leximin values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximin_sol).")
        end
        if !(minvar_sol ≈ leximax_sol)
            println("The welfare function with values $(vals) has different minvar and leximax values:")
            println("Leximin is $(minvar_sol) and leximax is $(leximax_sol).")
        end
        next!(prog)
    end
    finish!(prog)
end