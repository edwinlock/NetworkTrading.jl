using Plots
# using PlotlyJS

function plot_offers(market, data)
    xlabel, ylabel = "Steps", "Offer"
    numoffers = 2*length(market.Ω)
    numsteps = length(data.offers)
    xs = 1:numsteps
    ys = zeros(Int, numsteps, numoffers)
    labels = Matrix{String}(undef, 1, numoffers)
    j = 1
    for i ∈ 1:market.n
        for ω ∈ market.trades[i]
            labels[j] = "Agent $(i), Trade $(ω)"
            ys[:,j] .= [ data.offers[s][i][ω] for s ∈ xs ]
            j += 1
        end
    end
    plot(xs, ys, xlabel=xlabel, ylabel=ylabel, labels=labels, lw=3, legend=:outerbottom)
end

function plot_satisfied(market, data)
    xlabel, ylabel = "Steps", "#Satisfied"
    numsteps = length(data.offers)
    xs = 1:numsteps
    ys = market.n .- [length(data.unsatisfied[s]) for s ∈ xs]
    plot(xs, ys, xlabel=xlabel, ylabel=ylabel, legend=false)
    # scatter!(xs, ys, xlabel=xlabel, ylabel=ylabel, legend=false, lw=3, xticks=xs, yticks=ys, grid=false)
end

function plot_welfare(market, data)
    xlabel, ylabel = "Steps", "Welfare"
    numsteps = length(data.offers)
    xs = 1:numsteps
    ys = [welfare(data.offers[s], market) for s ∈ xs]
    # plot(xs, ys, xlabel=xlabel, ylabel=ylabel, legend=false, mode="lines+markers")
    plot(xs, ys, xlabel=xlabel, ylabel=ylabel, legend=false, lw=3, xticks=xs, yticks=ys, grid=false, mode="lines+markers")
end


"""
Draw LIP of valuation with valuation points a and b in a bounding box of size
(m+2, n+2).
"""
function plotLIP!(a::Vector, b::Vector, m, n; color=Symbol)
    # diagonal line
    plot!(
        [a[1], b[1]],
        [a[2], b[2]],
        xlims=(-2, m+2),
        ylims=(-2, n+2),
        xticks=-2:1:m+2,
        yticks=-2:1:n+2,
        legend=false,
        aspect_ratio=:equal,
        color=color,
        linewidth=2,
        # showaxis=false
    )
    # lower horizontal line
    plot!([-2, a[1]], [a[2], a[2]], color=color, linewidth=2)
    # upper horizontal line
    plot!([b[1], m+2], [b[2], b[2]], color=color, linewidth=2)
    # lower vertical line
    plot!([a[1], a[1]], [-2, a[2]], color=color, linewidth=2)
    # upper vertical line
    plot!([b[1], b[1]], [b[2], n+2], color=color, linewidth=2)
end

function plotLIP(a, b, m, n; color)
    plot()
    plotLIP!(a, b, m, n; color=color)
end


function draw_arrow!(point, direction)
    scaling_factor = 0.5
    endpoint = point .+ (scaling_factor .* direction)
    plot!(
        [point[1], endpoint[1]],
        [point[2], endpoint[2]],
        arrow=true,
        color=:gray,
        linewidth=1,
        label=""
    )
    return nothing
end