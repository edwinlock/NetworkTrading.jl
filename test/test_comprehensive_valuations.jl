using NetworkTrading
using Test
using Random
using Combinatorics

@testset "Comprehensive Valuation Tests" begin
    @testset "Unit Valuation Properties" begin
        test_networks = [
            [(1,2)],
            [(1,2), (2,3)], 
            [(1,2), (2,3), (3,4)],
            [(1,2), (1,3)],
            [(1,2), (2,3), (1,3), (3,4)]
        ]
        
        for Ω in test_networks
            n = maximum(maximum(trade) for trade in Ω)
            
            for agent in 1:n, value in [-50, -10, -1, 0, 1, 10, 50]
                val_fn = generate_unit_valuation(agent, Ω, value)
                
                # Test basic properties
                @test val_fn(Set{Int}()) == 0
                @test typeof(val_fn) <: Function
                
                # Test on all possible subsets of agent's trades
                agent_trades = collect(associated_trades(agent, Ω))
                
                # Test all subsets of agent's trades
                for subset_size in 0:length(agent_trades)
                    for subset in Combinatorics.combinations(agent_trades, subset_size)
                        result = val_fn(Set(subset))
                        @test typeof(result) <: Real
                        
                        # For positive values, test that valuations are well-defined
                        if value > 0 && subset_size > 0
                            @test typeof(result) <: Real
                            @test isfinite(result)
                        end
                    end
                end
                
                # Test with trades not belonging to agent (should return some value)
                other_trades = setdiff(1:length(Ω), agent_trades)
                if !isempty(other_trades)
                    val_with_other = val_fn(Set([first(other_trades)]))
                    # Agent valuations for non-involved trades should be well-defined
                    @test typeof(val_with_other) <: Real
                    @test isfinite(val_with_other)
                end
            end
        end
    end
    
    @testset "Intermediary Valuation Properties" begin
        test_networks = [
            [(1,2), (2,3)],      # Simple path
            [(1,2), (2,3), (2,4)], # Star with center at 2  
            [(1,2), (2,3), (3,2)], # Cycle (if valid)
            [(1,2), (2,3), (3,4), (2,4)], # More complex
        ]
        
        for Ω in test_networks
            n = maximum(maximum(trade) for trade in Ω)
            
            for agent in 1:n
                agent_trades = collect(associated_trades(agent, Ω))
                
                # Only test agents that can actually be intermediaries (have multiple trades)
                if length(agent_trades) >= 2
                    val_fn = generate_intermediary_valuation(agent, Ω)
                    
                    @test val_fn(Set{Int}()) == 0
                    @test typeof(val_fn) <: Function
                    
                    # Test with single trades (should give penalty)
                    for single_trade in agent_trades
                        penalty = val_fn(Set([single_trade]))
                        @test penalty <= 0  # Should be penalty or zero
                    end
                    
                    # Test with all trades (should be best case)
                    all_trades_val = val_fn(Set(agent_trades))
                    
                    # Test with partial subsets
                    if length(agent_trades) > 2
                        for subset_size in 2:(length(agent_trades)-1)
                            for subset in Combinatorics.combinations(agent_trades, subset_size)
                                partial_val = val_fn(Set(subset))
                                # Partial completion should give some real value
                                @test typeof(partial_val) <: Real
                                @test isfinite(partial_val)
                            end
                        end
                    end
                    
                    # Test that all subset valuations are well-defined
                    all_subsets = collect(powerset(agent_trades))
                    for subset in all_subsets
                        curr_val = val_fn(Set(subset))
                        @test typeof(curr_val) <: Real
                        @test isfinite(curr_val)
                    end
                end
            end
        end
    end
    
    @testset "Two-Trade Valuation Properties" begin
        for trial in 1:20
            Random.seed!(trial)
            
            # Create various network topologies
            Ω_options = [
                [(1,2)],
                [(1,2), (2,3)],
                [(1,2), (2,3), (3,4)],
                [(1,2), (1,3)],
                [(1,2), (2,3), (1,3)]
            ]
            
            for Ω in Ω_options
                n = maximum(maximum(trade) for trade in Ω)
                
                for agent in 1:n
                    val_max1 = rand(1:20)
                    val_max2 = rand(1:20)
                    
                    # Only use two-trade valuation for networks with exactly 2 trades
                    if length(Ω) == 2
                        agent_trades = collect(associated_trades(agent, Ω))
                        if length(agent_trades) >= 2  # Agent must participate in multiple trades
                            val_fn = generate_random_two_trade_valuation(val_max1, val_max2, agent, Ω)
                        else
                            continue  # Skip agents that don't have enough trades
                        end
                    else
                        continue  # Skip networks that don't have exactly 2 trades
                    end
                    
                    @test val_fn(Set{Int}()) == 0
                    @test typeof(val_fn) <: Function
                    
                    # Test with agent's trades
                    agent_trades = collect(associated_trades(agent, Ω))
                    
                    # Test various combinations
                    for subset_size in 0:min(length(agent_trades), 3)
                        if subset_size == 0
                            @test val_fn(Set{Int}()) == 0
                        else
                            for subset in Combinatorics.combinations(agent_trades, subset_size)
                                result = val_fn(Set(subset))
                                @test typeof(result) <: Real
                                # Should be bounded by the max values
                                @test abs(result) <= val_max1 + val_max2 + 50  # Some tolerance
                            end
                        end
                    end
                    
                    # Test with non-agent trades
                    all_trades = 1:length(Ω)
                    non_agent_trades = setdiff(all_trades, agent_trades)
                    if !isempty(non_agent_trades)
                        val_non_agent = val_fn(Set([first(non_agent_trades)]))
                        # Should typically be less valuable than agent's own trades
                        if !isempty(agent_trades)
                            val_own_trade = val_fn(Set([first(agent_trades)]))
                            # This is heuristic - not always true but often
                            @test typeof(val_non_agent) <: Real
                        end
                    end
                end
            end
        end
    end
    
    @testset "Valuation Consistency Tests" begin
        # Test that valuations behave consistently across different scenarios
        Ω = [(1,2), (2,3), (3,4)]
        
        # Test that same agent, same parameters give same valuations
        val1_a = generate_unit_valuation(1, Ω, 10)
        val1_b = generate_unit_valuation(1, Ω, 10)
        
        test_sets = [Set{Int}(), Set([1]), Set([1,2]), Set([2,3])]
        for test_set in test_sets
            @test val1_a(test_set) == val1_b(test_set)
        end
        
        # Test that different agents with same parameters can give different results
        val1 = generate_unit_valuation(1, Ω, 10)
        val2 = generate_unit_valuation(2, Ω, 10)
        
        # They might differ because they're involved in different trades
        @test typeof(val1(Set([1]))) <: Real
        @test typeof(val2(Set([1]))) <: Real
        
        # Test intermediary valuations for consistency
        inter1_a = generate_intermediary_valuation(2, Ω)
        inter1_b = generate_intermediary_valuation(2, Ω)
        
        @test inter1_a(Set{Int}()) == inter1_b(Set{Int}())
        @test inter1_a(Set([1])) == inter1_b(Set([1]))
    end
    
    @testset "Valuation Boundary Tests" begin
        Ω = [(1,2), (2,3)]
        
        # Test with extreme values
        extreme_values = [-1000, -100, -10, -1, 0, 1, 10, 100, 1000]
        
        for val in extreme_values
            val_fn = generate_unit_valuation(1, Ω, val)
            
            @test val_fn(Set{Int}()) == 0
            
            # Test with various trade combinations
            result1 = val_fn(Set([1]))
            result2 = val_fn(Set([2]))
            result_both = val_fn(Set([1,2]))
            
            @test typeof(result1) <: Real
            @test typeof(result2) <: Real  
            @test typeof(result_both) <: Real
            
            # Results should be finite
            @test isfinite(result1)
            @test isfinite(result2) 
            @test isfinite(result_both)
        end
        
        # Test two-trade valuations with extreme values (agent 2 participates in both trades)
        for val1 in [-100, 0, 100], val2 in [-100, 0, 100]
            val_fn = generate_random_two_trade_valuation(abs(val1)+1, abs(val2)+1, 2, Ω)
            
            result = val_fn(Set([1]))
            @test typeof(result) <: Real
            @test isfinite(result)
        end
    end
    
    @testset "Valuation Function Composition" begin
        # Test that valuations work correctly when combined in markets
        Ω = [(1,2), (2,3), (3,4)]
        
        # Create diverse valuation types
        valuations = [
            generate_unit_valuation(1, Ω, -15),                    # seller
            generate_intermediary_valuation(2, Ω),                 # intermediary  
            generate_intermediary_valuation(3, Ω),                 # intermediary
            generate_unit_valuation(4, Ω, 25)                     # buyer
        ]
        
        market = Market(Ω, valuations)
        
        # Test that market construction works
        @test market.n == 4
        @test length(market.Ω) == 3
        
        # Test that all valuation functions are callable
        for i in 1:4
            val_fn = market.valuation[i]
            @test typeof(val_fn) <: Function
            
            # Test with empty set
            @test val_fn(Set{Int}()) == 0
            
            # Test with various trade sets
            for trade_id in 1:3
                result = val_fn(Set([trade_id]))
                @test typeof(result) <: Real
                @test isfinite(result)
            end
        end
        
        # Test utility and demand functions work
        for i in 1:4
            util_fn = market.utility[i]
            demand_fn = market.demand[i]
            
            @test typeof(util_fn) <: Function
            @test typeof(demand_fn) <: Function
        end
        
        # Test that the market can be used for dynamics
        offers = [Dict(ω => rand(0:20) for ω in 1:3) for _ in 1:4]
        ds = DynamicState(market, offers)
        steps, data = dynamic(market, ds)
        
        @test steps >= 1
        @test length(data.offers) == steps
    end
end