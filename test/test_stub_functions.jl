using NetworkTrading
using Test

@testset "Stub Functions Tests" begin
    # Test that stub functions throw appropriate errors when extensions aren't loaded
    
    @testset "Optimization Stub Errors" begin
        Ω = [(1,2), (2,3)]
        valuation = [
            generate_unit_valuation(1, Ω, -10),
            generate_intermediary_valuation(2, Ω),
            generate_unit_valuation(3, Ω, 20)
        ]
        market = Market(Ω, valuation)
        
        # Test lyapunov_model stub
        @test_throws ArgumentError lyapunov_model(market)
        
        # Test constrained_lyapunov_model stub
        @test_throws ArgumentError constrained_lyapunov_model(market, [1.0, 2.0, 3.0])
        
        # Test find_competitive_equilibrium_prices stubs
        @test_throws ArgumentError find_competitive_equilibrium_prices(market)
        @test_throws ArgumentError find_competitive_equilibrium_prices(market, [1.0, 2.0, 3.0])
        
        # Test core model functions
        w = x -> sum(x)  # simple welfare function
        @test_throws ArgumentError core_model(3, w)
        @test_throws ArgumentError sorted_core_model(3, w)
        @test_throws ArgumentError leximin_model(3, w)
        @test_throws ArgumentError leximax_model(3, w)
        @test_throws ArgumentError minvar_model(3, w)
        
        # Test core imputation functions
        @test_throws ArgumentError find_optimal_core_imputation(3, w, :leximin)
        @test_throws ArgumentError find_leximin_core_imputation(3, w)
        @test_throws ArgumentError find_leximax_core_imputation(3, w)
        @test_throws ArgumentError find_minvar_core_imputation(3, w)
        
        # Test OXS functions
        @test_throws ArgumentError oxs_model(3, w)
        @test_throws ArgumentError solve_oxs(3, w)
        
        # Check that error messages contain helpful information
        try
            find_competitive_equilibrium_prices(market)
            @test false  # Should not reach here
        catch e
            @test e isa ArgumentError
            @test contains(string(e), "Gurobi")
            @test contains(string(e), "JuMP")
            @test contains(string(e), "MultiObjectiveAlgorithms")
        end
    end
    
    @testset "Plotting Stub Errors" begin
        Ω = [(1,2)]
        valuation = [
            generate_unit_valuation(1, Ω, -5),
            generate_unit_valuation(2, Ω, 10)
        ]
        market = Market(Ω, valuation)
        offers = [Dict(1 => 6), Dict(1 => 6)]
        ds = DynamicState(market, offers)
        steps, data = dynamic(market, ds)
        
        # Test plotting function stubs
        @test_throws ArgumentError plot_offers(market, data)
        @test_throws ArgumentError plot_satisfied(market, data)
        @test_throws ArgumentError plot_welfare(market, data)
        @test_throws ArgumentError plot_lyapunov(market, data)
        @test_throws ArgumentError plot_aggr_lyapunov(market, data)
        
        # Test utility plotting functions
        @test_throws ArgumentError plotLIP([1, 2], [3, 4], 5, 6; color=:red)
        @test_throws ArgumentError draw_arrow!(nothing, [1, 2], [0.5, 0.5])
        
        # Check that error messages contain helpful information
        try
            plot_offers(market, data)
            @test false  # Should not reach here
        catch e
            @test e isa ArgumentError
            @test contains(string(e), "Plots")
            @test contains(string(e), "Pkg.add")
        end
    end
    
    @testset "Error Message Quality" begin
        # Verify error messages are informative and helpful
        market = Market([(1,2)], [generate_unit_valuation(1, [(1,2)], 10), generate_unit_valuation(2, [(1,2)], -5)])
        
        # Test optimization error message
        try
            lyapunov_model(market)
        catch e
            msg = string(e)
            @test contains(msg, "Optimization")
            @test contains(msg, "Install with:")
            @test contains(msg, "using")
        end
        
        # Test plotting error message  
        try
            plot_offers(market, nothing)
        catch e
            msg = string(e)
            @test contains(msg, "Plotting")
            @test contains(msg, "Install with:")
            @test contains(msg, "using")
        end
    end
end