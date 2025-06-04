using Revise
using NetworkTrading
using ProgressMeter
using Combinatorics

function create_valuation_fn(values)
    n = round(Int, log(2, length(values)))  # number of goods
    d = Dict(Set(Φ) => i for (i, Φ) ∈ enumerate(powerset(1:n)))
    function valuation(Φ::Set{Int})
        @assert Φ ⊆ 1:n "Φ must be a subset of agents 1 to n."
        return values[d[Φ]]
    end
    return valuation
end

n = 2
ub = 10

iter = SubmodularFunctions(n, ub)
df = listall(iter)

substitutes = Vector{Int}[]
A = powerset(1:n)
@showprogress for row ∈ eachrow(df)
    values = collect(row)
    valuation = create_valuation_fn(values)
    if issubstitutes(valuation, A)
        push!(substitutes, values)
    end
end
length(substitutes)