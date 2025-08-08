using NetworkTrading
using Test
using Random

@testset "Comprehensive Dynamics Tests" begin
    @testset "Dynamic Convergence Properties" begin
        Random.seed!(123)
        
        # Test convergence for simple 2-agent markets
        for trial in 1:20
            Ω = [(1,2)]
            val1 = rand(-20:20)
            val2 = rand(-20:20) 
            # Ensure there's potential for trade
            if val1 + val2 <= 0
                val2 = abs(val1) + 5
            end
            
            valuations = [generate_unit_valuation(1, Ω, val1), generate_unit_valuation(2, Ω, val2)]
            market = Market(Ω, valuations)
            offers = [Dict(1 => rand(0:30)), Dict(1 => rand(0:30))]
            
            ds = DynamicState(market, offers)
            steps, data = dynamic(market, ds)
            
            @test steps > 0
            @test steps <= 100  # Should converge reasonably quickly
            @test length(data.offers) == steps
            @test length(data.unsatisfied) == steps
            @test length(data.selected) == steps
            
            # Check that final state has some desirable properties
            final_unsatisfied = data.unsatisfied[end]
            if val1 + val2 > 5  # If there's significant gains from trade
                @test length(final_unsatisfied) <= 1  # At most one agent unsatisfied
            end
        end
    end
    
    @testset "Dynamic System Properties" begin
        # Test path networks of different lengths
        for path_length in [2, 3, 4, 5]
            Ω = [(i, i+1) for i in 1:(path_length-1)]
            # Create alternating sellers and buyers
            valuations = [i % 2 == 1 ? generate_unit_valuation(i, Ω, -10) : generate_unit_valuation(i, Ω, 20) for i in 1:path_length]
            # Make intermediaries
            for i in 2:(path_length-1)
                valuations[i] = generate_intermediary_valuation(i, Ω)
            end
            
            market = Market(Ω, valuations)
            
            # Test multiple starting configurations
            for config_trial in 1:5
                Random.seed!(config_trial * path_length)
                offers = [Dict(ω => rand(0:25) for ω in 1:length(Ω)) for _ in 1:path_length]
                
                ds = DynamicState(market, offers)
                steps, data = dynamic(market, ds)
                
                @test steps >= 1
                @test length(data.offers) == steps
                
                # Test welfare computation
                for step in 1:min(steps, 5)  # Test first few steps
                    w = welfare(market, data.offers[step])
                    @test typeof(w) <: Real
                end
                
                # Test that active_trades function works
                for step in 1:min(steps, 3)
                    active_result = active_trades(data.offers[step], market)
                    @test typeof(active_result) <: Tuple
                end
            end
        end
    end
    
    @testset "Best Response Properties" begin
        # Test that best response moves are sensible
        for trial in 1:10
            Ω = [(1,2), (2,3)]
            valuations = [
                generate_unit_valuation(1, Ω, -15),
                generate_intermediary_valuation(2, Ω),
                generate_unit_valuation(3, Ω, 25)
            ]
            market = Market(Ω, valuations)
            
            Random.seed!(trial)
            initial_offers = [Dict(ω => rand(0:20) for ω in 1:length(Ω)) for _ in 1:3]
            original_offers = deepcopy(initial_offers)
            
            ds = DynamicState(market, initial_offers)
            
            # Test individual best response updates
            for agent in 1:3
                if agent in ds.unsatisfied
                    old_offer = copy(ds.offers[agent])
                    best_response!(agent, market, ds)
                    new_offer = ds.offers[agent]
                    
                    # Offer should change (unless already optimal)
                    # Test that the structure is preserved
                    @test keys(old_offer) == keys(new_offer)
                    @test all(ω -> typeof(new_offer[ω]) <: Integer, keys(new_offer))
                    @test all(ω -> new_offer[ω] >= 0, keys(new_offer))
                end
            end
        end
    end
    
    @testset "Welfare Calculation Properties" begin
        test_networks = [
            ([(1,2)], 2),
            ([(1,2), (2,3)], 3), 
            ([(1,2), (2,3), (3,4)], 4),
            ([(1,2), (1,3)], 3),
            ([(1,2), (2,3), (1,3)], 3)
        ]
        
        for (Ω, n) in test_networks
            # Create markets with known welfare properties
            valuations = [i <= n÷2 ? generate_unit_valuation(i, Ω, -5) : generate_unit_valuation(i, Ω, 10) for i in 1:n]
            market = Market(Ω, valuations)
            
            # Test welfare with different offer configurations
            test_offers_configs = [
                # All zero offers
                [Dict(ω => 0 for ω in 1:length(Ω)) for _ in 1:n],
                # All equal offers
                [Dict(ω => 10 for ω in 1:length(Ω)) for _ in 1:n],
                # Random offers
                [Dict(ω => rand(0:20) for ω in 1:length(Ω)) for _ in 1:n]
            ]
            
            for offers in test_offers_configs
                w = welfare(market, offers)
                @test typeof(w) <: Real
                
                # Test welfare function generation
                welfare_fn = generate_welfare_fn(market)
                @test typeof(welfare_fn) <: Function
                
                # Test that welfare function gives consistent results
                for subset_size in 0:min(n, 4)
                    test_set = Set(1:subset_size)
                    @test typeof(welfare_fn(test_set)) <: Real
                end
            end
        end
    end
    
    @testset "Lyapunov Function Properties" begin
        for network_trial in 1:5
            n = 3 + network_trial
            Ω = [(i, i+1) for i in 1:(n-1)]
            valuations = [i <= n÷2 ? generate_unit_valuation(i, Ω, -10) : generate_unit_valuation(i, Ω, 20) for i in 1:n]
            market = Market(Ω, valuations)
            
            L = generate_lyapunov_function(market)
            @test typeof(L) <: Function
            
            # Test Lyapunov function on various offer profiles
            for agent in 1:n
                # Test with agent's zero offers
                zero_offers = Dict(ω => 0 for ω in 1:length(Ω))
                L_zero = L(zero_offers)
                @test typeof(L_zero) <: Real
                @test L_zero >= 0  # Lyapunov functions should be non-negative
                
                # Test with random offers
                Random.seed!(agent * network_trial)
                random_offers = Dict(ω => rand(0:30) for ω in 1:length(Ω))
                L_random = L(random_offers)
                @test typeof(L_random) <: Real
                @test L_random >= 0
                
                # Test with high offers
                high_offers = Dict(ω => 100 for ω in 1:length(Ω))
                L_high = L(high_offers)
                @test typeof(L_high) <: Real
                @test L_high >= 0
                
                # High offers should generally give higher Lyapunov values for sellers
                # (This is a heuristic test, not always true)
                if any(associated_trades(agent, Ω)) && χ(agent, first(associated_trades(agent, Ω)), Ω) == 1
                    @test L_high >= L_zero
                end
            end
        end
    end
end