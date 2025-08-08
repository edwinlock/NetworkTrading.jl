# Test plotting extension functionality
# Note: These tests will only run if Plots.jl is available

using Test
using NetworkTrading

# Check if plotting dependencies are available
const HAS_PLOTS = try
    using Plots
    true
catch
    false
end

if HAS_PLOTS
    @testset "Plotting Extension Tests" begin
        using Plots
        
        # Set up test market and data
        Ω = [(1,2), (2,3)]
        valuation = [
            generate_unit_valuation(1, Ω, -10),
            generate_intermediary_valuation(2, Ω),
            generate_unit_valuation(3, Ω, 20)
        ]
        market = Market(Ω, valuation)
        offers = [
            Dict(1 => 9, 2 => 0),
            Dict(1 => 21, 2 => 16),
            Dict(2 => 1, 1 => 0)
        ]
        ds = DynamicState(market, offers)
        steps, data = dynamic(market, ds)
        
        @testset "Basic Plotting Functions" begin
            # Test plot_offers - should not throw errors
            @test_nowarn plot_offers(market, data)
            p1 = plot_offers(market, data)
            @test isa(p1, Plots.Plot)
            
            # Test plot_satisfied
            @test_nowarn plot_satisfied(market, data)
            p2 = plot_satisfied(market, data)
            @test isa(p2, Plots.Plot)
            
            # Test plot_welfare
            @test_nowarn plot_welfare(market, data)
            p3 = plot_welfare(market, data)
            @test isa(p3, Plots.Plot)
        end
        
        @testset "Lyapunov Plotting Functions" begin
            # Test plot_lyapunov
            @test_nowarn plot_lyapunov(market, data)
            p4 = plot_lyapunov(market, data)
            @test isa(p4, Plots.Plot)
            
            # Test plot_aggr_lyapunov
            @test_nowarn plot_aggr_lyapunov(market, data)
            p5 = plot_aggr_lyapunov(market, data)
            @test isa(p5, Plots.Plot)
        end
        
        @testset "Utility Plotting Functions" begin
            # Test plotLIP
            a = [2, 3]
            b = [4, 5]
            m, n = 6, 7
            
            @test_nowarn plotLIP(a, b, m, n; color=:red)
            p6 = plotLIP(a, b, m, n; color=:red)
            @test isa(p6, Plots.Plot)
            
            # Test plotLIP! (modifying existing plot)
            p7 = plot()
            @test_nowarn plotLIP!(p7, a, b, m, n; color=:blue)
            @test isa(p7, Plots.Plot)
            
            # Test draw_arrow!
            p8 = plot()
            point = [2.0, 3.0]
            direction = [1.0, 1.0]
            @test_nowarn draw_arrow!(p8, point, direction)
            @test isa(p8, Plots.Plot)
        end
        
        @testset "Extension Integration" begin
            # Test that extensions properly override stub functions
            # This should not throw an error now that extension is loaded
            @test_nowarn plot_offers(market, data)
            
            # Verify we get Plots.Plot objects, not errors
            result = plot_offers(market, data)
            @test isa(result, Plots.Plot)
        end
        
        @testset "Plot Content Verification" begin
            # Create simple 2-agent market for predictable results
            Ω_simple = [(1,2)]
            val_simple = [
                generate_unit_valuation(1, Ω_simple, -5),
                generate_unit_valuation(2, Ω_simple, 10)
            ]
            market_simple = Market(Ω_simple, val_simple)
            offers_simple = [Dict(1 => 6), Dict(1 => 7)]
            ds_simple = DynamicState(market_simple, offers_simple)
            steps_simple, data_simple = dynamic(market_simple, ds_simple)
            
            # Test that plots have reasonable structure
            p_offers = plot_offers(market_simple, data_simple)
            @test length(p_offers.series_list) > 0  # Should have some data series
            
            p_welfare = plot_welfare(market_simple, data_simple)
            @test length(p_welfare.series_list) > 0
            
            # Test plot attributes
            p_satisfied = plot_satisfied(market_simple, data_simple)
            @test p_satisfied.attr[:xlabel] == "Steps"
            @test p_satisfied.attr[:ylabel] == "#Satisfied"
        end
        
        @testset "Edge Cases" begin
            # Test with minimal data
            Ω_min = [(1,2)]
            val_min = [generate_unit_valuation(1, Ω_min, 0), generate_unit_valuation(2, Ω_min, 0)]
            market_min = Market(Ω_min, val_min)
            offers_min = [Dict(1 => 0), Dict(1 => 0)]
            ds_min = DynamicState(market_min, offers_min)
            steps_min, data_min = dynamic(market_min, ds_min)
            
            # Should handle edge cases gracefully
            @test_nowarn plot_offers(market_min, data_min)
            @test_nowarn plot_satisfied(market_min, data_min)
            @test_nowarn plot_welfare(market_min, data_min)
            
            # Test utility functions with edge cases
            a_edge = [0, 0]
            b_edge = [1, 1]
            @test_nowarn plotLIP(a_edge, b_edge, 2, 2; color=:black)
        end
    end
else
    @testset "Plotting Extension Unavailable" begin
        @test_skip "Plotting extension tests skipped - Plots.jl not available"
    end
end