#!/usr/bin/env julia

"""
Test script for generating a random substitutable valuation LIP
"""

include("createLIP.jl")

# Test with different numbers of trades
println("=" ^ 60)
println("Testing random substitutable valuation LIP generation")
println("=" ^ 60)

try
    # Test with 3 trades, upper bound 10, bounding box [-15, 15]^3
    println("\n📊 Testing with 3 trades...")
    json_data, valuation = create_random_LIP_file("random_3_trades_LIP.json", 3, 10, -15, 15; seed=123)
    
    println("\n✅ Random 3D LIP generated successfully!")
    println("\nGenerated file:")
    println("  - random_3_trades_LIP.json")
    println("\nYou can now load this in the VTK.js visualization!")
    
catch e
    println("\n❌ Test failed: $e")
    rethrow(e)
end