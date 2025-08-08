# Plotting functions - implemented in NetworkTradingPlotsExt when Plots.jl is loaded

const PLOTTING_ERROR_MSG = """
Plotting functionality requires Plots.
Install with: using Pkg; Pkg.add("Plots")
Then load with: using Plots
"""

"""
    plot_offers(market, data)

Plot the evolution of offers over time. Requires Plots.jl to be loaded.
"""
function plot_offers(args...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    plot_satisfied(market, data)

Plot the number of satisfied agents over time. Requires Plots.jl to be loaded.
"""
function plot_satisfied(args...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    plot_welfare(market, data)

Plot welfare evolution over time. Requires Plots.jl to be loaded.
"""
function plot_welfare(args...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    plot_lyapunov(market, data)

Plot Lyapunov function trajectory for each agent. Requires Plots.jl to be loaded.
"""
function plot_lyapunov(args...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    plot_aggr_lyapunov(market, data)

Plot aggregated Lyapunov function. Requires Plots.jl to be loaded.
"""
function plot_aggr_lyapunov(args...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    plotLIP!(plt, a, b, m, n; color)

Draw LIP of valuation with points a and b. Requires Plots.jl to be loaded.
"""
function plotLIP!(args...; kwargs...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    plotLIP(a, b, m, n; color)

Draw LIP of valuation with points a and b. Requires Plots.jl to be loaded.
"""
function plotLIP(args...; kwargs...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end

"""
    draw_arrow!(plt, point, direction)

Draw an arrow on a plot. Requires Plots.jl to be loaded.
"""
function draw_arrow!(args...)
    throw(ArgumentError(PLOTTING_ERROR_MSG))
end