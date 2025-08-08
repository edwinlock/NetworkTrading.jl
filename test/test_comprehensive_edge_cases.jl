using NetworkTrading
using Test
using Random

@testset "Comprehensive Edge Cases" begin
    @testset "Boundary Value Tests" begin
        # Test with extreme valuations
        extreme_values = [-1000, -100, -1, 0, 1, 100, 1000]
        
        for val1 in extreme_values, val2 in extreme_values
            if val1 != val2  # Avoid identical agents
                Ω = [(1,2)]
                valuations = [generate_unit_valuation(1, Ω, val1), generate_unit_valuation(2, Ω, val2)]
                
                @test_nowarn Market(Ω, valuations)
                market = Market(Ω, valuations)
                
                offers = [Dict(1 => abs(val1)), Dict(1 => abs(val2))]
                @test_nowarn DynamicState(market, offers)
                ds = DynamicState(market, offers)
                
                @test_nowarn dynamic(market, ds)
                steps, data = dynamic(market, ds)
                @test steps >= 1
                @test steps <= 200  # Should still converge
                
                @test_nowarn welfare(market, offers)
                w = welfare(market, offers)
                @test typeof(w) <: Real
            end
        end
    end
    
    @testset "Zero and Negative Price Tests" begin
        Ω = [(1,2), (2,3)]
        valuations = [
            generate_unit_valuation(1, Ω, -10),
            generate_intermediary_valuation(2, Ω),
            generate_unit_valuation(3, Ω, 20)
        ]
        market = Market(Ω, valuations)
        
        # Test with zero offers
        zero_offers = [Dict(1 => 0, 2 => 0), Dict(1 => 0, 2 => 0), Dict(1 => 0, 2 => 0)]
        ds_zero = DynamicState(market, zero_offers)
        steps_zero, data_zero = dynamic(market, ds_zero)
        @test steps_zero >= 1
        @test welfare(market, zero_offers) isa Real
        
        # Test active_trades with zero offers
        active_result = active_trades(zero_offers, market)
        @test typeof(active_result) <: Tuple
        
        # Test Lyapunov function with zero offers
        L = generate_lyapunov_function(market)
        for agent in 1:3
            L_val = L(zero_offers[agent])
            @test L_val >= 0
        end
    end
    
    @testset "Single Agent Markets" begin
        # Test markets where only one agent can trade (degenerate case)
        Ω = [(1,2)]
        valuations = [generate_unit_valuation(1, Ω, 10), generate_unit_valuation(2, Ω, 10)]
        market = Market(Ω, valuations)
        
        # When both agents want the same thing, dynamics should still work
        offers = [Dict(1 => 5), Dict(1 => 15)]
        ds = DynamicState(market, offers)
        steps, data = dynamic(market, ds)
        @test steps >= 1
        
        # Test utilities
        for agent in 1:2
            p = neighbouring_offers(agent, market, offers)
            u = indirect_utility(p, market.demand[agent], market.utility[agent])
            @test typeof(u) <: Real
        end
    end
    
    @testset "Large Network Stress Tests" begin
        # Test larger networks to ensure scalability
        for network_size in [6, 8, 10]
            # Create path network
            Ω = [(i, i+1) for i in 1:(network_size-1)]
            
            # Alternating buyer/seller pattern with intermediaries
            valuations = []
            for i in 1:network_size
                if i == 1
                    push!(valuations, generate_unit_valuation(i, Ω, -20))  # seller
                elseif i == network_size  
                    push!(valuations, generate_unit_valuation(i, Ω, 30))   # buyer
                else
                    push!(valuations, generate_intermediary_valuation(i, Ω))  # intermediary
                end
            end
            
            market = Market(Ω, valuations)
            @test market.n == network_size
            
            # Test with random initial offers
            Random.seed!(network_size)
            offers = [Dict(ω => rand(0:20) for ω in 1:length(Ω)) for _ in 1:network_size]
            
            ds = DynamicState(market, offers)
            @test_nowarn dynamic(market, ds)
            steps, data = dynamic(market, ds)
            
            # Should still converge in reasonable time even for large networks
            @test steps <= 500
            @test length(data.offers) == steps
            
            # Test welfare calculation on large network
            w = welfare(market, offers)
            @test typeof(w) <: Real
            
            # Test Lyapunov functions scale properly
            L = generate_lyapunov_function(market)
            for agent in [1, network_size÷2, network_size]  # Test a few agents
                L_val = L(offers[agent])
                @test typeof(L_val) <: Real
                @test L_val >= 0
            end
        end
    end
    
    @testset "Identical Agent Tests" begin
        # Test markets with identical agents (should lead to degenerate behavior)
        Ω = [(1,2), (2,3)]
        
        # All agents have identical valuations
        identical_val = generate_unit_valuation(1, Ω, 10)
        valuations = [identical_val, identical_val, identical_val]
        market = Market(Ω, valuations)
        
        offers = [Dict(1 => 5, 2 => 5), Dict(1 => 5, 2 => 5), Dict(1 => 5, 2 => 5)]
        ds = DynamicState(market, offers)
        
        # Should still work, even if not economically interesting
        steps, data = dynamic(market, ds)
        @test steps >= 1
        @test steps <= 100  # Should converge quickly since no one wants to change
        
        # Welfare should be computable
        w = welfare(market, offers)
        @test typeof(w) <: Real
    end
    
    @testset "Random Network Topologies" begin
        Random.seed!(42)
        
        # Test various random network configurations
        for trial in 1:10
            n_agents = rand(3:6)
            n_trades = rand(2:(n_agents * (n_agents-1) ÷ 4))  # Not too dense
            
            # Generate random trades ensuring connectivity
            trades = Set{Tuple{Int,Int}}()
            
            # Ensure the network is connected by creating a path first
            for i in 1:(n_agents-1)
                push!(trades, (i, i+1))
            end
            
            # Add random additional trades
            while length(trades) < n_trades && length(trades) < n_agents * (n_agents-1) ÷ 2
                i, j = rand(1:n_agents), rand(1:n_agents)
                if i != j
                    push!(trades, (min(i,j), max(i,j)))
                end
            end
            
            Ω = collect(trades)
            
            # Generate random valuations
            valuations = []
            for agent in 1:n_agents
                val_type = rand(1:3)
                if val_type == 1
                    push!(valuations, generate_unit_valuation(agent, Ω, rand(-20:20)))
                elseif val_type == 2
                    push!(valuations, generate_intermediary_valuation(agent, Ω))
                else
                    push!(valuations, generate_random_two_trade_valuation(20, 20, agent, Ω))
                end
            end
            
            market = Market(Ω, valuations)
            @test market.n == n_agents
            @test length(market.Ω) == length(Ω)
            
            # Test dynamics on random network
            offers = [Dict(ω => rand(0:15) for ω in 1:length(Ω)) for _ in 1:n_agents]
            ds = DynamicState(market, offers)
            
            @test_nowarn dynamic(market, ds)
            steps, data = dynamic(market, ds)
            @test steps >= 1
            @test steps <= 1000  # Should eventually converge
            
            # Test welfare and Lyapunov functions
            @test_nowarn welfare(market, offers)
            L = generate_lyapunov_function(market)
            @test_nowarn L(offers[1])
        end
    end
    
    @testset "Degenerate Cases" begin
        # Test market with no trades (should handle gracefully)
        # Note: This might not be a valid case, but we test error handling
        
        # Test market with single trade, multiple agents
        Ω = [(1,2)]
        
        # Three agents, but only two can trade
        valuations = [
            generate_unit_valuation(1, Ω, -10),
            generate_unit_valuation(2, Ω, 20),
            generate_unit_valuation(3, Ω, 0)  # Can't actually participate
        ]
        
        market = Market(Ω, valuations)
        offers = [Dict(1 => 8), Dict(1 => 12), Dict(1 => 10)]  # Agent 3's offer irrelevant
        
        ds = DynamicState(market, offers)
        steps, data = dynamic(market, ds)
        @test steps >= 1
        
        # Agent 3 should remain unsatisfied throughout (or quickly become satisfied)
        # since they can't actually affect any trades
        
        # Test welfare calculation
        w = welfare(market, offers)
        @test typeof(w) <: Real
    end
    
    @testset "Numerical Precision Tests" begin
        # Test with offers that might cause numerical issues
        Ω = [(1,2)]
        valuations = [generate_unit_valuation(1, Ω, -1), generate_unit_valuation(2, Ω, 1)]
        market = Market(Ω, valuations)
        
        # Test with very close offers
        close_offers = [Dict(1 => 1000), Dict(1 => 1001)]
        ds = DynamicState(market, close_offers)
        steps, data = dynamic(market, ds)
        @test steps >= 1
        
        # Test with identical offers (should converge immediately)
        identical_offers = [Dict(1 => 5), Dict(1 => 5)]
        ds_identical = DynamicState(market, identical_offers)
        steps_identical, data_identical = dynamic(market, ds_identical)
        @test steps_identical >= 1
        @test steps_identical <= 10  # Should converge very quickly
    end
end