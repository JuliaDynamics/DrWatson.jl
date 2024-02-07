cd(@__DIR__)
using DrWatson
using UnPack

# Convert workflow
import Literate

Literate.markdown(joinpath(@__DIR__, "src", "workflow.jl"), joinpath(@__DIR__, "src"); credit = false)

pages = [
    "Introduction" => "index.md",
    "DrWatson Workflow Tutorial" => "workflow.md",
    "Project Setup" => "project.md",
    "Naming Simulations" => "name.md",
    "Saving Tools" => "save.md",
    "Running & Listing Simulations" => "run&list.md",
    "Real World Examples" => "real_world.md"
]

import Downloads
Downloads.download(
    "https://raw.githubusercontent.com/JuliaDynamics/doctheme/master/build_docs_with_style.jl",
    joinpath(@__DIR__, "build_docs_with_style.jl")
)
include("build_docs_with_style.jl")

build_docs_with_style(pages, DrWatson, UnPack;
    expandfirst = ["index.md"], warnonly = true,
)
