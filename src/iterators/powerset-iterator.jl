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