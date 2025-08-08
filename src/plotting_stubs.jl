# Stub functions for plotting functionality
# These will be overridden by the NetworkTradingPlotsExt extension when loaded

const PLOTTING_ERROR_MSG = """
Plotting functionality requires Plots.jl.
Install with: using Pkg; Pkg.add("Plots")
Then load with: using Plots
"""

function plot_offers(market, data)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function plot_satisfied(market, data)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function plot_welfare(market, data)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function plot_lyapunov(market, data)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function plot_aggr_lyapunov(market, data)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function plotLIP!(plt, a::Vector, b::Vector, m, n; color=Symbol)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function plotLIP(a, b, m, n; color)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

function draw_arrow!(plt, point, direction)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end