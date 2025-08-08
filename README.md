# NetworkTrading.jl

A Julia package for modeling and analyzing dynamic trading networks with multiple agents.

## Installation

### 1. Install Julia

Download and install Julia from [julialang.org](https://julialang.org/downloads/). This package requires Julia 1.8 or later.

### 2. Install the Package

#### As a User
```julia
using Pkg
Pkg.add(url="https://github.com/edwinlock/NetworkTrading.jl")
```

#### For Development
Clone the repository and add it as a development package:
```bash
git clone https://github.com/edwinlock/NetworkTrading.jl.git
cd NetworkTrading.jl
```

Then in Julia:
```julia
using Pkg
Pkg.develop(path=".")
```

### 3. Optional Extensions

NetworkTrading.jl uses package extensions for optional functionality:

#### Optimization Extension
For competitive equilibrium and core imputation calculations:
```julia
using Pkg
Pkg.add(["Gurobi", "JuMP", "MultiObjectiveAlgorithms"])
```

**Note**: Gurobi requires a license (academic licenses are free at [gurobi.com/academia](https://www.gurobi.com/academia/))

#### Plotting Extension  
For visualization functions:
```julia
using Pkg
Pkg.add("Plots")
```

After installing the dependencies, load them to activate the extensions:
```julia
using Gurobi, JuMP, MultiObjectiveAlgorithms  # for optimization
using Plots  # for plotting
```

## Development Setup

We recommend using [VS Code](https://code.visualstudio.com/) with the [Julia extension](https://marketplace.visualstudio.com/items?itemName=julialang.language-julia) for development.

## Running Two-Agent Convergence Analysis

The `two_agent_convergence.jl` file demonstrates convergence analysis using Lyapunov functions:

```julia
# First, install and load the plotting extension
using Pkg; Pkg.add("Plots")
using Plots

# From the project root directory
julia two_agent_convergence.jl
```

This script:
1. Creates a two-agent market with random valuations
2. Runs best response dynamics
3. Computes Lyapunov functions for each agent
4. Plots convergence behavior over time (requires Plots extension)

The analysis helps understand the stability and convergence properties of the trading dynamics.

## Basic Usage Example

```julia
using NetworkTrading

# 3-agent path network example
# Agent 1: seller, Agent 2: intermediary, Agent 3: buyer
Ω = [(1,2), (2,3)]
valuation = [
    generate_unit_valuation(1, Ω, -10),
    generate_intermediary_valuation(2, Ω),
    generate_unit_valuation(3, Ω, 20)
]
offers = [
    Dict(1 => 9),
    Dict(1 => 21, 2=>16),
    Dict(2 => 1)
]
market = Market(Ω, valuation)
ds = DynamicState(market, offers)
steps, data = @time dynamic(market, ds)

# Visualize results (requires Plots extension)
# using Plots  # uncomment to enable plotting
# plot_offers(market, data)
# plot_satisfied(market, data)  
# plot_welfare(market, data)

# Core imputation analysis (requires optimization extension)
# using Gurobi, JuMP, MultiObjectiveAlgorithms  # uncomment to enable optimization
# w = generate_welfare_fn(market)
# leximin_solution = find_optimal_core_imputation(market.n, w, :leximin)
```

For more examples, see `adhoc.jl`.