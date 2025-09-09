"""
Implementation of Locus of Indifference Prices (LIP) visualization for NetworkTrading.jl

This module implements the creation of polyhedral complexes representing the LIP
of an agent's valuation function, as described in visualiseLIP.qmd.
"""

using Revise
using Polyhedra
using JSON3
using LinearAlgebra
using GLPK

# Type aliases
const Prices = Vector{Rational{Int}}
const Bundle = Set{Int}

# Set up solver for Polyhedra operations
const lib = DefaultLibrary{Float64}(GLPK.Optimizer)

# ============================================================================
# Utility functions
# ============================================================================

"""
    bundle_to_string(bundle)

Convert a bundle (set of goods) to its string representation.
"""
function bundle_to_string(bundle::Bundle)
    isempty(bundle) && return "∅"
    sorted_bundle = sort(collect(bundle))
    return "{" * join(sorted_bundle, ",") * "}"
end

"""
    compute_bundle_price_sum(bundle, χ, p)

Compute Σ_{ω ∈ bundle} χ_ω * p_ω for a given bundle, coefficient vector χ, and price vector p.
"""
function compute_bundle_price_sum(bundle::Bundle, χ::Prices, p::Prices)
    return sum(χ[ω] * p[ω] for ω in bundle if ω <= length(χ))
end

# ============================================================================
# Halfspace computation functions
# ============================================================================

"""
    build_constraint_coefficients(phi, psi, χ)

Build the coefficient vector for the constraint H(Φ,Ψ):
Σ_{ω ∈ Ψ} χ_ω p_ω - Σ_{ω ∈ Φ} χ_ω p_ω ≥ v(Ψ) - v(Φ)
Returns the coefficient vector for [p_1, p_2, p_3].
"""
function build_constraint_coefficients(Φ::Bundle, Ψ::Bundle, χ::Prices)
    n_goods = length(χ)
    coeffs = zeros(Rational{Int}, n_goods)
    
    # Add coefficients for Ψ (positive)
    for ω in Ψ
        if ω <= n_goods
            coeffs[ω] += χ[ω]
        end
    end
    
    # Subtract coefficients for Φ (negative)
    for ω in Φ
        if ω <= n_goods
            coeffs[ω] -= χ[ω]
        end
    end
    
    return coeffs
end

"""
    compute_halfspace_constraint(phi, psi, v, χ)

Create the halfspace constraint H(Φ,Ψ) as a HalfSpace object.
"""
function compute_halfspace_constraint(Φ::Bundle, Ψ::Bundle, v::Function, χ::Prices)
    coeffs = build_constraint_coefficients(Φ, Ψ, χ)
    rhs = Rational{Int}(v(Ψ) - v(Φ))
    
    # Create halfspace: coeffs' * p ≥ rhs
    return HalfSpace(coeffs, rhs)
end

"""
    compute_all_halfspaces(A, v, χ)

Generate all halfspace constraints H(Φ,Ψ) for all bundle pairs.
Returns a dictionary mapping (Φ, Ψ) pairs to HalfSpace objects.
"""
function compute_all_halfspaces(A::Vector{Bundle}, v::Function, χ::Prices)
    halfspaces = Dict{Tuple{Bundle, Bundle}, HalfSpace}()
    
    for Φ in A, Ψ in A
        if Φ != Ψ
            halfspaces[(Φ, Ψ)] = compute_halfspace_constraint(Φ, Ψ, v, χ)
        end
    end
    
    return halfspaces
end

# ============================================================================
# Bounding box functions
# ============================================================================

"""
    create_bounding_box(n_dims, M)

Create bounding box [0,M]^n by intersecting halfspaces: 
0 ≤ p_i ≤ M for all dimensions i.
"""
function create_bounding_box(n_dims::Int, M::Rational{Int})
    constraints = HalfSpace{Rational{Int}}[]
    
    for i in 1:n_dims
        # Lower bound: p_i ≥ 0  =>  -p_i ≤ 0
        lower_coeffs = zeros(Rational{Int}, n_dims)
        lower_coeffs[i] = -1
        push!(constraints, HalfSpace(lower_coeffs, 0//1))
        
        # Upper bound: p_i ≤ M  =>  p_i ≤ M  
        upper_coeffs = zeros(Rational{Int}, n_dims)
        upper_coeffs[i] = 1
        push!(constraints, HalfSpace(upper_coeffs, M))
    end
    
    # Return the intersection of all bounding constraints
    return reduce(intersect, constraints)
end

# ============================================================================
# Polyhedra operations functions
# ============================================================================

"""
    compute_polyhedron(Φ, A, halfspaces, bounding_box)

Compute the polyhedron P_Φ = B ∩ (∩_{Ψ ∈ A \\ {Φ}} H(Φ, Ψ)) for a single bundle Φ
using precomputed halfspaces and bounding box constraints.
"""
function compute_polyhedron(Φ::Bundle, A::Vector{Bundle}, halfspaces::Dict{Tuple{Bundle, Bundle}, HalfSpace}, bounding_box)
    # Start with the bounding box
    result = bounding_box
    
    # Add all constraints H(Φ, Ψ) for Ψ ≠ Φ by intersecting them one by one
    for Ψ in A
        if Ψ != Φ && haskey(halfspaces, (Φ, Ψ))
            result = intersect(result, halfspaces[(Φ, Ψ)])
        end
    end
    
    return result
end

"""
    compute_all_polyhedra(A, v, χ, M)

Compute all polyhedra P_Φ for all bundles Φ ∈ A with bounding box [0,M]^n.
Returns a dictionary mapping bundles to their polyhedra.
"""
function compute_all_polyhedra(A::Vector{Bundle}, v::Function, χ::Prices, M::Rational{Int})
    # First compute all halfspaces once
    halfspaces = compute_all_halfspaces(A, v, χ)
    
    # Create bounding box
    n_dims = length(χ)
    bounding_box = create_bounding_box(n_dims, M)
    
    # Then compute each polyhedron using the precomputed halfspaces and bounding box
    polyhedra = Dict{Bundle, Any}()
    
    for Φ in A
        polyhedra[Φ] = compute_polyhedron(Φ, A, halfspaces, bounding_box)
    end
    
    return polyhedra
end

"""
    extract_unique_vertices(polyhedra)

Extract all unique vertices from all polyhedra.
Returns a vector of unique vertices as Vector{Rational{Int}}.
"""
function extract_unique_vertices(polyhedra::Dict{Bundle, Any})
    all_vertices = Vector{Prices}()
    
    for (bundle, poly) in polyhedra
        if poly !== nothing && !isempty(polyhedron(poly, lib))
            vertices = collect(points(polyhedron(poly, lib)))
            append!(all_vertices, vertices)
        end
    end
    
    # Remove duplicates (approximately, for rational arithmetic)
    unique_vertices = Vector{Prices}()
    for vertex in all_vertices
        is_duplicate = false
        for existing in unique_vertices
            if norm(vertex - existing) < 1e-10  # tolerance for rational comparison
                is_duplicate = true
                break
            end
        end
        if !is_duplicate
            push!(unique_vertices, vertex)
        end
    end
    
    return unique_vertices
end

# ============================================================================
# Facet computation functions
# ============================================================================

"""
    compute_facet_intersection(poly1, poly2)

Compute the intersection P_Φ ∩ P_Ψ of two polyhedra.
"""
function compute_facet_intersection(poly1, poly2)
    if poly1 === nothing || poly2 === nothing
        return nothing
    end
    
    try
        intersection = poly1 ∩ poly2
        poly_intersect = polyhedron(intersection, lib)
        return isempty(poly_intersect) ? nothing : intersection
    catch
        return nothing
    end
end

"""
    is_facet_nonempty(facet)

Check if a facet intersection is non-empty and has appropriate dimension.
"""
function is_facet_nonempty(facet)
    if facet === nothing
        return false
    end
    try
        poly = polyhedron(facet, lib)
        return !isempty(poly)
    catch
        return false
    end
end

"""
    map_vertices_to_indices(facet_vertices, global_vertices)

Map facet vertices to their indices in the global vertex list.
"""
function map_vertices_to_indices(facet_vertices, global_vertices::Vector{Prices})
    indices = Int[]
    
    for fv in facet_vertices
        # Convert Float64 vertices to Rational for comparison
        fv_rational = Rational{Int}.(fv)
        for (i, gv) in enumerate(global_vertices)
            if norm(Float64.(fv_rational - gv)) < 1e-10  # tolerance for comparison
                push!(indices, i)
                break
            end
        end
    end
    
    return indices
end

"""
    compute_all_facets(polyhedra, A)

Find all non-empty facets F_{Φ,Ψ} = P_Φ ∩ P_Ψ.
Returns a vector of facet vertex indices.
"""
function compute_all_facets(polyhedra::Dict{Bundle, Any}, A::Vector{Bundle})
    all_vertices = extract_unique_vertices(polyhedra)
    facet_indices = Vector{Vector{Int}}()
    
    for i in 1:length(A), j in (i+1):length(A)
        Φ, Ψ = A[i], A[j]
        
        if haskey(polyhedra, Φ) && haskey(polyhedra, Ψ)
            facet = compute_facet_intersection(polyhedra[Φ], polyhedra[Ψ])
            
            if is_facet_nonempty(facet)
                try
                    facet_poly = polyhedron(facet, lib)
                    facet_vertices = collect(points(facet_poly))
                    if !isempty(facet_vertices)
                        indices = map_vertices_to_indices(facet_vertices, all_vertices)
                        if !isempty(indices)
                            push!(facet_indices, indices)
                        end
                    end
                catch
                    # Skip facets that cause numerical issues
                end
            end
        end
    end
    
    return facet_indices, all_vertices
end

# ============================================================================
# Label computation functions
# ============================================================================

"""
    compute_chebyshev_center(polyhedron)

Compute the Chebyshev center (center of the largest inscribed ball) of a polyhedron.
"""
function compute_chebyshev_center(poly_rep)
    if poly_rep === nothing
        return nothing
    end
    
    try
        poly = polyhedron(poly_rep, lib)
        if isempty(poly)
            return nothing
        end
        return chebyshevcenter(poly)
    catch
        # Fallback: use centroid of vertices if Chebyshev center fails
        try
            poly = polyhedron(poly_rep, lib)
            vertices = collect(points(poly))
            if !isempty(vertices)
                n_dims = length(vertices[1])
                center = zeros(Rational{Int}, n_dims)
                for vertex in vertices
                    center .+= vertex
                end
                return center ./ length(vertices)
            end
        catch
        end
        return nothing
    end
end

"""
    compute_all_label_positions(polyhedra)

Get Chebyshev centers for all polyhedra to use as label positions.
"""
function compute_all_label_positions(polyhedra::Dict{Bundle, Any})
    labels = Vector{Prices}()
    bundle_order = collect(keys(polyhedra))
    
    for bundle in bundle_order
        center = compute_chebyshev_center(polyhedra[bundle])
        if center !== nothing
            push!(labels, center)
        else
            # Fallback: use origin if center computation fails
            push!(labels, zeros(Rational{Int}, 3))
        end
    end
    
    return labels, bundle_order
end

# ============================================================================
# JSON formatting functions
# ============================================================================

"""
    vertices_to_json_format(vertices)

Convert rational vertices to float arrays for JSON compatibility.
"""
function vertices_to_json_format(vertices::Vector{Prices})
    return [[Float64(coord) for coord in vertex] for vertex in vertices]
end

"""
    facets_to_json_format(facets)

Convert facet indices to JSON arrays (1-indexed to 0-indexed).
"""
function facets_to_json_format(facets::Vector{Vector{Int}})
    # Convert from 1-indexed Julia to 0-indexed for JSON
    return [indices .- 1 for indices in facets]
end

"""
    labels_to_json_format(labels)

Convert label positions to JSON format.
"""
function labels_to_json_format(labels::Vector{Prices})
    return [[Float64(coord) for coord in label] for label in labels]
end

"""
    bundles_to_json_format(bundles)

Convert bundle sets to string arrays.
"""
function bundles_to_json_format(bundles::Vector{Bundle})
    return [bundle_to_string(bundle) for bundle in bundles]
end

"""
    assemble_json_output(vertices, facets, labels, bundles)

Create the final JSON structure for LIP visualization.
"""
function assemble_json_output(vertices, facets, labels, bundles)
    return Dict(
        "vertices" => vertices_to_json_format(vertices),
        "facets" => facets_to_json_format(facets),
        "labels" => labels_to_json_format(labels),
        "bundles" => bundles_to_json_format(bundles)
    )
end

# ============================================================================
# Main orchestrating function
# ============================================================================

"""
    create_LIP_json(v::Function, A, χ, M)

Create the LIP JSON file for visualization given:
- v: valuation function mapping bundles (sets) to integers
- A: vector of bundles (domain of the valuation)
- χ: coefficient vector indicating buyer (+1) or seller (-1) role for each trade
- M: maximum value for bounding box [0,M]^n

Returns a JSON-compatible dictionary with vertices, facets, labels, and bundles.
"""
function create_LIP_json(v::Function, A::Vector{Bundle}, χ::Vector{<:Real}, M::Real)
    # Convert χ and M to rational for exact arithmetic
    χ_rational = Rational{Int}.(χ)
    M_rational = Rational{Int}(M)
    
    # Compute all polyhedra P_Φ for each bundle Φ ∈ A with bounding box
    polyhedra = compute_all_polyhedra(A, v, χ_rational, M_rational)
    
    # Compute all facets and extract vertices
    facets, vertices = compute_all_facets(polyhedra, A)
    
    # Compute label positions (Chebyshev centers)
    labels, bundle_order = compute_all_label_positions(polyhedra)
    
    # Assemble the final JSON output
    json_data = assemble_json_output(vertices, facets, labels, bundle_order)
    
    return json_data
end

"""
    create_LIP_json_file(filename::String, v::Function, A, χ, M)

Create and save the LIP JSON file to disk.
"""
function create_LIP_json_file(filename::String, v::Function, A::Vector{Bundle}, χ::Vector{<:Real}, M::Real)
    json_data = create_LIP_json(v, A, χ, M)
    
    open(filename, "w") do io
        JSON3.pretty(io, json_data, indent=2)
    end
    
    return json_data
end

# ============================================================================
# Testing helper function
# ============================================================================

"""
    create_test_example()

Create a simple test example for validation with 3 goods and basic valuation.
"""
function create_test_example()
    # Define domain A as some bundles of {1, 2, 3}
    A = [
        Bundle(),      # empty bundle
        Bundle([1]),   # {1}
        Bundle([2]),   # {2}  
        Bundle([3]),   # {3}
        Bundle([1,2]), # {1,2}
        Bundle([1,3]), # {1,3}
        Bundle([2,3]), # {2,3}
        Bundle([1,2,3]) # {1,2,3}
    ]
    
    # Valuation function based on cardinality
    function v(bundle::Bundle)
        return length(bundle)  # value = number of goods in bundle
    end
    
    # Coefficient vector: agent is buyer of all trades
    χ = [1//1, 1//1, 1//1]  # buyer of trades 1, 2, 3
    
    return v, A, χ
end

"""
    test_create_LIP()

Run a basic test of the LIP creation functionality.
"""
function test_create_LIP()
    println("Testing LIP creation...")
    
    v, A, χ = create_test_example()
    M = 10  # Bounding box [0,10]^3
    
    try
        json_data = create_LIP_json(v, A, χ, M)
        
        println("✓ Successfully created LIP JSON")
        println("  - Vertices: $(length(json_data["vertices"]))")
        println("  - Facets: $(length(json_data["facets"]))")
        println("  - Labels: $(length(json_data["labels"]))")
        println("  - Bundles: $(length(json_data["bundles"]))")
        
        return json_data
    catch e
        println("✗ Error creating LIP JSON: $e")
        rethrow(e)
    end
end

"""
    generate_LIP_file(filename::String = "LIP.json")

Generate a LIP JSON file using the test example and save it to the specified filename.
This function combines test_create_LIP() with JSON file output.
"""
function generate_test_LIP_file(filename::String = "LIP.json")
    println("Generating LIP file: $filename")
    
    try
        # Generate the LIP data
        json_data = test_create_LIP()
        
        # Write to JSON file
        open(filename, "w") do file
            JSON3.pretty(file, json_data)
        end
        
        println("✓ Successfully saved LIP data to $filename")
        println("  File size: $(stat(filename).size) bytes")
        
        return json_data
    catch e
        println("✗ Error generating LIP file: $e")
        rethrow(e)
    end
end