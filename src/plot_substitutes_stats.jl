using Plots
using NetworkTrading

num_valuations(n, ub) = (ub+1)^(2^n-1)

n = 2
ubs = 0:100
subs_count = [length(SubstitutesValuations(Set(1:n), Set(Int[]), ub)) for ub ∈ ubs]
all_count = [num_valuations(n, ub) for ub ∈ ubs]
plt = plot(ubs, subs_count, label="#substitutes valuations for $n goods", xlabel="ub")
plt_ratio = plot(ubs, subs_count ./ all_count, label="#ratio of substitutes and all valuations for $n goods", xlabel="ub")

n = 3
ubs = 0:15
subs_count = [length(SubstitutesValuations(Set(1:n), Set(Int[]), ub)) for ub ∈ ubs]
all_count = [num_valuations(n, ub) for ub ∈ ubs]
plot!(plt, ubs, subs_count, label="#substitutes valuations for $n goods", xlabel="ub")
plot!(plt_ratio, ubs, subs_count ./ all_count, label="#ratio of substitutes and all valuations for $n goods", xlabel="ub")

savefig(plt, "substitutes_stats.pdf")
savefig(plt_ratio, "substitutes_ratio_stats.pdf")
