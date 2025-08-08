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
end
