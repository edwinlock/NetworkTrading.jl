module NetworkTrading

include("markets.jl")
include("dynamic.jl")
include("preferences.jl")
include("plotting.jl")


export Market, seller, buyer, isseller, isbuyer, associated_trades, incoming_trades, outgoing_trades, χ, counterpart
export BipartiteUnitMarket, RandomBipartiteUnitMarket, IntermediaryUnitMarket, RandomIntermediaryUnitMarket

export neighbouring_offers, active, welfare, updated_offers, best_response!, dynamic, indirect_utility
export generate_intermediary_demand, generate_intermediary_valuation, generate_utility, generate_unit_valuation, generate_unit_demand, generate_object_valuation, generate_two_trade_valuation, generate_random_two_trade_valuation
export objects2trades, generate_lyapunov_function, τ
export generate_two_trade_valuation, generate_params, all_sets
export plot_offers, plot_satisfied, plot_welfare, plot_lyapunov
export plotLIP, plotLIP!, draw_arrow!
end
