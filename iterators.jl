using Combinatorics

# ### An iterator to generate all welfare functions w for sets S ⊆ 1:n with integer entries w(S) \in [0, ub].
# struct SubstitutesValuations
#     n::Int  # ground set 1 to n
#     all_sets::Vector{Vector{Int}}
#     index::Dict{Vector{Int}, Int}  # maps each set to index in all_sets
#     ub::Int
# end


# function SubstitutesValuations(n, ub)
#     allsets = collect(powerset(1:n))
#     numsets = 2^n
#     index = Dict(allsets[i] => i for i ∈ 1:numsets)
#     return SubstitutesValuations(n, allsets, index, ub)
# end


# function Base.iterate(iter::SubstitutesValuations, state::Vector{Int})
#     numsets = 2^iter.n
#     # Update the state w
#     state = copy(state)
#     i = numsets
#     while i ≥ 1
#         # Reduce i until state[i] is strictly less than ub
#         while state[i] ≥ iter.ub; i -= 1; end
#         # Check whether iterator has reached the end, return nothing
#         i == 1 && return nothing
#         # Otherwise, increment state[i]
#         state[i] += 1
#         # Now update the entries of all entries state[i+1], ..., state[n]
#         # according to the M^♮-concavity property, breaking off early
#         # if any of the entries exceeds ub.
#         ub_exceeded = false
#         for k ∈ i+1:numsets
#             S = iter.all_sets[k]
#             lb = maximum_partition_value(iter, w, S)
#             if lb > iter.ub
#                 exceeded_ub = true
#                 break
#             else
#                 w[k] = lb
#             end
#         end
#         if exceeded_ub
#             i -= 1
#         else
#             w[i] += 1
#             continue
#         end
#     end
#     # Construct the welfare function from state w
#     w_fn = welfare_fn(iter, w)
#     return w_fn, w
# end


# function Base.iterate(iter::SubstitutesValuations)
#     w = zeros(Int, 2^iter.n)
#     w[end] = -1
#     return iterate(iter::SubstitutesValuations, w)
# end


# Base.IteratorSize(iter::SubstitutesValuations) = Base.SizeUnknown()


# function welfare_fn(iter, w)
#     function w_fn(S::Vector{Int})
#         @assert S ⊆ 1:iter.n  "Set must be contained in 1:$(iter.n)."
#         length(S) ≤ 1 && return 0
#         return w[iter.index[S]]
#     end
#     return w_fn
# end



# """
# Compute the maximum value w(U) + w(V) over all non-trivial partitions U, V of S.
# """
# function maximum_partition_value(iter, w, S)
#     result = 0
#     for U ∈ powerset(S, 1, length(S)-1)
#         for V ∈ powerset(S, 1, length(S)-1)
#             if U ≠ V
#                 result = max(result, partition_value(iter, w, U, V))
#             end
#         end
#     end
#     return result
# end

# """Compute the value w(U) + w(V) of sets U and V"""
# partition_value(iter, w, U, V) = w[iter.index[U]] + w[iter.index[V]]




struct AltPowerset
    n::Int
end


function Base.iterate(iter::AltPowerset, state::NTuple{N, Bool}) where N
    k = iter.n
    # Find largest index k for which state[k] is false
    while k ≥ 1 && state[k]; k -= 1; end
    # If no such index exists, we're done
    k == 0 && return nothing
    # Otherwise, create the next state
    function f(i) 
        i < k && return state[i]
        i == k && return true
        i > k && return false
    end
    new_state = ntuple(f, iter.n)
    new_S = Set(iter.n-i+1 for i ∈ 1:iter.n if new_state[i])
    return new_S, new_state
end


Base.IteratorSize(iter::AltPowerset) = 2^iter.n

function Base.iterate(iter::AltPowerset)
    state = ntuple(_ -> false, iter.n)
    return Set(Int[]), state
end

iter = AltPowerset(2)
iterate(iter)


next = iterate(iter)
while !isnothing(next)
    
end