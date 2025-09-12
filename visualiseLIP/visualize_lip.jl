#!/usr/bin/env julia

"""
MeshCat visualization script for LIP (Locus of Indifference Prices) polytope facets.

This script loads a LIP JSON file and visualizes each facet individually using MeshCat
from Polyhedra.jl. Each facet is plotted in a different color in the same visualization.

Usage: julia visualize_lip.jl
"""

using JSON3
using Polyhedra
using MeshCat
using GLPK
using ColorTypes
using LinearAlgebra

const lib = DefaultLibrary{Float64}(GLPK.Optimizer)

function load_lip_json(filename)
    return JSON3.read(read(filename, String))
end

function create_facet_polyhedron(vertices, facet_indices)
    facet_vertices = [vertices[i+1] for i in facet_indices]
    vertex_matrix = hcat(facet_vertices...)
    vrep_obj = Polyhedra.vrep(vertex_matrix')
    return polyhedron(vrep_obj, lib)
end

function generate_colors(n)
    colors = Vector{RGBA{Float32}}(undef, n)
    for i in 1:n
        hue = (i - 1) * 360 / n
        h = hue / 60
        c = 1.0
        x = c * (1 - abs((h % 2) - 1))
        
        if h < 1
            r, g, b = c, x, 0
        elseif h < 2
            r, g, b = x, c, 0
        elseif h < 3
            r, g, b = 0, c, x
        elseif h < 4
            r, g, b = 0, x, c
        elseif h < 5
            r, g, b = x, 0, c
        else
            r, g, b = c, 0, x
        end
        
        colors[i] = RGBA{Float32}(r, g, b, 0.7)
    end
    return colors
end

function visualize_lip_facets(json_file)
    println("Loading LIP data from: $json_file")
    
    lip_data = load_lip_json(json_file)
    vertices = lip_data.vertices
    facets = lip_data.facets
    bundles = lip_data.bundles
    
    println("Found $(length(facets)) facets, $(length(vertices)) vertices")
    
    vis = Visualizer()
    colors = generate_colors(length(facets))
    facets_added = 0
    
    for (i, facet) in enumerate(facets)
        try
            if length(facet) < 3
                continue
            end
            
            poly = create_facet_polyhedron(vertices, facet)
            mesh = Polyhedra.Mesh(poly)
            material = MeshPhongMaterial(color=colors[i])
            
            facet_name = Symbol("facet_$i")
            setobject!(vis[facet_name], mesh, material)
            facets_added += 1
            
            bundle_str = i <= length(bundles) ? bundles[i] : "N/A"
            println("Facet $i: Bundle $bundle_str")
            
        catch e
            println("Error processing facet $i: $e")
            continue
        end
    end
    
    println("\\nVisualized $facets_added facets successfully")
    open(vis)
    
    println("MeshCat server: http://127.0.0.1:8700")
    println("Press Enter to exit...")
    readline()
    
    return vis
end

function main()
    json_file = joinpath(@__DIR__, "data", "random_3_trades_LIP.json")
    
    if !isfile(json_file)
        println("File not found: $json_file")
        return
    end
    
    visualize_lip_facets(json_file)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end