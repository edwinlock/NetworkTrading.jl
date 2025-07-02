# Find all integral core allocations for the 4-player cooperative game

function core_allocations()
    valid_allocations = Vector{Vector{Float64}}()

    for x1 in 0:0.2:9
        for x2 in 0:0.2:9
            for x3 in 0:0.2:9
                for x4 in 0:0.2:9
                    if x1 + x2 + x3 + x4 != 9
                        continue
                    end

                    if x1 + x2 >= 5 &&
                       x1 + x3 >= 4 &&
                       x1 + x4 >= 3 &&
                       x2 + x3 >= 4 &&
                       x2 + x4 >= 3 &&
                       x3 + x4 >= 2 &&
                       x1 + x2 + x3 >= 8 &&
                       x1 + x2 + x4 >= 7 &&
                       x1 + x3 + x4 >= 6 &&
                       x2 + x3 + x4 >= 5

                        push!(valid_allocations, sort([x1, x2, x3, x4]))
                    end
                end
            end
        end
    end

    return sort!(valid_allocations)
end

function leximin(vectors)
    return vectors[argmin([sort(v) for v in vectors])]
end

function leximax(vectors)
    return vectors[argmax([sort(v, rev=true) for v in vectors])]
end

# Run and print
allocs = core_allocations()
for alloc in allocs
    println(alloc)
end

println("\nTotal integral core allocations: ", length(allocs))
println("Leximin core allocation: ", leximin(allocs))
println("Leximax core allocation: ", leximax(allocs))

