using Test

@testset "NetworkTrading.jl" begin
    @testset "Package Loading" begin
        include("test_package_loading.jl")
    end
    
    @testset "Core Functionality" begin
        include("test_core_functionality.jl")
    end
    
    @testset "Stub Functions" begin
        include("test_stub_functions.jl")
    end
    
    @testset "Optimization Extension" begin
        include("test_optimization_extension.jl")
    end
    
    @testset "Plotting Extension" begin
        include("test_plotting_extension.jl")
    end
    
    # Comprehensive test suites
    @testset "Comprehensive Market Tests" begin
        include("test_comprehensive_markets.jl")
    end
    
    @testset "Comprehensive Dynamics Tests" begin  
        include("test_comprehensive_dynamics.jl")
    end
    
    @testset "Comprehensive Edge Cases" begin
        include("test_comprehensive_edge_cases.jl")
    end
    
    @testset "Comprehensive Valuation Tests" begin
        include("test_comprehensive_valuations.jl")
    end
    
    @testset "Network Structure Tests" begin
        include("test_network_structures.jl")
    end
end
