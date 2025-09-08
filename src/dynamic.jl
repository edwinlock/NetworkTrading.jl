"""
Implementation of best response market dynamic.
"""

using ProgressMeter


"""
Implement best response dynamic that selects an unsatisfied agent
uniformly at random.
"""
function dynamic(market::Market, ds::DynamicState)
    data = (
        unsatisfied = Vector{Set{Int64}}(),
        offers = Vector{Vector{Dict{Int64, Int64}}}(),
        selected = Vector{Int}()
    )
    steps = 0
    @debug "Running market with $(market.n) agents and $(market.m) trades."
    @debug "Initial offers are $(ds.offers).\n"
    while length(ds.unsatisfied) > 0
        steps += 1
        i = rand(ds.unsatisfied)  # choose unsatisfied agent uniformly at random
        best_response!(i, market, ds)
        push!(data.selected, i)
        push!(data.unsatisfied, copy(ds.unsatisfied))
        push!(data.offers, copy(ds.offers))
        @debug "Step $(steps)"
        @debug "Selected agent $(i)"
        @debug "Number of unsatisfied agents is $(length(ds.unsatisfied))."
        @debug "Current offers are $(ds.offers).\n"
    end
    return steps, data
end


"""
Perform best response for agent i. Updates offers of the agent and
the set of unsatisfied neighbours of the market.
"""
function best_response!(i, market::Market, ds::DynamicState)
    newoffers = best_response(i, market::Market, ds.offers)
    # Determine all agents who are newly unsatisfied
    newly_unsatisfied = Set(
        counterpart(i, ω, market.Ω) for ω ∈ market.trades[i]
            if ds.offers[i][ω] ≠ newoffers[ω]
    )
    ds.offers[i] = newoffers
    union!(ds.unsatisfied, newly_unsatisfied)
    delete!(ds.unsatisfied, i)  # agent i is now satisfied
    return nothing
end


function best_response(i, market::Market, offers)
    p = neighbouring_offers(i, market, offers)
    Ψ = market.demand[i](p)
    newoffers = updated_offers(i, p, Ψ, market)
    return newoffers
end

"""
Compute updated offers of agent i given market prices p and demanded bundle Ψ.
"""
function updated_offers(i, p, Ψ, market::Market)
    function newoffer(ω)
        ω ∈ Ψ && return p[ω]
        return p[ω] - χ(i, ω, market.Ω)
    end
    return Dict(ω => newoffer(ω) for ω ∈ market.trades[i])
end