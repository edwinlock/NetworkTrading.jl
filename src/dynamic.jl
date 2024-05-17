"""
Implementation of best response dynamic.
"""

using ProgressMeter


"""
Implement best response dynamic that selects an unsatisfied agent
uniformly at random.
"""
function dynamic(market)
    data = (unsatisfied = Vector{Set{Int64}}(), offers = Vector{Vector{Dict{Int64, Int64}}}())
    step = 1
    # @info "Running market with $(market.n) agents and $(market.m) trades."
    while length(market.unsatisfied) > 0
        i = rand(market.unsatisfied)  # choose unsatisfied agent uniformly at random
        best_response!(i, market)
        push!(data.unsatisfied, copy(market.unsatisfied))
        push!(data.offers, copy(market.offers))
        @debug "Step $(step)"
        @debug "Selected agent $(i)"
        @debug "Number of unsatisfied agents is $(length(market.unsatisfied))"
        @debug "Current offers are $(market.offers) \n"
        step += 1
    end
    return step, data
end


"""
Perform best response for agent i. Updates offers of the agent and
the set of unsatisfied neighbours of the market.
"""
function best_response!(i, market::Market)
    p = neighbouring_offers(i, market)
    Ψ = market.demand[i](p)
    newoffers = updated_offers(i, p, Ψ, market)
    newly_unsatisfied = Set(
        counterpart(i, ω, market.Ω) for ω ∈ market.trades[i]
            if market.offers[i][ω] ≠ newoffers[ω]
    )
    market.offers[i] = newoffers
    union!(market.unsatisfied, newly_unsatisfied)
    delete!(market.unsatisfied, i)  # agent i is now satisfied
    return nothing
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