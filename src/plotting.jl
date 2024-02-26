using Plots

# plotlyjs()

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
    plot(xs, ys, xlabel=xlabel, ylabel=ylabel, legend=false)
    # scatter!(xs, ys, xlabel=xlabel, ylabel=ylabel, legend=false, lw=3, xticks=xs, yticks=ys, grid=false)
end