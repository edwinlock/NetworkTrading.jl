struct Powerset
    n::Int
end

Base.length(iter::Powerset) = 2^iter.n
Base.eltype(iter::Powerset) = Set{Int}

function Base.iterate(iter::Powerset, state::Int=0)
    # Terminate if we're done
    state ≥ 2^iter.n && return nothing
    # Otherwise, create set
    S = Set{Int}()
    for i in 1:iter.n
        if state & (1 << (i-1)) != 0
            push!(S, i)
        end
    end
    return S, state + 1
end


# # # using Combinatorics

# """
# An iterator to generate all submodular functions f for sets S ⊆ 1:n with integer
# entries f(S) ∈ [0, ub] and f(∅) = 0.
# """
# struct SubmodularFunctions
#     n::Int  # ground set 1 to n
#     allsets::Vector{Vector{Int}}
#     index::Dict{Vector{Int}, Int}  # maps each set to index in allsets
#     ub::Int
# end


# function SubmodularFunctions(n, ub)
#     allsets = collect(powerset(1:n))
#     numsets = 2^n
#     index = Dict(allsets[i] => i for i ∈ 1:numsets)
#     return SubmodularFunctions(n, allsets, index, ub)
# end


# function Base.iterate(iter::SubmodularFunctions, state::Vector{Int})
#     numsets = 2^iter.n
#     i = numsets
#     while i ≥ 1
#         # Reduce i until state[i] is strictly less than ub
#         while (i ≥ 1 && state[i] ≥ iter.ub); i -= 1; end
#         # Check whether iterator has reached the end, return nothing
#         i == 0 && return nothing
#         # Otherwise, increment state[i]
#         state[i] += 1
#         # Now update the entries of all entries state[i+1], ..., state[n]
#         # according to the substitutes property, breaking off early
#         # if any of the entries exceeds ub.
#         ub_exceeded = false
#         for k ∈ i+1:numsets
#             lb = compute_lb(iter, state, k)
#             if lb > iter.ub
#                 ub_exceeded = true
#                 break
#             else
#                 state[k] = lb
#             end
#         end
#         if ub_exceeded
#             i -= 1
#         else
#             break
#         end
#     end
#     return copy(state), state
# end


# """
# Compute the maximum value f(Φ - ω) + f(Φ - χ) - f(Φ - ω - χ) for the set Φ given by the
# setindex over all possible ω ≠ χ ∈ Φ.
# """
# function compute_lb(iter, state, setindex::Int)
#     Φ = iter.allsets[setindex]
#     lb = 0
#     for (ω, χ) ∈ combinations(Φ, 2)
#         # Compute f(Φ - ω) + f(Φ - χ) - f(Φ - ω - χ) and update lb if value exceeds lb.
#         i = iter.index[setdiff(Φ, ω)]
#         j = iter.index[setdiff(Φ, χ)]
#         k = iter.index[setdiff(Φ, ω, χ)]
#         res = state[i] + state[j] - state[k]
#         lb = res > lb ? res : lb
#     end
#     return lb
# end

# function Base.iterate(iter::SubmodularFunctions)
#     state = zeros(Int, 2^iter.n)
#     state[end] = -1
#     return iterate(iter::SubmodularFunctions, state)
# end


# Base.IteratorSize(iter::SubmodularFunctions) = Base.SizeUnknown()


# function vec2fn(iter, vec)
#     function fn(S::Vector{Int})
#         @assert S ⊆ 1:iter.n  "Set must be contained in 1:$(iter.n)."
#         length(S) ≤ 1 && return 0
#         return vec[iter.index[S]]
#     end
#     return w_fn
# end