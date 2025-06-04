using Revise
using Combinatorics
using BenchmarkTools
using NetworkTrading

# n = 16
# @btime collect(powerset(1:n))
# @btime collect(Powerset(n))

# @profview(collect(Powerset(n)))

# @profview(collect(powerset(1:n)))



# iter = Powerset(3)
# iterate(iter)

# next = iterate(iter)
# while !isnothing(next)
#     set, state = next
#     println(set)
#     next = iterate(iter, state)
# end



function test_original(n)
    count = 0
    for subset in powerset(1:n)
        count += 1
    end
    return count
end

function test_powerset(n)
    count = 0
    for subset in Powerset(n)
        count += 1
    end
    return count
end


@btime test_original(15)
@btime test_powerset(15)