using Test
using NetworkTrading

@testset "Package Loading Tests" begin
    @testset "Basic Package Import" begin
        # Test that NetworkTrading loads without extensions
        @test_nowarn eval(:(using NetworkTrading))
        
        # Test that all core exports are available
        core_exports = [
            :Market, :DynamicState, :seller, :buyer, :isseller, :isbuyer,
            :associated_trades, :incoming_trades, :outgoing_trades, :χ, :counterpart, :associated_agents,
            :BipartiteUnitMarket, :RandomBipartiteUnitMarket, :IntermediaryUnitMarket, :RandomIntermediaryUnitMarket,
            :neighbouring_offers, :active_trades, :welfare, :updated_offers, :dynamic, :indirect_utility,
            :isessential, :essentialagents,
            :generate_intermediary_demand, :generate_intermediary_valuation, :generate_utility, 
            :generate_unit_valuation, :generate_unit_demand, 
            :generate_two_trade_valuation, :generate_random_two_trade_valuation,
            :generate_lyapunov_function, :τ,
            :all_sets, :issubstitutes, :issubmodular, :issupermodular,
            :generate_valuation, :generate_demand, :generate_welfare_fn,
            :create_valuation_fn, :rand
        ]
        
        for export_name in core_exports
            @test isdefined(NetworkTrading, export_name)
        end
    end
    
    @testset "Extension Exports Available" begin
        # Test that extension function names are exported (as stubs)
        optimization_exports = [
            :find_competitive_equilibrium_prices, :lyapunov_model, :constrained_lyapunov_model,
            :core_model, :sorted_core_model, :leximin_model, :leximax_model, :minvar_model,
            :find_optimal_core_imputation, :find_leximin_core_imputation, 
            :find_leximax_core_imputation, :find_minvar_core_imputation,
            :oxs_model, :solve_oxs
        ]
        
        plotting_exports = [
            :plot_offers, :plot_satisfied, :plot_welfare, :plot_lyapunov, :plot_aggr_lyapunov,
            :plotLIP, :draw_arrow!
        ]
        
        # Check optimization exports
        for export_name in optimization_exports
            @test isdefined(NetworkTrading, export_name)
        end
        
        # Check plotting exports
        for export_name in plotting_exports
            @test isdefined(NetworkTrading, export_name)
        end
    end
    
    @testset "Module Structure" begin
        # Test that NetworkTrading module has expected structure
        @test isa(NetworkTrading, Module)
        
        # Test that we can construct basic types
        Ω = [(1,2)]
        valuation = [generate_unit_valuation(1, Ω, 10), generate_unit_valuation(2, Ω, -5)]
        @test_nowarn Market(Ω, valuation)
        
        market = Market(Ω, valuation)
        offers = [Dict(1 => 5), Dict(1 => 5)]
        @test_nowarn DynamicState(market, offers)
    end
    
    @testset "Version and Metadata" begin
        # Test that package metadata is accessible
        @test haskey(Base.package_locks, Base.PkgId(NetworkTrading)) || 
              haskey(Base.loaded_modules, Base.PkgId(NetworkTrading))
    end
end