using JuMP
using Gurobi
using NetworkTrading.jl

# Define the sets and parameters
I = [1, 2, 3]  # Set of indices i
Ω = [(1,2), (2,3)] # Set of elements ω
valuation = [
    generate_unit_valuation(1, Ω, -10),
    generate_intermediary_valuation(2, Ω),
    generate_unit_valuation(3, Ω, 20)
]
v = Dict{Tuple{Int, Set}, Float64}()  # Value function v^i(Φ)
χ = Dict{Tuple{Int, Int, Set}, Float64}()  # Indicator χ^i_{ωΦ}

# Create the model
model = Model(Gurobi.Optimizer)

# Define the decision variables
@variable(model, x[i in I, Φ in 2^Ω[i]] >= 0)

# Objective function
@objective(model, Max, sum(v[i, Φ] * x[i, Φ] for i in I, Φ in 2^Ω[i]))

# Constraint 1: ∑_{i∈I} ∑_{Φ∈2^{Ω^i}} χ^i_{ωΦ} x^i_{Φ} = 0, ∀ ω ∈ Ω
@constraint(model, [ω in Ω], sum(χ[i, ω, Φ] * x[i, Φ] for i in I, Φ in 2^Ω[i]) == 0)

# Constraint 2: ∑_{Φ∈2^{Ω^i}} x^i_{Φ} ≤ 1, ∀ i ∈ I
@constraint(model, [i in I], sum(x[i, Φ] for Φ in 2^Ω[i]) <= 1)

# Solve the model
optimize!(model)

# Retrieve the results
if termination_status(model) == MOI.OPTIMAL
    println("Optimal solution found!")
    for i in I
        for Φ in 2^Ω[i]
            println("x[$i, $Φ] = ", value(x[i, Φ]))
        end
    end
else
    println("No optimal solution found.")
end