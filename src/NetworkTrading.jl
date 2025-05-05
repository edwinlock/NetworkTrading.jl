module NetworkTrading

include("markets.jl")
include("dynamic.jl")
include("preferences.jl")
include("plotting.jl")


export Market, seller, buyer, isseller, isbuyer, associated_trades, incoming_trades, outgoing_trades, χ, counterpart, associated_agents
export BipartiteUnitMarket, RandomBipartiteUnitMarket, IntermediaryUnitMarket, RandomIntermediaryUnitMarket

export neighbouring_offers, active, welfare, updated_offers, best_response!, dynamic, indirect_utility
export generate_intermediary_demand, generate_intermediary_valuation, generate_utility, generate_unit_valuation, generate_unit_demand, generate_object_valuation, generate_two_trade_valuation, generate_random_two_trade_valuation
export objects2trades, generate_lyapunov_function, τ
export generate_two_trade_valuation, generate_params, all_sets
export plot_offers, plot_satisfied, plot_welfare, plot_lyapunov
export plotLIP, plotLIP!, draw_arrow!
export generate_valuation, generate_demand

using PrecompileTools
@compile_workload begin
    redirect_stdout(devnull) do  # suppress output to terminal while precompiling
    valmax = 20
    Ω = [(1,2), (1,2)]
    valuation = [
    generate_random_two_trade_valuation(valmax, valmax, 1, Ω),
    generate_random_two_trade_valuation(valmax, valmax, 2, Ω),
    ]
    offers = [
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax)),
    Dict(1 => rand(0:valmax), 2 => rand(0:valmax))
    ]
    market = Market(Ω, offers, valuation)
    steps, data = @time dynamic(market)
    # plot_offers(market, data)
    # plot_satisfied(market, data)
    # plot_welfare(market, data)
    plot_lyapunov(market, data)
    end
end

end


