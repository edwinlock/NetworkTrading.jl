using ProgressMeter
using Plots

function statistics(data::Vector)
    n = length(data)
    mean_val = sum(data) / n
    dev = [abs(x - mean_val) for x in data]
    std_dev = sqrt(sum(dev .^ 2) / n)
    return mean_val, std_dev
end

function bipartite_stepnumbers(popsizes; r, reps=100)
    ns = popsizes
    data = zeros(reps, length(ns))
    m = zeros(length(ns))  # mean
    s = zeros(length(ns))  # standard deviation
    e = zeros(length(ns))  # standard error
    @showprogress for i ∈ eachindex(ns)
        n = ns[i]
        for rep ∈ 1:reps
            market = RandomBipartiteUnitMarket(n ÷ 2, n ÷ 2, r)
            data[rep, i], _ = dynamic(market)
        end
        m[i], s[i] = statistics(data[:, i])
        e[i] = s[i] / sqrt(reps)
    end
    plot(ns, m, ribbon=s)
    scatter!(ns, m, ribbon=s, legend=false)
end


