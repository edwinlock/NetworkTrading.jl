module NetworkTrading

include("markets.jl")
include("dynamic.jl")
include("preferences.jl")
include("plotting.jl")


export Market, isseller, isbuyer, associated_trades, incoming_trades, outgoing_trades, χ, counterpart
export neighbouring_offers, active, welfare, updated_offers, best_response!, dynamic
export generate_intermediary_demand, generate_intermediary_valuation, generate_utility, generate_unit_valuation, generate_unit_demand
export generate_random_two_trade_buyer_valuation, generate_random_two_trade_seller_valuation, generate_two_trade_demand
export plot_offers, plot_satisfied, plot_welfare
export BipartiteUnitMarket, RandomBipartiteUnitMarket, IntermediaryUnitMarket, RandomIntermediaryUnitMarket

end
