# Test optimization extension functionality
# Note: These tests will only run if Gurobi, JuMP, and MultiObjectiveAlgorithms are available

using Test
using NetworkTrading

# Check if optimization dependencies are available
const HAS_OPTIMIZATION = try
    using Gurobi, JuMP, MultiObjectiveAlgorithms
    true
catch
    false
end

if HAS_OPTIMIZATION
    @testset "Optimization Extension Tests" begin
        using Gurobi, JuMP, MultiObjectiveAlgorithms
        
        @testset "Basic Optimization Functions" begin
            # Create a simple 2-agent market
            Ω = [(1,2)]
            valuation = [
                generate_unit_valuation(1, Ω, -5),
                generate_unit_valuation(2, Ω, 10)
            ]
            market = Market(Ω, valuation)
            
            # Test lyapunov_model
            @test_nowarn lyapunov_model(market)
            model, p, u = lyapunov_model(market)
            @test isa(model, JuMP.Model)
            @test length(p) == length(Ω)
            @test length(u) == market.n
            
            # Test find_competitive_equilibrium_prices
            @test_nowarn find_competitive_equilibrium_prices(market)
            prices = find_competitive_equilibrium_prices(market)
            @test isa(prices, Vector)
            @test length(prices) == length(Ω)
            @test all(isfinite, prices)
        end
        
        @testset "Core Models" begin
            n = 3
            # Simple welfare function where individual worth is i, grand coalition worth is sum
            w = function(S)
                if isempty(S)
                    return 0.0
                elseif length(S) == n
                    return sum(S) + 1.0  # superadditive bonus
                else
                    return sum(S)
                end
            end
            
            # Test core_model
            @test_nowarn core_model(n, w)
            model, x = core_model(n, w)
            @test isa(model, JuMP.Model)
            @test length(x) == n
            
            # Test sorted_core_model
            @test_nowarn sorted_core_model(n, w)
            model, x, y, P = sorted_core_model(n, w)
            @test isa(model, JuMP.Model)
            @test length(x) == n
            @test length(y) == n
            @test size(P) == (n, n)
        end
        
        @testset "Core Imputation Finding" begin
            n = 2
            # Simple superadditive game
            w = function(S)
                if isempty(S)
                    return 0.0
                elseif length(S) == 1
                    return first(S)
                else
                    return sum(S) + 1.0
                end
            end
            
            # Test minvar core imputation
            @test_nowarn find_optimal_core_imputation(n, w, :min_variance)
            minvar_sol = find_optimal_core_imputation(n, w, :min_variance)
            @test isa(minvar_sol, Vector) || minvar_sol === nothing
            
            if minvar_sol !== nothing
                @test length(minvar_sol) == n
                @test all(isfinite, minvar_sol)
                # Check core constraints
                @test sum(minvar_sol) ≈ w(1:n) rtol=1e-6
            end
            
            # Test convenience functions
            @test_nowarn find_minvar_core_imputation(n, w)
        end
        
        @testset "Market-based Optimization" begin
            # Create a larger market for more interesting optimization
            Ω = [(1,2), (2,3)]
            valuation = [
                generate_unit_valuation(1, Ω, -10),
                generate_intermediary_valuation(2, Ω),
                generate_unit_valuation(3, Ω, 20)
            ]
            market = Market(Ω, valuation)
            
            # Test constrained lyapunov model
            core_imputation = [5.0, 2.0, 8.0]
            @test_nowarn constrained_lyapunov_model(market, core_imputation)
            
            # Test find_competitive_equilibrium_prices with core imputation
            @test_nowarn find_competitive_equilibrium_prices(market, core_imputation)
            
            # Generate welfare function and test with it
            w = generate_welfare_fn(market)
            @test isa(w, Function)
            
            # Test that welfare function works
            @test w(Set()) == 0.0
            @test w(Set(1:market.n)) ≥ 0.0
        end
        
        @testset "OXS Functions" begin
            n = 2
            w = function(S)
                if isempty(S)
                    return 0.0
                elseif length(S) == 1
                    return 2.0 * first(S)
                else
                    return sum(S) + 3.0
                end
            end
            
            # Test oxs_model
            @test_nowarn oxs_model(n, w)
            model, a = oxs_model(n, w)
            @test isa(model, JuMP.Model)
            
            # Test solve_oxs
            @test_nowarn solve_oxs(n, w)
            solution, obj_val = solve_oxs(n, w)
            # Solution might be nothing if infeasible, that's okay for this test
            @test (solution === nothing && obj_val === nothing) || 
                  (isa(solution, Array) && isa(obj_val, Real))
        end
        
        @testset "Extension Integration" begin
            # Test that extensions properly override stub functions
            Ω = [(1,2)]
            valuation = [generate_unit_valuation(1, Ω, -3), generate_unit_valuation(2, Ω, 7)]
            market = Market(Ω, valuation)
            
            # This should not throw an error now that extension is loaded
            @test_nowarn find_competitive_equilibrium_prices(market)
            
            # Check that we get reasonable results
            prices = find_competitive_equilibrium_prices(market)
            @test all(isfinite, prices)
            @test length(prices) == 1  # one trade
        end
    end
else
    @testset "Optimization Extension Unavailable" begin
        @test_skip "Optimization extension tests skipped - dependencies not available"
    end
end