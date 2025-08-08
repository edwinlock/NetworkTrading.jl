using NetworkTrading
using Test
using Random

@testset "Comprehensive Market Tests" begin
    @testset "Market Construction Edge Cases" begin
        # Test single trade markets
        @test_nowarn Market([(1,2)], [generate_unit_valuation(1, [(1,2)], 5), generate_unit_valuation(2, [(1,2)], -3)])
        
        # Test larger markets
        for n in [3, 4, 5, 6]
            Ω = [(i, i+1) for i in 1:(n-1)]
            valuations = [i <= n÷2 ? generate_unit_valuation(i, Ω, -10) : generate_unit_valuation(i, Ω, 20) for i in 1:n]
            market = Market(Ω, valuations)
            @test market.n == n
            @test length(market.Ω) == n-1
        end
        
        # Test star networks
        for n in [3, 4, 5]
            # Agent 1 connected to all others
            Ω = [(1, i) for i in 2:n]
            valuations = [generate_intermediary_valuation(1, Ω)]
            append!(valuations, [generate_unit_valuation(i, Ω, 10) for i in 2:n])
            market = Market(Ω, valuations)
            @test market.n == n
            @test length(market.Ω) == n-1
        end
        
        # Test complete bipartite networks  
        for n1 in [2, 3], n2 in [2, 3]
            Ω = [(i, j) for i in 1:n1, j in (n1+1):(n1+n2)]
            valuations = [generate_unit_valuation(i, Ω, -5) for i in 1:n1]
            append!(valuations, [generate_unit_valuation(i, Ω, 15) for i in (n1+1):(n1+n2)])
            market = Market(Ω, valuations)
            @test market.n == n1 + n2
            @test length(market.Ω) == n1 * n2
        end
    end
    
    @testset "Valuation Function Properties" begin
        Ω = [(1,2), (2,3), (3,4)]
        
        # Test unit valuations are monotonic
        for agent in 1:4, value in [-20, -5, 0, 5, 10, 20]
            val_fn = generate_unit_valuation(agent, Ω, value)
            @test val_fn(Set{Int}()) == 0
            # Test monotonicity: adding trades shouldn't decrease value for buyers, increase for sellers
            if value > 0  # buyer
                @test val_fn(Set([1])) >= val_fn(Set{Int}())
                @test val_fn(Set([1,2])) >= val_fn(Set([1]))
            end
        end
        
        # Test two-trade valuations
        for agent in 1:4
            val_fn = generate_random_two_trade_valuation(10, 10, agent, Ω)
            @test val_fn(Set{Int}()) == 0
            @test typeof(val_fn(Set([1]))) <: Real
            @test typeof(val_fn(Set([1,2]))) <: Real
        end
        
        # Test intermediary valuations 
        for agent in 2:3  # agents that can be intermediaries
            val_fn = generate_intermediary_valuation(agent, Ω)
            @test val_fn(Set{Int}()) == 0
            # Intermediaries should get penalty for incomplete trades
            agent_trades = collect(associated_trades(agent, Ω))
            if length(agent_trades) > 1
                @test val_fn(Set([first(agent_trades)])) < 0
            end
        end
    end
    
    @testset "Market Utility Functions" begin
        # Test χ function properties
        test_networks = [
            [(1,2)], 
            [(1,2), (2,3)], 
            [(1,2), (2,3), (3,4)],
            [(1,2), (1,3)],  # star
            [(1,2), (2,3), (1,3)]  # triangle
        ]
        
        for Ω in test_networks
            n = maximum(maximum(trade) for trade in Ω)
            for trade_idx in 1:length(Ω)
                trade = Ω[trade_idx]
                # Each trade should have exactly two participants with opposite signs
                participants = filter(i -> χ(i, trade_idx, Ω) != 0, 1:n)
                @test length(participants) == 2
                @test trade[1] in participants && trade[2] in participants
                @test χ(trade[1], trade_idx, Ω) + χ(trade[2], trade_idx, Ω) == 0
                @test abs(χ(trade[1], trade_idx, Ω)) == 1
                @test abs(χ(trade[2], trade_idx, Ω)) == 1
            end
        end
        
        # Test counterpart function
        for Ω in test_networks
            for (trade_idx, (i, j)) in enumerate(Ω)
                @test counterpart(i, trade_idx, Ω) == j
                @test counterpart(j, trade_idx, Ω) == i
            end
        end
    end
    
    @testset "DynamicState Properties" begin
        for n in [2, 3, 4, 5]
            Ω = [(i, i+1) for i in 1:(n-1)]
            valuations = [i <= n÷2 ? generate_unit_valuation(i, Ω, -10) : generate_unit_valuation(i, Ω, 20) for i in 1:n]
            market = Market(Ω, valuations)
            
            # Test various initial offer configurations
            # All zero offers
            zero_offers = [Dict(ω => 0 for ω in 1:length(Ω)) for _ in 1:n]
            ds1 = DynamicState(market, zero_offers)
            @test length(ds1.unsatisfied) == n
            
            # Random offers
            Random.seed!(42)
            random_offers = [Dict(ω => rand(0:20) for ω in 1:length(Ω)) for _ in 1:n]
            ds2 = DynamicState(market, random_offers)
            @test length(ds2.unsatisfied) <= n
            
            # High offers (should lead to more dissatisfaction)
            high_offers = [Dict(ω => 100 for ω in 1:length(Ω)) for _ in 1:n]
            ds3 = DynamicState(market, high_offers)
            @test length(ds3.unsatisfied) >= length(ds1.unsatisfied)
        end
    end
end