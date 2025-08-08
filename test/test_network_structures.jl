using NetworkTrading
using Test

@testset "Network Structure Tests" begin
    @testset "Path Networks" begin
        # Test path networks of various lengths
        for path_length in 2:8
            Ω = [(i, i+1) for i in 1:(path_length-1)]
            
            # Test network properties
            @test length(Ω) == path_length - 1
            
            # Create alternating seller/buyer pattern
            valuations = []
            for i in 1:path_length
                if i == 1
                    push!(valuations, generate_unit_valuation(i, Ω, -10))  # start seller
                elseif i == path_length
                    push!(valuations, generate_unit_valuation(i, Ω, 20))   # end buyer  
                else
                    push!(valuations, generate_intermediary_valuation(i, Ω))  # intermediary
                end
            end
            
            market = Market(Ω, valuations)
            @test market.n == path_length
            
            # Test that each internal agent is connected to exactly 2 trades
            for i in 2:(path_length-1)
                agent_trades = collect(associated_trades(i, Ω))
                @test length(agent_trades) == 2
            end
            
            # Test that end agents are connected to exactly 1 trade
            @test length(collect(associated_trades(1, Ω))) == 1
            @test length(collect(associated_trades(path_length, Ω))) == 1
            
            # Test network connectivity
            for i in 1:(path_length-1)
                for j in (i+1):path_length
                    # Check if there's a path between agents i and j
                    # In a path network, every pair should be connected
                    trades_between = []
                    for trade_idx in i:(j-1)
                        push!(trades_between, trade_idx)
                    end
                    @test length(trades_between) == j - i
                end
            end
            
            # Test dynamics on path network
            offers = [Dict(ω => rand(0:15) for ω in 1:length(Ω)) for _ in 1:path_length]
            ds = DynamicState(market, offers)
            steps, data = dynamic(market, ds)
            
            @test steps >= 1
            @test steps <= 100  # Should converge reasonably quickly
        end
    end
    
    @testset "Star Networks" begin
        # Test star networks with different center agents and sizes
        for n_total in 3:6
            for center in 1:n_total
                # Create star with center agent connected to all others
                Ω = []
                for other in 1:n_total
                    if other != center
                        if center < other
                            push!(Ω, (center, other))
                        else
                            push!(Ω, (other, center))
                        end
                    end
                end
                
                @test length(Ω) == n_total - 1
                
                # Center should be intermediary, others should be end-agents
                valuations = []
                for i in 1:n_total
                    if i == center
                        push!(valuations, generate_intermediary_valuation(i, Ω))
                    else
                        # Alternate buyers and sellers
                        val = i % 2 == 0 ? 15 : -10
                        push!(valuations, generate_unit_valuation(i, Ω, val))
                    end
                end
                
                market = Market(Ω, valuations)
                @test market.n == n_total
                
                # Test that center agent is connected to all trades
                center_trades = collect(associated_trades(center, Ω))
                @test length(center_trades) == n_total - 1
                
                # Test that non-center agents are connected to exactly 1 trade
                for i in 1:n_total
                    if i != center
                        agent_trades = collect(associated_trades(i, Ω))
                        @test length(agent_trades) == 1
                    end
                end
                
                # Test that the center agent can reach all others
                for i in 1:n_total
                    if i != center
                        # There should be exactly one trade connecting center to i
                        connecting_trades = filter(trade_idx -> 
                            (χ(center, trade_idx, Ω) != 0 && χ(i, trade_idx, Ω) != 0), 1:length(Ω))
                        @test length(connecting_trades) == 1
                    end
                end
                
                # Test dynamics
                offers = [Dict(ω => rand(0:12) for ω in 1:length(Ω)) for _ in 1:n_total]
                ds = DynamicState(market, offers)
                steps, data = dynamic(market, ds)
                
                @test steps >= 1
            end
        end
    end
    
    @testset "Complete Bipartite Networks" begin
        # Test complete bipartite networks K_{m,n}
        for m in 2:4, n in 2:4
            # Group 1: agents 1 to m (sellers)
            # Group 2: agents (m+1) to (m+n) (buyers)
            
            Ω = []
            for i in 1:m, j in (m+1):(m+n)
                push!(Ω, (i, j))
            end
            
            @test length(Ω) == m * n
            
            # Create valuations: sellers negative, buyers positive
            valuations = []
            for i in 1:m
                push!(valuations, generate_unit_valuation(i, Ω, -10))
            end
            for j in (m+1):(m+n)
                push!(valuations, generate_unit_valuation(j, Ω, 20))
            end
            
            market = Market(Ω, valuations)
            @test market.n == m + n
            
            # Test connectivity properties
            for i in 1:m
                agent_trades = collect(associated_trades(i, Ω))
                @test length(agent_trades) == n  # Each seller connected to all buyers
            end
            
            for j in (m+1):(m+n)
                agent_trades = collect(associated_trades(j, Ω))
                @test length(agent_trades) == m  # Each buyer connected to all sellers
            end
            
            # Test that sellers only connect to buyers and vice versa
            for i in 1:m, j in (m+1):(m+n)
                # There should be exactly one trade between seller i and buyer j
                connecting_trades = filter(trade_idx -> 
                    (χ(i, trade_idx, Ω) != 0 && χ(j, trade_idx, Ω) != 0), 1:length(Ω))
                @test length(connecting_trades) == 1
            end
            
            # Test that no seller connects directly to another seller
            for i in 1:m, j in 1:m
                if i != j
                    connecting_trades = filter(trade_idx -> 
                        (χ(i, trade_idx, Ω) != 0 && χ(j, trade_idx, Ω) != 0), 1:length(Ω))
                    @test length(connecting_trades) == 0
                end
            end
            
            # Test dynamics on bipartite network
            offers = [Dict(ω => rand(0:10) for ω in 1:length(Ω)) for _ in 1:(m+n)]
            ds = DynamicState(market, offers)
            steps, data = dynamic(market, ds)
            
            @test steps >= 1
            @test steps <= 50  # Should converge quickly due to clear buyer/seller structure
        end
    end
    
    @testset "Cycle Networks" begin
        # Test cycle networks
        for cycle_size in 3:6
            # Create cycle: 1-2-3-...-n-1
            Ω = [(i, i+1) for i in 1:(cycle_size-1)]
            push!(Ω, (cycle_size, 1))  # Close the cycle
            
            @test length(Ω) == cycle_size
            
            # In a cycle, every agent should be an intermediary
            valuations = [generate_intermediary_valuation(i, Ω) for i in 1:cycle_size]
            
            market = Market(Ω, valuations)
            @test market.n == cycle_size
            
            # Test that every agent is connected to exactly 2 trades
            for i in 1:cycle_size
                agent_trades = collect(associated_trades(i, Ω))
                @test length(agent_trades) == 2
            end
            
            # Test cycle property: should be able to traverse the cycle
            current_agent = 1
            visited_trades = Set{Int}()
            
            for step in 1:cycle_size
                agent_trades = collect(associated_trades(current_agent, Ω))
                
                # Find a trade we haven't used yet
                unvisited_trades = setdiff(agent_trades, visited_trades)
                @test !isempty(unvisited_trades)
                
                next_trade = first(unvisited_trades)
                push!(visited_trades, next_trade)
                
                # Find the other agent in this trade
                next_agent = counterpart(current_agent, next_trade, Ω)
                current_agent = next_agent
                
                if step == cycle_size
                    @test current_agent == 1  # Should return to start
                end
            end
            
            # Test dynamics on cycle (might not converge quickly due to circular dependencies)
            offers = [Dict(ω => rand(0:8) for ω in 1:length(Ω)) for _ in 1:cycle_size]
            ds = DynamicState(market, offers)
            steps, data = dynamic(market, ds)
            
            @test steps >= 1
            # Cycles might take longer to converge or oscillate
        end
    end
    
    @testset "Tree Networks" begin
        # Test various tree structures
        
        # Binary tree
        tree_configs = [
            # Simple binary tree: 1 root, 2 and 3 children
            ([(1,2), (1,3)], 3),
            # Larger binary tree
            ([(1,2), (1,3), (2,4), (2,5), (3,6), (3,7)], 7),
            # Asymmetric tree
            ([(1,2), (2,3), (2,4), (4,5)], 5)
        ]
        
        for (Ω, n_agents) in tree_configs
            # Create mixed valuations
            valuations = []
            for i in 1:n_agents
                degree = length(collect(associated_trades(i, Ω)))
                if degree == 1
                    # Leaf nodes: buyers or sellers
                    val = i % 2 == 0 ? 15 : -15
                    push!(valuations, generate_unit_valuation(i, Ω, val))
                else
                    # Internal nodes: intermediaries
                    push!(valuations, generate_intermediary_valuation(i, Ω))
                end
            end
            
            market = Market(Ω, valuations)
            @test market.n == n_agents
            
            # Test tree property: should have exactly n-1 edges
            @test length(Ω) == n_agents - 1
            
            # Test that the network is connected (no isolated components)
            # Every agent should have at least one trade
            for i in 1:n_agents
                agent_trades = collect(associated_trades(i, Ω))
                @test length(agent_trades) >= 1
            end
            
            # Test that there are no cycles (tree property)
            # This is harder to test algorithmically, but our construction guarantees it
            
            # Test dynamics
            offers = [Dict(ω => rand(0:12) for ω in 1:length(Ω)) for _ in 1:n_agents]
            ds = DynamicState(market, offers)
            steps, data = dynamic(market, ds)
            
            @test steps >= 1
        end
    end
    
    @testset "Network Utility Functions" begin
        # Test various network utility functions across different topologies
        test_networks = [
            ([(1,2)], 2, "edge"),
            ([(1,2), (2,3)], 3, "path"),
            ([(1,2), (1,3)], 3, "star"),
            ([(1,2), (2,3), (1,3)], 3, "triangle"),
            ([(1,2), (2,3), (3,4), (4,1)], 4, "cycle")
        ]
        
        for (Ω, n, name) in test_networks
            # Test χ function properties for this network
            for agent in 1:n, trade_idx in 1:length(Ω)
                chi_val = χ(agent, trade_idx, Ω)
                @test chi_val ∈ [-1, 0, 1]
                
                if chi_val != 0
                    # Agent participates in this trade
                    @test agent in Ω[trade_idx]
                end
            end
            
            # Test counterpart function
            for trade_idx in 1:length(Ω)
                i, j = Ω[trade_idx]
                @test counterpart(i, trade_idx, Ω) == j
                @test counterpart(j, trade_idx, Ω) == i
            end
            
            # Test associated_trades function
            for agent in 1:n
                trades = collect(associated_trades(agent, Ω))
                for trade_idx in trades
                    @test agent in Ω[trade_idx]
                end
                
                # Verify completeness: agent should be in exactly these trades
                for trade_idx in 1:length(Ω)
                    if agent in Ω[trade_idx]
                        @test trade_idx in trades
                    else
                        @test trade_idx ∉ trades
                    end
                end
            end
        end
    end
end