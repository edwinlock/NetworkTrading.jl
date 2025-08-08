using NetworkTrading
using Test

@testset "Core Functionality Tests" begin
    # Test basic market construction
    @testset "Market Construction" begin
        Ω = [(1,2), (2,3)]
        valuation = [
            generate_unit_valuation(1, Ω, -10),
            generate_intermediary_valuation(2, Ω),
            generate_unit_valuation(3, Ω, 20)
        ]
        market = Market(Ω, valuation)
        
        @test market.n == 3
        @test length(market.Ω) == 2
        @test market.Ω == [(1,2), (2,3)]
    end
    
    @testset "DynamicState Construction" begin
        Ω = [(1,2), (2,3)]
        valuation = [
            generate_unit_valuation(1, Ω, -10),
            generate_intermediary_valuation(2, Ω),
            generate_unit_valuation(3, Ω, 20)
        ]
        market = Market(Ω, valuation)
        offers = [
            Dict(1 => 9),
            Dict(1 => 21, 2=>16),
            Dict(2 => 1)
        ]
        
        ds = DynamicState(market, offers)
        @test length(ds.offers) == 3
        @test length(ds.unsatisfied) == 3
    end
    
    @testset "Valuation Functions" begin
        Ω = [(1,2)]
        
        # Test unit valuation
        val1 = generate_unit_valuation(1, Ω, 10)
        @test val1(Set([1])) == 10
        @test val1(Set{Int}()) == 0
        
        # Test intermediary valuation 
        val2 = generate_intermediary_valuation(2, Ω)
        @test val2(Set{Int}()) == 0
        # Note: intermediary valuations penalize incomplete trades, so this won't be 0
        @test val2(Set([1])) < 0  # intermediary gets penalty for incomplete trades
    end
    
    @testset "Market Utilities" begin
        Ω = [(1,2), (2,3)]
        
        # Test χ function
        @test χ(1, 1, Ω) == -1  # agent 1 buys trade 1 
        @test χ(2, 1, Ω) == 1   # agent 2 sells trade 1
        @test χ(1, 2, Ω) == 0   # agent 1 not involved in trade 2
        
        # Test counterpart function
        @test counterpart(1, 1, Ω) == 2
        @test counterpart(2, 1, Ω) == 1
        @test counterpart(2, 2, Ω) == 3
    end
    
    @testset "Dynamic System" begin
        # Small 2-agent market for testing dynamics
        Ω = [(1,2)]
        valuation = [
            generate_unit_valuation(1, Ω, -5),
            generate_unit_valuation(2, Ω, 10)
        ]
        market = Market(Ω, valuation)
        offers = [Dict(1 => 8), Dict(1 => 7)]
        
        ds = DynamicState(market, offers)
        steps, data = dynamic(market, ds)
        
        @test steps > 0
        @test length(data.offers) == steps
        @test length(data.unsatisfied) == steps
    end
    
    @testset "Welfare Calculation" begin
        Ω = [(1,2)]
        valuation = [
            generate_unit_valuation(1, Ω, -5),
            generate_unit_valuation(2, Ω, 10)
        ]
        market = Market(Ω, valuation)
        offers = [Dict(1 => 6), Dict(1 => 6)]
        
        w = welfare(market, offers)
        @test w ≥ 0  # welfare should be non-negative for feasible trades
    end
    
    @testset "Lyapunov Functions" begin
        Ω = [(1,2)]
        valuation = [
            generate_unit_valuation(1, Ω, -5),
            generate_unit_valuation(2, Ω, 10)
        ]
        market = Market(Ω, valuation)
        
        L = generate_lyapunov_function(market)
        @test typeof(L) <: Function
        
        # Test with specific offers
        offers = Dict(1 => 6)
        lyap_val = L(offers)
        @test typeof(lyap_val) <: Real
    end
end