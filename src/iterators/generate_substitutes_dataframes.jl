using Revise
using NetworkTrading
using ProgressMeter
using Combinatorics
using CSV
using DataFrames


function create_valuation_fn(values)
    n = round(Int, log(2, length(values)))  # number of goods
    d = Dict(Set(Φ) => i for (i, Φ) ∈ enumerate(powerset(1:n)))
    function valuation(Φ::Set{Int})
        @assert Φ ⊆ 1:n "Φ must be a subset of agents 1 to n."
        return values[d[Φ]]
    end
    return valuation
end


function filter_substitutes(df)
    n = round(Int, log(2, ncol(df)))
    A = powerset(1:n)
    new_df = similar(df, 0)
    @showprogress for row in eachrow(df)
        values = collect(row)
        valuation = create_valuation_fn(values)
        issubstitutes(valuation, A) && push!(new_df, values)
    end
    return new_df
end


iter = SubmodularFunctions(1, 100)
submodular_df = listall(iter)
substitutes_df = filter_substitutes(submodular_df)
CSV.write("substitutes-2-100.csv", substitutes_df)

iter = SubmodularFunctions(2, 100)
submodular_df = listall(iter)
substitutes_df = filter_substitutes(submodular_df)
CSV.write("substitutes-2-100.csv", substitutes_df)

iter = SubmodularFunctions(3, 15)
submodular_df = listall(iter)
substitutes_df = filter_substitutes(submodular_df)
CSV.write("substitutes-3-15.csv", substitutes_df)


