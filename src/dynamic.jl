using ProgressMeter

### Implementation of dynamic

"""
Retrieve the offers of agent i's neighbours.
"""
function neighbouring_offers(i::Int, offers, market::Market)::Dict{Int,Int}
    prices = Dict{Int,Int}()
    for ω ∈ market.trades[i]  # Set p[ω] to the offer of counterpart of trade    
        j = counterpart(i, ω, market.Ω)
        prices[ω] = offers[j][ω]
    end
    return prices
end
neighbouring_offers(i::Int, market::Market) = neighbouring_offers(i, market.offers, market)


"""
Compute active trades and prices. Returns prices and set of trades (p, Ψ).
"""
function active(offers, market::Market)
    # Compute trades for which both offers agree, and their prices.
    Ψ = Set{Int}()
    p = Dict{Int,Int}()
    for ω ∈ 1:market.m
        buyer, seller = market.Ω[ω]
        if offers[buyer][ω] == offers[seller][ω]
            push!(Ψ, ω)
            p[ω] = offers[buyer][ω]
        end
    end
    return p, Ψ
end


"""
Compute welfare (aggregate utility) of market with specified offers.
"""
function welfare(offers, market::Market)
    p, Ψ = active(offers, market::Market)    
    return sum(market.utility[i](p,Ψ) for i ∈ 1:market.n;init=0)
end
welfare(market::Market) = welfare(market.offers, market)


"""
Compute new offers of agent i given market prices p and demanded bundle Ψ.
"""
function compute_offers(i, p, Ψ, market::Market)
    function newoffer(ω)
        ω ∈ Ψ && return p[ω]
        χ = isbuyer(i, ω, market.Ω) ? 1 : -1
        return p[ω] - χ
    end
    return Dict(ω => newoffer(ω) for ω ∈ market.trades[i])
end


"""
Perform best response for agent i. Updates offers of the agent and
the set of unsatisfied neighbours of the market.
"""
function best_response!(i, market::Market)
    p = neighbouring_offers(i, market)
    Ψ = market.demand[i](p)
    newoffers = compute_offers(i, p, Ψ, market)
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
        @debug "Current offers are $(market.offers)"
        step += 1
    end
    return step, data
end
